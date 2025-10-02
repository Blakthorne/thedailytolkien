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
    comment_created
    comment_moderated
    quote_create
    quote_delete
    quote_update
    quotes_bulk_delete
    quotes_csv_import
    quotes_csv_import_error
    tag_created
    tag_deleted
    tag_updated
    tag_added_to_quote
    tag_removed_from_quote
    unauthorized_access_attempt
    user_delete
    user_role_change
    user_streak_manual_update
    user_update
    users_bulk_delete
    users_bulk_role_change
    users_bulk_streak_reset
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
    when "comment_created"
      "created a comment"
    when "comment_moderated"
      "moderated a comment"
    when "quote_create"
      "created a quote"
    when "quote_delete"
      "deleted a quote"
    when "quote_update"
      "updated quote"
    when "quotes_bulk_delete"
      "performed bulk quote delete"
    when "quotes_csv_import"
      "imported quotes from CSV"
    when "quotes_csv_import_error"
      "failed to import quotes from CSV"
    when "tag_created"
      "created a tag"
    when "tag_deleted"
      "deleted tag"
    when "tag_updated"
      "updated tag"
    when "tag_added_to_quote"
      "added tag to quote"
    when "tag_removed_from_quote"
      "removed tag from quote"
    when "unauthorized_access_attempt"
      "attempted unauthorized access"
    when "user_delete"
      "deleted user"
    when "user_role_change"
      "changed user role"
    when "user_streak_manual_update"
      "manually updated user streak"
    when "user_update"
      "updated user"
    when "users_bulk_delete"
      "performed bulk user delete"
    when "users_bulk_role_change"
      "performed bulk user role change"
    when "users_bulk_streak_reset"
      "performed bulk user streak reset"
    else
      action.to_s.humanize
    end
  end
end
