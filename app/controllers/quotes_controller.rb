# The QuotesController handles the display of Tolkien quotes on the website.
# It provides an index action that shows a daily quote with full interaction capabilities.
class QuotesController < ApplicationController
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

  def set_quote
    # Get today's date as a Unix timestamp (start of day)
    today_start = Time.now.beginning_of_day.to_i
    tomorrow_start = Time.now.beginning_of_day.tomorrow.to_i

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
