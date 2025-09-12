require "csv"

class Admin::ImportExportController < AdminController
  def index
    # Display the import/export page
  end

  def import
    unless params[:csv_file].present?
      redirect_to admin_import_export_path, alert: "Please select a CSV file to upload."
      return
    end

    file = params[:csv_file]

    unless file.content_type == "text/csv" || file.original_filename.end_with?(".csv")
      redirect_to admin_import_export_path, alert: "Please upload a valid CSV file."
      return
    end

    begin
      result = process_csv_import(file)

      log_action("quotes_csv_import", nil, {
        total_rows: result[:total_rows],
        imported: result[:imported],
        skipped: result[:skipped],
        failed: result[:failed],
        filename: file.original_filename
      })

      if result[:failed] > 0
        flash[:alert] = generate_import_summary(result)
      else
        flash[:notice] = generate_import_summary(result)
      end

    rescue StandardError => e
      log_action("quotes_csv_import_error", nil, {
        error: e.message,
        filename: file.original_filename
      })

      flash[:alert] = "Error processing CSV file: #{e.message}"
    end

    redirect_to admin_import_export_path
  end

  def export
    csv_data = generate_quotes_csv_with_tags

    log_action("quotes_export_csv_enhanced", nil, { count: Quote.count })

    send_data csv_data,
              filename: "quotes-enhanced-#{Date.current}.csv",
              type: "text/csv",
              disposition: "attachment"
  end

  private

  def process_csv_import(file)
    result = {
      total_rows: 0,
      imported: 0,
      skipped: 0,
      failed: 0,
      errors: []
    }

    CSV.foreach(file.path, headers: true, header_converters: :symbol) do |row|
      result[:total_rows] += 1

      begin
        # Extract data from CSV row
        text = row[:text]&.strip
        book = row[:book]&.strip
        chapter = row[:chapter]&.strip
        context = row[:context]&.strip
        character = row[:character]&.strip
        tags_string = row[:tags]&.strip

        # Validate required fields
        if text.blank? || book.blank?
          result[:failed] += 1
          result[:errors] << "Row #{result[:total_rows]}: Text and Book are required"
          next
        end

        # Check for duplicates (case-insensitive)
        existing_quote = Quote.where(
          "LOWER(text) = ? AND LOWER(book) = ?",
          text.downcase,
          book.downcase
        ).first

        if existing_quote
          result[:skipped] += 1
          next
        end

        # Create the quote
        quote = Quote.new(
          text: text,
          book: book,
          chapter: chapter.presence,
          context: context.presence,
          character: character.presence
        )

        if quote.save
          # Process tags if provided
          if tags_string.present?
            tag_names = tags_string.split(",").map(&:strip).reject(&:blank?)
            tag_names.each do |tag_name|
              tag = Tag.find_or_create_by(name: tag_name.downcase)
              quote.tags << tag unless quote.tags.include?(tag)
            end
          end

          result[:imported] += 1
        else
          result[:failed] += 1
          result[:errors] << "Row #{result[:total_rows]}: #{quote.errors.full_messages.join(', ')}"
        end

      rescue StandardError => e
        result[:failed] += 1
        result[:errors] << "Row #{result[:total_rows]}: #{e.message}"
      end
    end

    result
  end

  def generate_import_summary(result)
    summary = []
    summary << "Import completed!"
    summary << "Total rows processed: #{result[:total_rows]}"
    summary << "Successfully imported: #{result[:imported]} quotes"
    summary << "Skipped (duplicates): #{result[:skipped]} quotes" if result[:skipped] > 0
    summary << "Failed: #{result[:failed]} quotes" if result[:failed] > 0

    if result[:errors].any?
      summary << ""
      summary << "Errors:"
      result[:errors].first(10).each { |error| summary << "• #{error}" }
      if result[:errors].length > 10
        summary << "• ... and #{result[:errors].length - 10} more errors"
      end
    end

    summary.join("\n")
  end

  def generate_quotes_csv_with_tags
    CSV.generate(headers: true) do |csv|
      csv << [ "text", "book", "chapter", "context", "character", "tags" ]

      Quote.includes(:tags).find_each do |quote|
        tags_string = quote.tags.map(&:name).join(",")

        csv << [
          quote.text,
          quote.book,
          quote.chapter,
          quote.context,
          quote.character,
          tags_string
        ]
      end
    end
  end
end
