class PhilosophyController < ApplicationController
  def show
    # Read markdown content from external file
    # This allows you to edit the philosophy content without touching the code
    markdown_file_path = Rails.root.join("app", "content", "philosophy.md")

    begin
      markdown_content = File.read(markdown_file_path)
    rescue Errno::ENOENT
      # Fallback content if file doesn't exist
      markdown_content = <<~MARKDOWN
        # Philosophy Content Missing

        The philosophy content file could not be found at `app/content/philosophy.md`.

        Please create this file to display your philosophical content.
      MARKDOWN
    end

    # Process Markdown to HTML using Redcarpet
    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      link_attributes: { target: "_blank" }
    )
    @markdown = Redcarpet::Markdown.new(renderer)

    # Render the content for display in the view
    @content = @markdown.render(markdown_content)
  end
end
