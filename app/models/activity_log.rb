class ActivityLog < ApplicationRecord
  belongs_to :user
  belongs_to :target, polymorphic: true, optional: true

  # Serialize details as JSON
  serialize :details, coder: JSON

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
    activity_logs_view
    comment_created
    dashboard_view
    page_view
    quote_disliked
    quote_edit_view
    quote_like_removed
    quote_liked
    quote_update
    quote_view
    quotes_bulk_delete
    quotes_csv_import
    quotes_export_csv_enhanced
    record_not_found
    tag_deleted
    unauthorized_access_attempt
    user_delete
    user_edit_view
    user_role_change
    user_streak_manual_update
    user_streak_recalculated
    user_streak_reset
    user_update
    user_view
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

  # Human-friendly description of the action (keeps target details out so views can append them)
  def action_description
    case action.to_s
    when "create"
      "created"
    when "update"
      "updated"
    when "destroy"
      "deleted"
    when "bulk_update"
      "performed a bulk update"
    when "bulk_destroy"
      "performed a bulk delete"
    when "promote_user"
      "promoted a user"
    when "demote_user"
      "demoted a user"
    when "export_data"
      "exported data"
    when "view_details"
      "viewed details"
    when "login_admin_area"
      "logged into the admin area"
    when "activity_logs_view"
      "viewed activity logs"
    when "comment_created"
      "created a comment"
    when "dashboard_view"
      "viewed dashboard"
    when "page_view"
      "viewed page"
    when "quote_disliked"
      "disliked quote"
    when "quote_edit_view"
      "viewed quote edit page"
    when "quote_like_removed"
      "removed quote like"
    when "quote_liked"
      "liked quote"
    when "quote_update"
      "updated quote"
    when "quote_view"
      "viewed quote"
    when "quotes_bulk_delete"
      "performed bulk quote delete"
    when "quotes_csv_import"
      "imported quotes from CSV"
    when "quotes_export_csv_enhanced"
      "exported quotes to CSV"
    when "record_not_found"
      "attempted to access non-existent record"
    when "tag_deleted"
      "deleted tag"
    when "unauthorized_access_attempt"
      "attempted unauthorized access"
    when "user_delete"
      "deleted user"
    when "user_edit_view"
      "viewed user edit page"
    when "user_role_change"
      "changed user role"
    when "user_streak_manual_update"
      "manually updated user streak"
    when "user_streak_recalculated"
      "recalculated user streak"
    when "user_streak_reset"
      "reset user streak"
    when "user_update"
      "updated user"
    when "user_view"
      "viewed user"
    else
      action.to_s.humanize
    end
  end
end
