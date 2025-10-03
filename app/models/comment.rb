class Comment < ApplicationRecord
  MAX_DEPTH = 4
  PROFANITY_WORDS = %w[
    damn hell fuck shit ass bitch bastard crap fool
    stupid idiot moron dumb dumbass retard
    bullshit
  ].freeze

  belongs_to :user, optional: true
  belongs_to :quote
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy

  validates :content, presence: true, length: { minimum: 1, maximum: 2000 }
  validates :depth, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 4 }
  validate :validate_depth

  before_validation :set_depth
  after_create :log_creation
  before_update :track_edit, if: :content_changed?

  scope :top_level, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:created_at) }

  def filtered_content
    return content unless contains_profanity?

    # Replace profanity with asterisks while preserving original word/character positions
    filtered = content.dup

    # First try direct word matching
    PROFANITY_WORDS.each do |word|
      filtered.gsub!(/\b#{Regexp.escape(word)}\b/i) { |match| "*" * match.length }
    end

    # Then check for obfuscated versions and filter them too
    # This is a simplified approach - just mark the whole comment as filtered if obfuscation detected
    if filtered == content && contains_profanity?
      "[Content filtered due to inappropriate language]"
    else
      filtered
    end
  end

  def to_admin_json
    {
      id: id,
      content: content,
      filtered_content: filtered_content,
      user_email: user.email,
      quote_text: quote.text[0..100] + (quote.text.length > 100 ? "..." : ""),
      quote_id: quote.id,
      parent_id: parent_id,
      depth: depth,
      has_profanity: contains_profanity?,
      created_at: created_at.strftime("%B %d, %Y at %I:%M %p"),
      replies_count: replies.count
    }
  end

  # Edit functionality methods
  def edited?
    edited_at.present?
  end

  def edit_time_limit_exceeded?
    created_at < 15.minutes.ago
  end

  def can_be_edited_by?(user)
    return false if edit_time_limit_exceeded?
    return false if user.nil?
    self.user == user
  end

  def contains_profanity?
    return false if content.blank?

    # Check both the original content and a version with spaces/punctuation collapsed
    normalized_content = normalize_for_profanity_check(content)

    PROFANITY_WORDS.any? do |word|
      # Build a flexible regex for the word that allows separators between characters
      # This creates a pattern like: d[\s_\-\*]*a[\s_\-\*]*m[\s_\-\*]*n for "damn"
      flexible_pattern = word.chars.map { |c| Regexp.escape(c) }.join('[\\s_\\-\\*\\.\\,\\!\\?\\;\\:\\\'\\"\\`\\~\\|\\\\\\/ ]*')
      flexible_regex = /\b#{flexible_pattern}\b/i

      # Check both normalized (leetspeak/unicode replaced) and original
      normalized_content.match?(flexible_regex) || content.downcase.match?(flexible_regex)
    end
  end

  private

  # Normalize content to detect profanity with common evasion techniques
  def normalize_for_profanity_check(text)
    return "" if text.blank?
    normalized = text.dup.downcase

    # First, replace leetspeak substitutions (process longer patterns first)
    leetspeak_replacements = [
      [ "|\\/|", "m" ], [ "|\\|", "n" ], [ "\\/\\/", "w" ],
      [ "|-|", "h" ], [ "|3", "b" ], [ "|)", "d" ],
      [ "|<", "k" ], [ "|_|", "u" ], [ "|_", "l" ], [ "|>", "p" ],
      [ "|2", "r" ], [ "\\/", "v" ], [ "ph", "f" ], [ "><", "x" ],
      [ "11", "ll" ], # Process multi-digit patterns before single digits
      [ "@", "a" ], [ "4", "a" ], [ "^", "a" ],
      [ "8", "b" ], [ "(", "c" ], [ "<", "c" ],
      [ "{", "c" ], [ "3", "e" ], [ "€", "e" ],
      [ "6", "g" ], [ "9", "g" ], [ "#", "h" ],
      [ "!", "i" ], [ "1", "i" ], [ "|", "i" ],
      [ "0", "o" ], [ "5", "s" ], [ "$", "s" ],
      [ "7", "t" ], [ "+", "t" ], [ "2", "z" ]
    ]

    # Apply leetspeak replacements
    leetspeak_replacements.each do |leet, normal|
      normalized.gsub!(leet, normal)
    end

    # Replace common Unicode substitutions
    unicode_map = {
      "а" => "a", "е" => "e", "о" => "o", # Cyrillic
      "ⓐ" => "a", "ⓔ" => "e", "ⓞ" => "o", # Circled letters
      "𝐚" => "a", "𝐞" => "e", "𝐨" => "o", # Bold letters
      "𝑎" => "a", "𝑒" => "e", "𝑜" => "o"  # Italic letters
    }

    unicode_map.each do |unicode_char, normal|
      normalized.gsub!(unicode_char, normal)
    end

    normalized
  end



  def set_depth
    self.depth = parent ? parent.depth + 1 : 0
  end

  def validate_depth
    if depth > MAX_DEPTH
      errors.add(:parent, "Comment nesting too deep (max #{MAX_DEPTH} levels)")
    end
  end

  def log_creation
    ActivityLog.create!(
      user: user,
      action: "comment_created",
      target: quote,
      ip_address: RequestStore[:current_ip] || "127.0.0.1",
      user_agent: RequestStore[:current_user_agent] || "Unknown",
      details: {
        comment_id: id,
        depth: depth,
        parent_id: parent_id,
        content_length: content.length,
        has_profanity: contains_profanity?
      }
    )
  rescue => e
    Rails.logger.error "Failed to log comment creation: #{e.message}"
  end

  public

  # Helper methods for handling deleted users
  def user_display_name
    return "Deleted User" unless user
    user.display_name
  end

  def user_name
    return "Deleted User" unless user
    user.name.presence || user.email
  end

  def user_email
    return nil unless user
    user.email
  end

  def user_deleted?
    user.nil?
  end

  private

  def track_edit
    # Store original content if this is the first edit
    if original_content.blank?
      self.original_content = content_was
    end

    # Update edit tracking
    self.edited_at = Time.current
    self.edit_count = (edit_count || 0) + 1
  end
end
