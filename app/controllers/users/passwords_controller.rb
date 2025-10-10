# frozen_string_literal: true

module Users
  class PasswordsController < Devise::PasswordsController
    # Skip the require_no_authentication filter for create action
    # This allows signed-in users to request password reset emails
    skip_before_action :require_no_authentication, only: [ :create ]

    # POST /users/password
    # Override to redirect back to profile page for signed-in users,
    # or to sign-in page for non-signed-in users
    def create
      self.resource = resource_class.send_reset_password_instructions(resource_params)
      yield resource if block_given?

      if successfully_sent?(resource)
        # Set flash message explicitly
        set_flash_message! :notice, :send_instructions
        # Redirect to profile if signed in, otherwise to sign-in page
        redirect_to user_signed_in? ? profile_path : new_user_session_path
      else
        respond_with(resource)
      end
    end

    protected

    # Override to redirect to appropriate page based on authentication status
    def after_sending_reset_password_instructions_path_for(resource_name)
      user_signed_in? ? profile_path : new_user_session_path
    end
  end
end
