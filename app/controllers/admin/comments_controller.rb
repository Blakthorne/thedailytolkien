class Admin::CommentsController < AdminController
  before_action :set_comment, only: [ :show, :destroy ]

  def index
    @comments = Comment.includes(:user, :quote).order(created_at: :desc)

    # Filter by profanity if requested
    @comments = @comments.where("content LIKE ?", "%*%") if params[:profanity_filter] == "true"

    # Search functionality
    if params[:search].present?
      @comments = @comments.where("content ILIKE ?", "%#{params[:search]}%")
    end

    # Filter by user
    if params[:user_id].present?
      @comments = @comments.where(user_id: params[:user_id])
    end

    # Filter by quote
    if params[:quote_id].present?
      @comments = @comments.where(quote_id: params[:quote_id])
    end

    @comments = @comments.page(params[:page]).per(20) if respond_to?(:page)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          comments: @comments.map(&:to_admin_json),
          total_count: @comments.count
        }
      end
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @comment.to_admin_json }
    end
  end

  def destroy
    comment_content = @comment.content[0..50] + (@comment.content.length > 50 ? "..." : "")
    user_email = @comment.user.email
    quote_id = @comment.quote.id

    @comment.destroy

    ActivityLog.create!(
      user: current_user,
      action: "comment_moderated",
      details: {
        comment_content: comment_content,
        user_email: user_email,
        quote_id: quote_id,
        reason: params[:reason] || "Admin moderation"
      }
    )

    # Broadcast the comment deletion
    QuoteInteractionChannel.broadcast_to(@comment.quote, {
      type: "comment_deleted",
      comment_id: @comment.id,
      total_count: @comment.quote.comments_count
    })

    respond_to do |format|
      format.html { redirect_to admin_comments_path, notice: "Comment was successfully deleted." }
      format.json { render json: { success: true, message: "Comment deleted successfully" } }
    end
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end
end
