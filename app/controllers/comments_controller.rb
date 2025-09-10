class CommentsController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :update, :destroy ]
  before_action :set_quote, except: [ :destroy, :update ]
  before_action :set_comment, only: [ :update, :destroy ]
  before_action :set_comment_quote, only: [ :update ]

  # GET /quotes/:quote_id/comments
  def index
    @comments = @quote.comments.includes(:user, :replies).top_level.ordered

    respond_to do |format|
      format.json do
        render json: {
          comments: render_comments(@comments),
          total_count: @quote.comments_count
        }
      end
      format.html { redirect_to root_path }
    end
  end

  # POST /quotes/:quote_id/comments
  def create
    @comment = @quote.comments.build(comment_params)
    @comment.user = current_user

    # Set parent and validate depth
    if params[:parent_id].present?
      parent = @quote.comments.find(params[:parent_id])
      if parent.depth >= 4
        return render json: { error: "Maximum comment nesting depth exceeded" }, status: :unprocessable_entity
      end
      @comment.parent = parent
    end

    if @comment.save
      # Broadcast the new comment via ActionCable
      QuoteInteractionChannel.broadcast_to(@quote, {
        type: "new_comment",
        comment: render_comment(@comment),
        total_count: @quote.comments_count
      })

      respond_to do |format|
        format.json do
          render json: {
            success: true,
            html: render_to_string(partial: "quotes/comment_with_replies", locals: { comment: @comment, depth: @comment.depth }, formats: [ :html ]),
            comments_count: @quote.comments_count,
            total_count: @quote.comments_count
          }
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: {
            success: false,
            errors: @comment.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
    end
  end

  # PATCH/PUT /comments/:id
  def update
    unless @comment.can_be_edited_by?(current_user)
      return render json: { error: "Comment cannot be edited" }, status: :forbidden
    end

    if @comment.update(comment_params)
      respond_to do |format|
        format.json do
          render json: {
            success: true,
            html: render_to_string(partial: "quotes/comment_with_replies", locals: { comment: @comment, depth: @comment.depth }, formats: [ :html ]),
            edited: true,
            edited_at: @comment.edited_at.strftime("%B %d, %Y at %I:%M %p"),
            edit_count: @comment.edit_count
          }
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: {
            success: false,
            errors: @comment.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /comments/:id
  def destroy
    if @comment.user == current_user || current_user.admin?
      @comment.destroy

      # Broadcast the update via ActionCable
      QuoteInteractionChannel.broadcast_to(@quote, {
        type: "comment_deleted",
        comment_id: @comment.id,
        total_count: @quote.comments_count
      })

      respond_to do |format|
        format.json do
          render json: {
            success: true,
            total_count: @quote.comments_count
          }
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: { error: "Not authorized to delete this comment" }, status: :forbidden
        end
      end
    end
  end

  private

  def set_quote
    @quote = Quote.find(params[:quote_id])
  end

  def set_comment
    @comment = Comment.find(params[:id])
    @quote = @comment.quote
  end

  def set_comment_quote
    @quote = @comment.quote
  end

  def comment_params
    params.require(:comment).permit(:content)
  end

  def render_comments(comments)
    comments.map { |comment| render_comment(comment) }
  end

  def render_comment(comment)
    {
      id: comment.id,
      content: comment.filtered_content,
      user_name: comment.user.email.split("@").first,
      created_at: comment.created_at.strftime("%B %d, %Y at %I:%M %p"),
      depth: comment.depth,
      parent_id: comment.parent_id,
      replies: render_comments(comment.replies.ordered),
      can_delete: current_user&.admin? || (current_user == comment.user)
    }
  end
end
