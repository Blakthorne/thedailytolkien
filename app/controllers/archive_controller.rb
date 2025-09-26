# Archive Controller for The Daily Tolkien quote archive system
# Provides both an index view showing a table of all historical quotes
# and individual show views for specific dates showing read-only quote interactions
class ArchiveController < ApplicationController
  before_action :set_user_timezone
  after_action :reset_user_timezone

  # Archive index - displays paginated table of all displayed quotes with filtering/sorting
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
    load_archive_filters
  end

  # Archive show - displays a specific quote from a given date (read-only)
  def show
    date = convert_date_to_timestamp(params[:date])

    if date.nil?
      redirect_to archive_index_path, alert: "Invalid date format. Please use YYYY-MM-DD."
      return
    end

    @quote = Quote.displayed_on_date(date.to_date).first
    @archive_date = date.to_date

    if @quote
      # Load all interaction data for read-only display
      @quote_likes = @quote.quote_likes.includes(:user)
      @comments = @quote.comments.includes(:user, replies: :user).where(parent_id: nil).order(:created_at)
      @user_like_status = current_user ? @quote.user_like_status(current_user) : nil
    end
  end

  private

  # Permit archive filtering and search parameters
  def archive_params
    params.permit(:search, :book, :character, :tag_id, :sort_by, :sort_direction, :page)
  end

  # Convert date string (YYYY-MM-DD) to Unix timestamp for database queries
  def convert_date_to_timestamp(date_string)
    return nil unless date_string&.match?(/^\d{4}-\d{2}-\d{2}$/)

    begin
      Date.parse(date_string).in_time_zone(@user_timezone || "UTC")
    rescue ArgumentError
      nil
    end
  end

  # Set up filter options for archive index dropdowns
  def load_archive_filters
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
