# Custom Devise sessions controller to handle login streak updates
class Users::SessionsController < Devise::SessionsController
  # POST /resource/sign_in
  def create
    super do |resource|
      if resource.persisted?
        # Mark that user just signed in for streak update
        session[:just_signed_in] = true
        # Update streak immediately on successful sign-in
        resource.update_login_streak
      end
    end
  end

  protected

  # Always redirect to home page after sign in
  def after_sign_in_path_for(resource)
    root_path
  end
end
