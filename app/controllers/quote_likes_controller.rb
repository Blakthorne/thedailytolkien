class QuoteLikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quote
  before_action :validate_like_type
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  # POST /quote_likes
  def create
    @quote_like = @quote.quote_likes.find_by(user: current_user)

    if @quote_like
      # User already has a like/dislike, toggle or change it
      if @quote_like.like_type == params[:like_type]
        # Same type - remove the like
        @quote_like.destroy
        like_status = nil
      else
        # Different type - change it
        @quote_like.update!(like_type: params[:like_type])
        like_status = @quote_like.like_type
      end
    else
      # Create new like
      @quote_like = @quote.quote_likes.create!(user: current_user, like_type: params[:like_type])
      like_status = @quote_like.like_type
    end

    # Log the activity
    log_like_activity(like_status)

    # Broadcast the update via ActionCable
    QuoteInteractionChannel.broadcast_to(@quote, {
      type: "like_update",
      likes_count: @quote.likes_count,
      dislikes_count: @quote.dislikes_count,
      user_like_status: like_status
    })

    render json: {
      success: true,
      likes_count: @quote.likes_count,
      dislikes_count: @quote.dislikes_count,
      user_like_status: like_status
    }
  end

  private

  def set_quote
    @quote = Quote.find(params[:quote_id])
  end

  def validate_like_type
    lt = params[:like_type]
    unless %w[like dislike].include?(lt)
      render json: { success: false, error: "Invalid like_type. Must be 'like' or 'dislike'." }, status: :unprocessable_entity
    end
  end

  def log_like_activity(like_status)
    # Activity logging removed for quote likes/dislikes per user request
    # No longer logging: quote_liked, quote_disliked, quote_like_removed
  end

  def render_unprocessable(exception)
    render json: { success: false, error: exception.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
  end

  def render_not_found(_exception)
    render json: { success: false, error: "Quote not found" }, status: :not_found
  end
end
