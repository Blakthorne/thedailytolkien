require 'csv'

class Admin::QuotesController < AdminController
  before_action :set_quote, only: [:show, :edit, :update, :destroy, :toggle_status]
  
  def index
    @quotes = Quote.includes(:user).order(created_at: :desc)
    @quotes = @quotes.where("text ILIKE ? OR book ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    @quotes = @quotes.limit(20).offset(params[:page].to_i * 20) if params[:page].present?
    
    respond_to do |format|
      format.html
      format.csv { render csv: generate_quotes_csv, filename: "quotes-#{Date.current}.csv" }
    end
  end
  
  def show
    log_action('quote_view', @quote)
  end
  
  def new
    @quote = Quote.new
  end
  
  def create
    @quote = Quote.new(quote_params)
    
    if @quote.save
      log_action('quote_create', @quote, {
        book: @quote.book,
        chapter: @quote.chapter
      })
      
      redirect_to admin_quote_path(@quote), notice: 'Quote was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    log_action('quote_edit_view', @quote)
  end
  
  def update
    old_attributes = @quote.attributes.dup
    
    if @quote.update(quote_params)
      log_action('quote_update', @quote, {
        changes: @quote.previous_changes,
        old_attributes: old_attributes.slice('text', 'book', 'chapter', 'character')
      })
      
      redirect_to admin_quote_path(@quote), notice: 'Quote was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    quote_info = {
      text: @quote.text[0..50] + "...",
      book: @quote.book,
      chapter: @quote.chapter
    }
    
    @quote.destroy
    
    log_action('quote_delete', nil, quote_info)
    
    redirect_to admin_quotes_path, notice: 'Quote was successfully deleted.'
  end
  
  def toggle_status
    # For future use when we add status field to quotes
    redirect_to admin_quotes_path, notice: 'Feature coming soon.'
  end
  
  def bulk_action
    quote_ids = params[:quote_ids] || []
    action = params[:bulk_action]
    
    case action
    when 'delete'
      deleted_count = Quote.where(id: quote_ids).destroy_all.count
      log_action('quotes_bulk_delete', nil, { count: deleted_count, quote_ids: quote_ids })
      redirect_to admin_quotes_path, notice: "#{deleted_count} quotes were deleted."
    else
      redirect_to admin_quotes_path, alert: 'Invalid bulk action.'
    end
  end
  
  private
  
  def set_quote
    @quote = Quote.find(params[:id])
  end
  
  def quote_params
    params.require(:quote).permit(:text, :book, :chapter, :character)
  end
  
  def generate_quotes_csv
    CSV.generate(headers: true) do |csv|
      csv << ['ID', 'Text', 'Book', 'Chapter', 'Character', 'Created At']
      
      Quote.find_each do |quote|
        csv << [
          quote.id,
          quote.text,
          quote.book,
          quote.chapter,
          quote.character,
          quote.created_at.strftime('%Y-%m-%d %H:%M:%S')
        ]
      end
    end
  end
end
