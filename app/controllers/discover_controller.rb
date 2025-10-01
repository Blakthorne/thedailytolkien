# Discover Controller for The Daily Tolkien quote discovery system
# Provides both an index view showing a table of all historical quotes
# and individual show views for specific dates with full quote interactions
class DiscoverController < ApplicationController
  before_action :set_user_timezone
  after_action :reset_user_timezone

  # Discover index - displays paginated table of all displayed quotes with filtering/sorting
  def index
    @quotes = Quote.displayed.includes(:tags, :quote_likes, :comments)

    # Apply filters
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      @quotes = @quotes.where(
        "LOWER(text) LIKE ? OR LOWER(book) LIKE ? OR LOWER(chapter) LIKE ? OR LOWER(character) LIKE ?",
        search_term, search_term, search_term, search_term
      )
    end

    if params[:book].present?
      @quotes = @quotes.where(book: params[:book])
    end

    if params[:character].present?
      @quotes = @quotes.where(character: params[:character])
    end

    if params[:tag_id].present?
      @quotes = @quotes.joins(:tags).where(tags: { id: params[:tag_id] })
    end

    # Apply sorting
    case params[:sort_by]
    when "date"
      @quotes = @quotes.order(last_date_displayed: params[:sort_direction] == "asc" ? :asc : :desc)
    when "book"
      @quotes = @quotes.order(book: params[:sort_direction] == "asc" ? :asc : :desc)
    when "character"
      @quotes = @quotes.order(character: params[:sort_direction] == "asc" ? :asc : :desc)
    else
      @quotes = @quotes.by_display_date
    end

    # Paginate results
    @quotes = @quotes.page(params[:page]).per(25)

    # Load filter options
    load_discover_filters
  end

  # Discover show - displays a specific quote by ID with full interactivity
  def show
    @quote = Quote.find_by(id: params[:id])

    if @quote.nil?
      render :show
      return
    end

    # Calculate the discover date from the quote's last display date
    @discover_date = Time.at(@quote.last_date_displayed).in_time_zone(@user_timezone || "UTC").to_date

    if @quote
      # Load all interaction data for full interactivity (like quotes#index)
      @quote_likes = @quote.quote_likes.includes(:user)
      @comments = @quote.comments.includes(:user, replies: :user).where(parent_id: nil).order(:created_at)
      @user_like_status = current_user ? @quote.user_like_status(current_user) : nil

      # Set up data for interactive functionality (matching quotes controller)
      @likes_count = @quote.likes_count
      @dislikes_count = @quote.dislikes_count
      @comments_count = @quote.comments_count

      # Load tags for display (matching quotes controller pattern)
      @tags = @quote.tags
    end
  end

  private

  # Permit discover filtering and search parameters
  def discover_params
    params.permit(:search, :book, :character, :tag_id, :sort_by, :sort_direction, :page)
  end



  # Set up filter options for discover index dropdowns
  def load_discover_filters
    @books = Quote.displayed.distinct.pluck(:book).compact.sort
    @characters = Quote.displayed.distinct.pluck(:character).compact.sort
    @tags = Tag.joins(:quotes).where(quotes: { id: Quote.displayed.select(:id) }).distinct.order(:name)
  end

  # Set user timezone for proper date display
  def set_user_timezone
    @user_timezone = current_user&.streak_timezone || "UTC"
    @previous_time_zone = Time.zone
    Time.zone = @user_timezone
  end

  def reset_user_timezone
    Time.zone = @previous_time_zone
  end
end
