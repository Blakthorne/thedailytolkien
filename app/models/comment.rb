class Comment < ApplicationRecord
  MAX_DEPTH = 4
  PROFANITY_WORDS = %w[
    damn hell fuck shit ass bitch bastard crap
    stupid idiot moron dumb dumbass retard
  ].freeze

  belongs_to :user
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

    # Replace profanity with asterisks while preserving word length
    filtered = content.dup
    PROFANITY_WORDS.each do |word|
      filtered.gsub!(/\b#{Regexp.escape(word)}\b/i, "*" * word.length)
    end
    filtered
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

  private

  def contains_profanity?
    PROFANITY_WORDS.any? { |word| content.match?(/\b#{Regexp.escape(word)}\b/i) }
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
