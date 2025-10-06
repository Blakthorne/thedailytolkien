# The Quote model represents a single quote from J.R.R. Tolkien's works.
# This model is the core of "The Daily Tolkien" application, storing quotes
# that are displayed daily on the home page. Each quote includes metadata
# about its source and display history to manage the rotation system.
#
# The model ensures data integrity through validations and provides methods
# for selecting quotes for daily display.
class Quote < ApplicationRecord
  # Validations ensure that essential data is present and correctly formatted.
  # The text and book fields are required as they are fundamental to the quote.
  validates :text, presence: true
  validates :book, presence: true

    # days_displayed must be a non-negative integer, tracking how many times
    # this quote has been shown to users.
    validates :days_displayed, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

    # Ensure sane defaults before validations run
    before_validation :set_default_counters

  # last_date_displayed and first_date_displayed are optional integers representing
  # Unix timestamps. They track when the quote was last and first displayed.
  # These can be nil if the quote hasn't been displayed yet.
  validates :last_date_displayed, numericality: { only_integer: true }, allow_nil: true
  validates :first_date_displayed, numericality: { only_integer: true }, allow_nil: true

  # chapter, context, and character are optional string fields that provide
  # additional metadata about the quote's origin and content.
  # No validations are needed here as they can be nil.

  # Associations for interaction system
  has_many :quote_likes, dependent: :destroy
  has_many :comments, dependent: :destroy

  # Associations for tagging system
  has_many :quote_tags, dependent: :destroy
  has_many :tags, through: :quote_tags

  # Engagement metrics methods
  # Note: These now use counter cache columns instead of COUNT queries
  # The columns are automatically updated by Rails when associations change

  def engagement_score
    (read_attribute(:likes_count) || 0) + (read_attribute(:comments_count) || 0) - (read_attribute(:dislikes_count) || 0)
  end

  # Check if user has liked/disliked this quote
  def user_like_status(user)
    return nil unless user
    quote_like = quote_likes.find_by(user: user)
    quote_like&.like_type
  end

  # Discover-specific methods for quote discover system

  # Class method to find quotes displayed on a specific date
  def self.displayed_on_date(date)
    timestamp_start = date.beginning_of_day.to_i
    timestamp_end = date.end_of_day.to_i
    where(last_date_displayed: timestamp_start..timestamp_end)
  end

  # Instance method returning formatted display date from last_date_displayed
  def discover_date
    return nil unless last_date_displayed
    Time.at(last_date_displayed).to_date
  end

  # Instance method for truncated quote text for discover snippets
  def discover_snippet(length = 100)
    return text if text.nil? || text.length <= length
    truncated = text[0, length]
    last_space = truncated.rindex(" ")
    last_space ? truncated[0, last_space] + "..." : truncated + "..."
  end

  # Instance method checking if quote has been displayed
  def has_been_displayed?
    last_date_displayed.present?
  end

  # Scope for quotes that have been displayed (last_date_displayed not nil)
  scope :displayed, -> { where.not(last_date_displayed: nil) }

  # Scope to order by display date descending
  scope :by_display_date, -> { order(last_date_displayed: :desc) }

  # Scope to filter by date range
  scope :date_range, ->(start_date, end_date) {
    start_timestamp = start_date.beginning_of_day.to_i
    end_timestamp = end_date.end_of_day.to_i
    where(last_date_displayed: start_timestamp..end_timestamp)
  }
end
    private

    # Sets default values for counter fields so validations don't fail when omitted.
    def set_default_counters
      self.days_displayed = 0 if days_displayed.nil?
    end
