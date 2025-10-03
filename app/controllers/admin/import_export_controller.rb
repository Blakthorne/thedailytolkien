require "csv"

class Admin::ImportExportController < AdminController
  def index
    # Display the import/export page
  end

  # Maximum file size for CSV uploads (5MB)
  MAX_CSV_FILE_SIZE = 5.megabytes

  # Maximum number of rows to process
  MAX_CSV_ROWS = 10_000

  def import
    unless params[:csv_file].present?
      redirect_to admin_import_export_path, alert: "Please select a CSV file to upload."
      return
    end

    file = params[:csv_file]

    # Security check 1: File size validation
    if file.size > MAX_CSV_FILE_SIZE
      redirect_to admin_import_export_path,
                  alert: "File size exceeds maximum allowed size of #{MAX_CSV_FILE_SIZE / 1.megabyte}MB."
      return
    end

    # Security check 2: Content-type validation (strict)
    unless file.content_type == "text/csv"
      redirect_to admin_import_export_path,
                  alert: "Invalid file type. Only CSV files with text/csv content-type are allowed."
      return
    end

    # Security check 3: File extension validation
    unless file.original_filename.end_with?(".csv")
      redirect_to admin_import_export_path, alert: "Invalid file extension. Only .csv files are allowed."
      return
    end

    # Security check 4: Validate CSV structure and content
    validation_result = validate_csv_file(file)
    unless validation_result[:valid]
      redirect_to admin_import_export_path, alert: validation_result[:error]
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

  # Validate CSV file structure and content for security
  def validate_csv_file(file)
    begin
      # Read first chunk to check for malicious content
      file.rewind
      first_bytes = file.read(1000)
      file.rewind

      # Security check: Look for potentially malicious content
      # Check for null bytes (indicates binary file)
      if first_bytes.include?("\x00")
        return { valid: false, error: "Invalid CSV file format (binary content detected)." }
      end

      # Check for extremely long lines by scanning entire file efficiently
      File.foreach(file.path).with_index do |line, index|
        # Only check first 100 lines for performance
        break if index > 100

        if line.length > 10_000
          return { valid: false, error: "CSV contains excessively long lines." }
        end
      end
      file.rewind

      # Validate CSV can be parsed
      csv_data = CSV.read(file.path, headers: true)

      # Check row count
      if csv_data.length > MAX_CSV_ROWS
        return { valid: false, error: "CSV exceeds maximum allowed rows (#{MAX_CSV_ROWS})." }
      end

      # Validate required headers exist
      required_headers = [ "text", "book" ]
      headers = csv_data.headers.map(&:to_s).map(&:downcase)

      missing_headers = required_headers - headers
      if missing_headers.any?
        return { valid: false, error: "CSV missing required columns: #{missing_headers.join(', ')}" }
      end

      { valid: true }
    rescue CSV::MalformedCSVError => e
      { valid: false, error: "Malformed CSV file: #{e.message}" }
    rescue StandardError => e
      { valid: false, error: "Error validating CSV: #{e.message}" }
    ensure
      file.rewind
    end
  end

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

      # Safety check: Stop processing if row limit exceeded
      if result[:total_rows] > MAX_CSV_ROWS
        result[:errors] << "Maximum row limit (#{MAX_CSV_ROWS}) exceeded. Processing stopped."
        break
      end

      begin
        # Extract and sanitize data from CSV row
        text = row[:text]&.strip
        book = row[:book]&.strip
        chapter = row[:chapter]&.strip
        context = row[:context]&.strip
        character = row[:character]&.strip
        tags_string = row[:tags]&.strip

        # Security: Validate field lengths to prevent DoS
        if text && text.length > 2000
          result[:failed] += 1
          result[:errors] << "Row #{result[:total_rows]}: Text exceeds maximum length (2000 characters)"
          next
        end

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
