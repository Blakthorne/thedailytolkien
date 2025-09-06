class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    auth = request.env["omniauth.auth"]
    origin = request.params["origin"] || request.env.dig("omniauth.params", "origin")

    # Try to find existing user by provider/uid first
    @user = User.find_by(provider: auth.provider, uid: auth.uid)

    # If no user found, check by email (for users who signed up manually first)
    @user ||= User.find_by(email: auth.info.email)

    if @user
      # User exists - handle based on context
      if origin == "signup"
        # They tried to signup but already have an account
        redirect_to new_user_session_path, alert: "You already have an account with this email. Please sign in instead."
        nil
      else
        # Update OAuth info if missing
        if @user.provider.blank? || @user.uid.blank?
          @user.update(provider: auth.provider, uid: auth.uid)
        end

        # Sign them in and redirect to home
        sign_in @user, event: :authentication
        set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
        redirect_to after_sign_in_path_for(@user)
        nil
      end
    else
      # No user found - handle based on context
      if origin == "signup"
        # They want to signup, create new user
        @user = User.new(
          email: auth.info.email,
          name: auth.info.name,
          provider: auth.provider,
          uid: auth.uid,
          password: Devise.friendly_token[0, 20]
        )

        if @user.save
          sign_in @user, event: :authentication
          set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
          redirect_to after_sign_up_path_for(@user)
          nil
        else
          # Save failed, show errors
          redirect_to new_user_registration_path, alert: "There was an error creating your account: #{@user.errors.full_messages.join(', ')}"
          nil
        end
      else
        # They tried to signin but don't have an account
        redirect_to new_user_registration_path, alert: "No account found with this email. Please sign up first."
        nil
      end
    end
  end

  def failure
    redirect_to root_path
  end
end
