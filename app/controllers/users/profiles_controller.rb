module Users
  class ProfilesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_user

    def show
      # Display user profile with personal info, streak stats, and account management
    end

    def edit
      # Display edit form for first_name and last_name
    end

    def update
      if @user.update(user_params)
        redirect_to profile_path, notice: "Profile updated successfully"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = current_user
    end

    def user_params
      params.require(:user).permit(:first_name, :last_name)
    end
  end
end
