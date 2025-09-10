# Service for detecting and validating user timezones
class TimezoneDetectionService
  COMMON_TIMEZONES = [
    "UTC",
    "Eastern Time (US & Canada)",
    "Central Time (US & Canada)",
    "Mountain Time (US & Canada)",
    "Pacific Time (US & Canada)",
    "London",
    "Paris",
    "Berlin",
    "Tokyo",
    "Sydney"
  ].freeze

  def self.detect_from_browser(timezone_offset_minutes)
    return "UTC" if timezone_offset_minutes.nil?

    # Convert offset minutes to hours (browser gives negative offset)
    offset_hours = -(timezone_offset_minutes.to_i / 60.0)

    # Find matching timezone
    matching_timezone = ActiveSupport::TimeZone.all.find do |tz|
      tz.utc_offset / 3600.0 == offset_hours
    end

    matching_timezone&.name || "UTC"
  end

  def self.validate_timezone(timezone_name)
    return "UTC" if timezone_name.blank?

    if ActiveSupport::TimeZone.all.map(&:name).include?(timezone_name)
      timezone_name
    else
      "UTC"
    end
  end

  def self.user_friendly_timezones
    ActiveSupport::TimeZone.all.map do |tz|
      [ tz.to_s, tz.name ]
    end.sort_by(&:first)
  end

  def self.common_timezones
    COMMON_TIMEZONES.map do |name|
      tz = ActiveSupport::TimeZone[name]
      [ tz.to_s, name ] if tz
    end.compact.sort_by(&:first)
  end

  def self.detect_from_ip(ip_address)
    # Placeholder for IP-based timezone detection
    # In a production app, you might use a service like:
    # - MaxMind GeoIP2
    # - IPStack
    # - ipgeolocation.io

    # For now, return UTC as safe default
    "UTC"
  end
end
