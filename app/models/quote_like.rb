class QuoteLike < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :quote

  enum :like_type, { dislike: 0, like: 1 }

  validates :user_id, uniqueness: { scope: :quote_id, message: "can only like or dislike a quote once" }, allow_nil: true
  validates :like_type, presence: true

  # Scopes for counting
  scope :likes, -> { where(like_type: :like) }
  scope :dislikes, -> { where(like_type: :dislike) }

  # Custom counter cache callbacks for conditional counting
  after_create :increment_quote_counter
  after_update :update_quote_counter
  after_destroy :decrement_quote_counter

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

  def increment_quote_counter
    return unless quote&.persisted?
    return if quote.destroyed? || quote.marked_for_destruction?

    if like?
      quote.increment!(:likes_count)
    else
      quote.increment!(:dislikes_count)
    end
  rescue ActiveRecord::RecordNotFound
    # Quote was deleted, ignore counter update
  end

  def decrement_quote_counter
    return unless quote&.persisted?
    return if quote.destroyed? || quote.marked_for_destruction?

    if like?
      quote.decrement!(:likes_count)
    else
      quote.decrement!(:dislikes_count)
    end
  rescue ActiveRecord::RecordNotFound
    # Quote was deleted, ignore counter update
  end

  def update_quote_counter
    return unless saved_change_to_like_type?
    return unless quote&.persisted?
    return if quote.destroyed? || quote.marked_for_destruction?

    # When like_type changes, decrement old type and increment new type
    if like?
      quote.decrement!(:dislikes_count)
      quote.increment!(:likes_count)
    else
      quote.decrement!(:likes_count)
      quote.increment!(:dislikes_count)
    end
  rescue ActiveRecord::RecordNotFound
    # Quote was deleted, ignore counter update
  end
end
