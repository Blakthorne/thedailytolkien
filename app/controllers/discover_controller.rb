# Discover Controller for The Daily Tolkien quote discovery system
# Provides both an index view showing a table of all historical quotes
# and individual show views for specific dates with full quote interactions
class DiscoverController < ApplicationController
  before_action :set_user_timezone
  after_action :reset_user_timezone

  # Discover index - displays paginated table of all quotes with filtering/sorting
  def index
    # Start with base query - NO eager loading yet
    @quotes = Quote.all

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

    # Apply sorting (now uses indexed columns for better performance)
    case params[:sort_by]
    when "date"
      # Sort by last_date_displayed, with NULLs (never displayed) at the end
      direction = params[:sort_direction] == "asc" ? "ASC" : "DESC"
      @quotes = @quotes.order(Arel.sql("last_date_displayed IS NULL, last_date_displayed #{direction}"))
    when "book"
      @quotes = @quotes.order(book: params[:sort_direction] == "asc" ? :asc : :desc)
    when "character"
      @quotes = @quotes.order(character: params[:sort_direction] == "asc" ? :asc : :desc)
    when "likes"
      # Now we can sort by counter cache column efficiently
      @quotes = @quotes.order(likes_count: params[:sort_direction] == "asc" ? :asc : :desc)
    when "comments"
      # Now we can sort by counter cache column efficiently
      @quotes = @quotes.order(comments_count: params[:sort_direction] == "asc" ? :asc : :desc)
    else
      # Default: sort by last_date_displayed DESC, with never-displayed quotes at the end
      @quotes = @quotes.order(Arel.sql("last_date_displayed IS NULL, last_date_displayed DESC"))
    end

    # Paginate FIRST - only load 25 quotes
    @quotes = @quotes.page(params[:page]).per(25)

    # NOW eager load associations ONLY for the 25 quotes being displayed
    # Only load tags since that's all we display in the table
    @quotes = @quotes.includes(:tags)

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

    # Calculate the discover date from the quote's last display date (if it has been displayed)
    @discover_date = @quote.last_date_displayed.present? ?
      Time.at(@quote.last_date_displayed).in_time_zone(@user_timezone || "UTC").to_date :
      nil

    if @quote
      # Load only top-level comments with users and replies (same pattern as quotes controller)
      @comments = @quote.comments.includes(:user, replies: :user).top_level.ordered
      @user_like_status = current_user ? @quote.user_like_status(current_user) : nil

      # Use counter cache columns for counts (no queries needed)
      @likes_count = @quote.likes_count
      @dislikes_count = @quote.dislikes_count
      @comments_count = @quote.comments_count

      # Load tags for display
      @tags = @quote.tags.order(:name)
    end
  end

  private

  # Permit discover filtering and search parameters
  def discover_params
    params.permit(:search, :book, :character, :tag_id, :sort_by, :sort_direction, :page)
  end



  # Set up filter options for discover index dropdowns
  def load_discover_filters
    @books = Quote.distinct.pluck(:book).compact.sort
    @characters = Quote.distinct.pluck(:character).compact.sort
    @tags = Tag.joins(:quotes).distinct.order(:name)
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
