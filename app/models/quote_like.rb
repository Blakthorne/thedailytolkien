class QuoteLike < ApplicationRecord
  belongs_to :user
  belongs_to :quote

  enum :like_type, { dislike: 0, like: 1 }

  validates :user_id, uniqueness: { scope: :quote_id, message: "can only like or dislike a quote once" }
  validates :like_type, presence: true

  # Scopes for counting
  scope :likes, -> { where(like_type: :like) }
  scope :dislikes, -> { where(like_type: :dislike) }
end
