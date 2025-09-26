# Controller for user-specific actions like timezone updates
class UsersController < ApplicationController
  before_action :authenticate_user!

  # PATCH /users/update_timezone
  def update_timezone
    timezone = params[:timezone]
    offset = params[:offset]

    # Validate timezone
    validated_timezone = TimezoneDetectionService.validate_timezone(timezone, offset)

    if current_user.update(streak_timezone: validated_timezone)
      # Recalculate streak with new timezone
      current_user.recalculate_streak!

      render json: {
        success: true,
        timezone: validated_timezone,
        streak: {
          current: current_user.current_streak,
          longest: current_user.longest_streak,
          display: current_user.streak_display
        }
      }
    else
      render json: {
        success: false,
        errors: current_user.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "Timezone update failed for user #{current_user.id}: #{e.message}"
    render json: {
      success: false,
      error: "Failed to update timezone"
    }, status: :internal_server_error
  end
end
