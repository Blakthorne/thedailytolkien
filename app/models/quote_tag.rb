class QuoteTag < ApplicationRecord
  belongs_to :quote
  belongs_to :tag

  validates :quote_id, uniqueness: { scope: :tag_id, message: "Tag already assigned to this quote" }
end
