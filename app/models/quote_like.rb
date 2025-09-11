class QuoteLike < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :quote

  enum :like_type, { dislike: 0, like: 1 }

  validates :user_id, uniqueness: { scope: :quote_id, message: "can only like or dislike a quote once" }, allow_nil: true
  validates :like_type, presence: true

  # Scopes for counting
  scope :likes, -> { where(like_type: :like) }
  scope :dislikes, -> { where(like_type: :dislike) }

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
end
