# Archive Helper for The Daily Tolkien
# Provides helper methods for archive functionality including date formatting,
# quote snippets, navigation, and pagination information
module ArchiveHelper
  # Format Unix timestamp for archive date display with timezone support
  def format_archive_date(timestamp, timezone = "UTC")
    return nil unless timestamp

    Time.at(timestamp).in_time_zone(timezone).strftime("%B %d, %Y")
  end

  # Smart truncation preserving words for archive quote snippets
  def archive_quote_snippet(quote, length = 100)
    return "" unless quote&.text

    text = quote.text
    return text if text.length <= length

    # Find the last space within the length limit
    truncated = text[0, length]
    last_space = truncated.rindex(" ")

    # If no space found, just truncate at length
    return truncated + "..." unless last_space

    # Truncate at the last space and add ellipsis
    text[0, last_space] + "..."
  end

  # Generate link to specific archived date
  def archive_date_link(date, options = {})
    return "#" unless date

    date_string = date.is_a?(String) ? date : date.strftime("%Y-%m-%d")
    link_to(options[:text] || date_string, archive_path(date_string), options.except(:text))
  end

  # Format tags with "+X more" logic for archive display
  def readable_tag_list(tags, limit = 3)
    return content_tag(:span, "—", style: "color: #8b7355; font-style: italic;") if tags.blank?

    visible_tags = tags.limit(limit)
    remaining_count = tags.count - limit

    content = safe_join(
      visible_tags.map do |tag|
        content_tag(:span, tag.name, class: "tag-badge")
      end,
      " "
    )

    if remaining_count > 0
      content += " ".html_safe
      content += content_tag(:span, "+#{remaining_count} more",
                           style: "color: #8b7355; font-size: 0.75rem;")
    end

    content
  end

  # Pagination description text for archive
  def archive_pagination_info(collection)
    return "" unless collection.respond_to?(:current_page)

    start_item = (collection.current_page - 1) * collection.limit_value + 1
    end_item = [ start_item + collection.limit_value - 1, collection.total_count ].min

    "Showing #{start_item}-#{end_item} of #{collection.total_count} quotes"
  end

  # Convert Date object to archive URL path
  def date_to_archive_path(date)
    return archive_index_path unless date

    date_string = date.is_a?(String) ? date : date.strftime("%Y-%m-%d")
    archive_path(date_string)
  end

  # Validate YYYY-MM-DD format for archive dates
  def valid_archive_date?(date_string)
    return false unless date_string.is_a?(String)
    return false unless date_string.match?(/^\d{4}-\d{2}-\d{2}$/)

    begin
      Date.parse(date_string)
      true
    rescue ArgumentError
      false
    end
  end

  # Get min/max dates for archive date range
  def archive_date_range
    quotes = Quote.displayed
    return [ nil, nil ] if quotes.empty?

    min_timestamp = quotes.minimum(:last_date_displayed)
    max_timestamp = quotes.maximum(:last_date_displayed)

    min_date = min_timestamp ? Time.at(min_timestamp).to_date : nil
    max_date = max_timestamp ? Time.at(max_timestamp).to_date : nil

    [ min_date, max_date ]
  end

  # Format archive header date with day of week
  def archive_header_date(date, timezone = "UTC")
    return "Unknown Date" unless date

    formatted_date = date.is_a?(Date) ? date : Date.parse(date.to_s)
    day_of_week = formatted_date.strftime("%A")
    formatted = formatted_date.strftime("%B %d, %Y")

    { formatted: formatted, day_of_week: day_of_week }
  end

  # Generate breadcrumb navigation for archive pages
  def archive_breadcrumb(current_date = nil)
    breadcrumbs = [
      link_to("Home", root_path),
      current_date ? link_to("Archive", archive_index_path) : "Archive"
    ]

    if current_date
      date_text = current_date.is_a?(Date) ?
        current_date.strftime("%B %d, %Y") :
        current_date.to_s
      breadcrumbs << date_text
    end

    safe_join(breadcrumbs, " › ")
  end

  # Check if date has archived quote
  def archive_date_has_quote?(date)
    return false unless date

    Quote.displayed_on_date(date).exists?
  end

  # Get previous/next archive dates for navigation
  def archive_navigation_dates(current_date)
    return [ nil, nil ] unless current_date

    current_timestamp = current_date.beginning_of_day.to_i

    # Find previous date with a quote
    prev_quote = Quote.displayed
                      .where("last_date_displayed < ?", current_timestamp)
                      .order(last_date_displayed: :desc)
                      .first

    # Find next date with a quote
    next_quote = Quote.displayed
                      .where("last_date_displayed > ?", current_timestamp)
                      .order(last_date_displayed: :asc)
                      .first

    prev_date = prev_quote ? Time.at(prev_quote.last_date_displayed).to_date : nil
    next_date = next_quote ? Time.at(next_quote.last_date_displayed).to_date : nil

    [ prev_date, next_date ]
  end
end
