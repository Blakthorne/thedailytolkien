class ActivityLog < ApplicationRecord
  belongs_to :user
  belongs_to :target, polymorphic: true, optional: true

  # Validations
  validates :action, presence: true
  validates :ip_address, presence: true

  # Scopes for common queries
  scope :recent, -> { order(created_at: :desc) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_target_type, ->(type) { where(target_type: type) }
  scope :by_user, ->(user) { where(user: user) }

  # Common actions for admin activities
  ACTIONS = %w[
    create update destroy
    bulk_update bulk_destroy
    promote_user demote_user
    export_data view_details
    login_admin_area
  ].freeze

  # Helper methods
  def target_description
    return "N/A" unless target

    case target_type
    when "Quote"
      "Quote: #{target.text.truncate(50)}"
    when "User"
      "User: #{target.name} (#{target.email})"
    else
      "#{target_type} ##{target_id}"
    end
  end

  def formatted_created_at
    created_at.strftime("%Y-%m-%d %H:%M:%S")
  end
end
