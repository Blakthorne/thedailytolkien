# The QuotesController handles the display of Tolkien quotes on the website.
# It provides an index action that shows a daily quote with full interaction capabilities.
class QuotesController < ApplicationController
  before_action :set_request_timezone
  after_action :reset_request_timezone
  before_action :set_quote, only: [ :index ]

  # The index action is responsible for displaying the daily Tolkien quote
  # along with all interaction data (likes, comments, tags).
  def index
    if @quote
      # Load interaction data for the UI
      @user_like_status = current_user ? @quote.user_like_status(current_user) : nil
      # Load only top-level comments (replies will be loaded via associations)
      @comments = @quote.comments.includes(:user, replies: :user).top_level.ordered
      @tags = @quote.tags.order(:name)

      # Engagement stats
      @likes_count = @quote.likes_count
      @dislikes_count = @quote.dislikes_count
      @comments_count = @quote.comments_count
    end
  end

  private

  # Set the request timezone based on signed-in user's preference or a guest cookie
  def set_request_timezone
    @previous_time_zone = Time.zone
    tz = if current_user&.streak_timezone.present?
      current_user.streak_timezone
    else
      # Validate guest timezone cookie (IANA or Rails name)
      guest_tz = cookies[:guest_tz]
      TimezoneDetectionService.validate_timezone(guest_tz)
    end

    @request_timezone = tz || "UTC"
    Time.zone = @request_timezone
  end

  def reset_request_timezone
    Time.zone = @previous_time_zone
  end

  def set_quote
    # Get today's date as a Unix timestamp (start of day) in the request timezone
    now_in_tz = Time.zone ? Time.zone.now : Time.current
    today_start = now_in_tz.beginning_of_day.to_i
    tomorrow_start = now_in_tz.beginning_of_day.tomorrow.to_i

    # Find if there's already a quote selected for today
    @quote = Quote.includes(:quote_likes, :comments, :tags)
                   .where.not(text: nil)
                   .where(last_date_displayed: today_start...tomorrow_start)
                   .first

    # If no quote for today, select the next one in rotation
    if @quote.nil?
      @quote = Quote.includes(:quote_likes, :comments, :tags)
                    .where.not(text: nil)
                    .order(Arel.sql("last_date_displayed IS NULL DESC, last_date_displayed ASC, id ASC"))
                    .first

      if @quote
        # Update display tracking information for the new daily quote
        @quote.days_displayed += 1
        @quote.last_date_displayed = today_start
        @quote.first_date_displayed ||= today_start
        @quote.save
      end
    end
  end
end
