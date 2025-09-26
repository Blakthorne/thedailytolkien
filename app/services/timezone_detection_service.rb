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

  # Map a numeric offset (in minutes) to a representative Rails timezone name.
  # Note: Offsets are not unique across timezones and can vary with DST.
  # This should only be used as a last-resort fallback when no IANA name is available.
  def self.detect_from_browser(timezone_offset_minutes)
    return "UTC" if timezone_offset_minutes.nil?

    # Convert offset minutes to seconds (browser gives negative offset for locations behind UTC)
    offset_seconds = -(timezone_offset_minutes.to_i * 60)

    # Find a Rails timezone that currently matches the given offset
    matching_timezone = ActiveSupport::TimeZone.all.find do |tz|
      tz.utc_offset == offset_seconds
    end

    matching_timezone&.name || "UTC"
  end

  # Resolve and validate a timezone from a possibly-IANA identifier or Rails name,
  # with an optional numeric offset (minutes) as a fallback.
  def self.validate_timezone(timezone_name, fallback_offset_minutes = nil)
    # Prefer explicit name if present
    if timezone_name.present?
      # Time.find_zone accepts IANA identifiers (e.g., "America/New_York") and Rails names
      tz = Time.find_zone(timezone_name)
      if tz
        # If an IANA identifier was provided, map back to Rails-friendly name when possible
        # Example: "America/New_York" => "Eastern Time (US & Canada)"
        iana = tz.tzinfo&.identifier || timezone_name
        rails_name = preferred_rails_name_for_iana(iana) || tz.name
        return rails_name
      end
    end

    # Fallback: try to guess from offset
    if fallback_offset_minutes
      return detect_from_browser(fallback_offset_minutes)
    end

    # Default safe fallback
    "UTC"
  end

  # Choose a deterministic, human-friendly Rails name when multiple aliases
  # point to the same IANA zone (e.g., Europe/London => ["Edinburgh", "London", "Dublin"]).
  def self.preferred_rails_name_for_iana(iana_identifier)
    candidates = ActiveSupport::TimeZone::MAPPING.select { |_, v| v == iana_identifier }.keys
    return nil if candidates.empty?

    # Preference list for well-known ambiguous mappings
    preference = [
      "Eastern Time (US & Canada)",
      "Central Time (US & Canada)",
      "Mountain Time (US & Canada)",
      "Pacific Time (US & Canada)",
      "London"
    ]

    preferred = (candidates & preference).first
    preferred || candidates.first
  end

  def self.user_friendly_timezones
    ActiveSupport::TimeZone.all.map { |tz| [ tz.to_s, tz.name ] }.sort_by(&:first)
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
