require "csv"

class Admin::UsersController < AdminController
  before_action :set_user, only: [ :show, :edit, :update, :destroy, :update_role, :toggle_status ]

  def index
    @users = User.order(created_at: :desc)
    @users = @users.where("email ILIKE ?", "%#{params[:search]}%") if params[:search].present?
    @users = @users.where(role: params[:role]) if params[:role].present?

    respond_to do |format|
      format.html
      format.csv do
        csv_data = generate_users_csv
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
    log_action("user_view", @user)
  end

  def edit
    log_action("user_edit_view", @user)
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
    old_role = @user.role
    new_role = params[:role]

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
    else
      redirect_to admin_users_path, alert: "Invalid bulk action."
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :role)
  end

  def generate_users_csv
    CSV.generate(headers: true) do |csv|
      csv << [ "ID", "Email", "Role", "Provider", "Created At", "Last Sign In" ]

      User.find_each do |user|
        csv << [
          user.id,
          user.email,
          user.role,
          user.provider || "email",
          user.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          user.current_sign_in_at&.strftime("%Y-%m-%d %H:%M:%S") || "Never"
        ]
      end
    end
  end
end
