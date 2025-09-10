require "csv"

class Admin::UsersController < AdminController
  before_action :set_user, only: [ :show, :edit, :update, :destroy, :update_role, :toggle_status, :reset_streak, :recalculate_streak, :update_streak ]

  def index
    @users = User.order(created_at: :desc)
    @users = @users.where("email ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    @users = @users.where(role: params[:role]) if params[:role].present?

    respond_to do |format|
      format.html
      format.csv do
        csv_data = generate_users_csv
  log_action("users_export_csv", nil, { count: User.count })
        send_data csv_data,
                  filename: "users-#{Date.current}.csv",
                  type: "text/csv",
                  disposition: "attachment"
      end
    end
  end

  def show
    @user_activities = ActivityLog.where(user: @user)
                                 .order(created_at: :desc)
                                 .limit(20)
    # No logging for view-only actions
  end

  def edit
    # No logging for view-only actions
  end

  def update
    old_attributes = @user.attributes.dup

    if @user.update(user_params)
      log_action("user_update", @user, {
        changes: @user.previous_changes,
        old_attributes: old_attributes.slice("email", "role")
      })

      redirect_to admin_user_path(@user), notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    return if @user == current_user # Prevent self-deletion

    user_info = {
      email: @user.email,
      role: @user.role,
      id: @user.id
    }

    @user.destroy

    log_action("user_delete", nil, user_info)

    redirect_to admin_users_path, notice: "User was successfully deleted."
  end

  def update_role
    # Prevent admin from changing their own role
    if @user == current_user
      redirect_to admin_user_path(@user), alert: "You cannot change your own role."
      return
    end

    old_role = @user.role
    new_role = params[:role]

    # Validate that the new role is valid
    unless User.roles.keys.include?(new_role)
      redirect_to admin_user_path(@user), alert: "Invalid role specified."
      return
    end

    if @user.update(role: new_role)
      log_action("user_role_change", @user, {
        old_role: old_role,
        new_role: new_role
      })

      redirect_to admin_user_path(@user), notice: "User role updated to #{new_role.humanize}."
    else
      redirect_to admin_user_path(@user), alert: "Failed to update user role."
    end
  end

  def toggle_status
    # For future use when we add status field to users
    redirect_to admin_users_path, notice: "Feature coming soon."
  end

  def bulk_action
    user_ids = params[:user_ids] || []
    action = params[:bulk_action]

    # Prevent bulk actions on current user
    user_ids = user_ids.reject { |id| id.to_i == current_user.id }

    case action
    when "delete"
      deleted_count = User.where(id: user_ids).destroy_all.count
      log_action("users_bulk_delete", nil, { count: deleted_count, user_ids: user_ids })
      redirect_to admin_users_path, notice: "#{deleted_count} users were deleted."
    when "make_admin"
      updated_count = User.where(id: user_ids).update_all(role: "admin")
      log_action("users_bulk_role_change", nil, { count: updated_count, user_ids: user_ids, new_role: "admin" })
      redirect_to admin_users_path, notice: "#{updated_count} users were made admins."
    when "make_commentor"
      updated_count = User.where(id: user_ids).update_all(role: "commentor")
      log_action("users_bulk_role_change", nil, { count: updated_count, user_ids: user_ids, new_role: "commentor" })
      redirect_to admin_users_path, notice: "#{updated_count} users were made commentors."
    when "reset_streaks"
      reset_count = bulk_reset_streaks(user_ids)
      redirect_to admin_users_path, notice: "Reset streaks for #{reset_count} users."
    when "recalculate_streaks"
      recalc_count = bulk_recalculate_streaks(user_ids)
      redirect_to admin_users_path, notice: "Recalculated streaks for #{recalc_count} users."
    else
      redirect_to admin_users_path, alert: "Invalid bulk action."
    end
  end

  # Individual streak management actions
  def reset_streak
    # Capture values before resetting
    previous_current = @user.current_streak
    previous_longest = @user.longest_streak

    @user.reset_streak!
    log_action("user_streak_reset", @user, {
      previous_current_streak: previous_current,
      previous_longest_streak: previous_longest
    })
    redirect_to admin_user_path(@user), notice: "Streak reset for #{@user.email}."
  end

  def recalculate_streak
    old_current = @user.current_streak
    old_longest = @user.longest_streak

    @user.recalculate_streak!

    log_action("user_streak_recalculated", @user, {
      old_current_streak: old_current,
      old_longest_streak: old_longest,
      new_current_streak: @user.current_streak,
      new_longest_streak: @user.longest_streak
    })

    redirect_to admin_user_path(@user), notice: "Streak recalculated for #{@user.email}."
  end

  def update_streak
    current_streak = params[:current_streak].to_i
    longest_streak = params[:longest_streak].to_i

    if current_streak < 0 || longest_streak < 0
      redirect_to admin_user_path(@user), alert: "Streak values cannot be negative."
      return
    end

    old_attributes = {
      current_streak: @user.current_streak,
      longest_streak: @user.longest_streak
    }

    if @user.update(current_streak: current_streak, longest_streak: longest_streak)
      log_action("user_streak_manual_update", @user, {
        old_attributes: old_attributes,
        new_attributes: {
          current_streak: current_streak,
          longest_streak: longest_streak
        }
      })
      redirect_to admin_user_path(@user), notice: "Streak updated for #{@user.email}."
    else
      redirect_to admin_user_path(@user), alert: "Failed to update streak: #{@user.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    # Only allow email updates through general update - role changes handled separately
    params.require(:user).permit(:email)
  end

  def bulk_reset_streaks(user_ids)
    users = User.where(id: user_ids)
    reset_count = 0

    users.find_each do |user|
      user.reset_streak!
      reset_count += 1
    end

    log_action("users_bulk_streak_reset", nil, {
      count: reset_count,
      user_ids: user_ids
    })

    reset_count
  end

  def bulk_recalculate_streaks(user_ids)
    users = User.where(id: user_ids)
    recalc_count = 0

    users.find_each do |user|
      user.recalculate_streak!
      recalc_count += 1
    end

    log_action("users_bulk_streak_recalculated", nil, {
      count: recalc_count,
      user_ids: user_ids
    })

    recalc_count
  end

  def generate_users_csv
    CSV.generate(headers: true) do |csv|
      csv << [ "ID", "Email", "Role", "Current Streak", "Longest Streak", "Timezone", "Provider", "Created At", "Last Sign In" ]

      User.find_each do |user|
        csv << [
          user.id,
          user.email,
          user.role,
          user.current_streak,
          user.longest_streak,
          user.streak_timezone,
          user.provider || "email",
          user.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          user.current_sign_in_at&.strftime("%Y-%m-%d %H:%M:%S") || "Never"
        ]
      end
    end
  end
end
