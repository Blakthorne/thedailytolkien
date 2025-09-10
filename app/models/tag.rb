class Tag < ApplicationRecord
  has_many :quote_tags, dependent: :destroy
  has_many :quotes, through: :quote_tags

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { minimum: 1, maximum: 50 }

  before_save :normalize_name

  scope :alphabetical, -> { order(:name) }
  scope :popular, -> { joins(:quotes).group("tags.id").order("COUNT(quotes.id) DESC") }

  def usage_count
    quotes.count
  end

  def to_json_with_stats
    {
      id: id,
      name: name,
      description: description,
      usage_count: usage_count,
      created_at: created_at.strftime("%B %d, %Y"),
      recent_usage: quotes.where("quotes.created_at > ?", 1.week.ago).count
    }
  end

  private

  def normalize_name
    self.name = name.strip.downcase if name.present?
  end
end
