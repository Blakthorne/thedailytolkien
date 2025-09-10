class Admin::TagsController < AdminController
  before_action :set_tag, only: [ :show, :edit, :update, :destroy ]

  def index
    @tags = Tag.includes(:quotes).order(:name)
    @tags = @tags.where("name LIKE ?", "%#{params[:search]}%") if params[:search].present?

    # Pagination if needed
    @tags = @tags.page(params[:page]).per(20) if respond_to?(:page)

    respond_to do |format|
      format.html
      format.json { render json: @tags.map(&:to_json_with_stats) }
    end
  end

  def show
    @quotes = @tag.quotes.page(params[:page]).per(10)
  end

  def new
    @tag = Tag.new
  end

  def create
    @tag = Tag.new(tag_params)

    if @tag.save
      ActivityLog.create!(
        user: current_user,
        action: "tag_created",
        details: { tag_name: @tag.name },
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )

      redirect_to admin_tag_path(@tag), notice: "Tag was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    old_name = @tag.name

    if @tag.update(tag_params)
      ActivityLog.create!(
        user: current_user,
        action: "tag_updated",
        details: { old_name: old_name, new_name: @tag.name },
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )

      redirect_to admin_tag_path(@tag), notice: "Tag was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    tag_name = @tag.name
    quotes_count = @tag.quotes.count

    @tag.destroy

    ActivityLog.create!(
      user: current_user,
      action: "tag_deleted",
      details: { tag_name: tag_name, quotes_affected: quotes_count },
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    redirect_to admin_tags_path, notice: "Tag '#{tag_name}' was successfully deleted."
  end

  # POST /admin/tags/:id/add_to_quote
  def add_to_quote
    @tag = Tag.find(params[:id])
    quote = Quote.find(params[:quote_id])

    if @tag.quotes.include?(quote)
      render json: { error: "Tag already exists on this quote" }, status: :unprocessable_content
    else
      @tag.quotes << quote

      ActivityLog.create!(
        user: current_user,
        action: "tag_added_to_quote",
        details: { tag_name: @tag.name, quote_id: quote.id },
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )

      render json: { success: true, message: "Tag added successfully" }
    end
  end

  # DELETE /admin/tags/:id/remove_from_quote
  def remove_from_quote
    @tag = Tag.find(params[:id])
    quote = Quote.find(params[:quote_id])

    if @tag.quotes.include?(quote)
      @tag.quotes.delete(quote)

      ActivityLog.create!(
        user: current_user,
        action: "tag_removed_from_quote",
        details: { tag_name: @tag.name, quote_id: quote.id },
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )

      render json: { success: true, message: "Tag removed successfully" }
    else
      render json: { error: "Tag not found on this quote" }, status: :not_found
    end
  end

  private

  def set_tag
    @tag = Tag.find(params[:id])
  end

  def tag_params
    params.require(:tag).permit(:name, :description)
  end
end
