class QuoteLikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quote

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

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          likes_count: @quote.likes_count,
          dislikes_count: @quote.dislikes_count,
          user_like_status: like_status
        }
      end
    end
  end

  private

  def set_quote
    @quote = Quote.find(params[:quote_id])
  end

  def log_like_activity(like_status)
    # Activity logging removed for quote likes/dislikes per user request
    # No longer logging: quote_liked, quote_disliked, quote_like_removed
  end
end
