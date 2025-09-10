require "test_helper"

class TimezoneDetectionServiceTest < ActiveSupport::TestCase
  test "detect_from_browser should convert offset to timezone" do
    # Eastern Standard Time: UTC-5 = -300 minutes browser offset
    timezone = TimezoneDetectionService.detect_from_browser(-300)
    assert_includes ActiveSupport::TimeZone.all.map(&:name), timezone

    # UTC: 0 minutes offset - should return a valid UTC-based timezone
    timezone = TimezoneDetectionService.detect_from_browser(0)
    utc_zones = ActiveSupport::TimeZone.all.select { |tz| tz.utc_offset == 0 }.map(&:name)
    assert_includes utc_zones, timezone

    # Pacific Standard Time: UTC-8 = -480 minutes browser offset
    timezone = TimezoneDetectionService.detect_from_browser(-480)
    assert_includes ActiveSupport::TimeZone.all.map(&:name), timezone
  end

  test "detect_from_browser should handle nil input" do
    timezone = TimezoneDetectionService.detect_from_browser(nil)
    assert_equal "UTC", timezone
  end

  test "detect_from_browser should handle invalid offset" do
    # Very large offset that doesn't match any timezone
    timezone = TimezoneDetectionService.detect_from_browser(-2000)
    assert_equal "UTC", timezone
  end

  test "validate_timezone should return valid timezone" do
    timezone = TimezoneDetectionService.validate_timezone("Eastern Time (US & Canada)")
    assert_equal "Eastern Time (US & Canada)", timezone

    timezone = TimezoneDetectionService.validate_timezone("UTC")
    assert_includes ActiveSupport::TimeZone.all.map(&:name), timezone
  end

  test "validate_timezone should return UTC for invalid timezone" do
    timezone = TimezoneDetectionService.validate_timezone("Invalid/Timezone")
    assert_equal "UTC", timezone

    timezone = TimezoneDetectionService.validate_timezone("")
    assert_equal "UTC", timezone

    timezone = TimezoneDetectionService.validate_timezone(nil)
    assert_equal "UTC", timezone
  end

  test "user_friendly_timezones should return formatted list" do
    timezones = TimezoneDetectionService.user_friendly_timezones

    assert timezones.is_a?(Array)
    assert timezones.length > 0

    # Each entry should be [display_name, timezone_name]
    first_entry = timezones.first
    assert first_entry.is_a?(Array)
    assert_equal 2, first_entry.length

    # Should be sorted by display name
    display_names = timezones.map(&:first)
    assert_equal display_names, display_names.sort
  end

  test "common_timezones should include expected zones" do
    common = TimezoneDetectionService.common_timezones
    timezone_names = common.map(&:last)

    assert_includes timezone_names, "UTC"
    assert_includes timezone_names, "Eastern Time (US & Canada)"
    assert_includes timezone_names, "Pacific Time (US & Canada)"
    assert_includes timezone_names, "London"

    # Should be sorted by display name
    display_names = common.map(&:first)
    assert_equal display_names, display_names.sort
  end

  test "detect_from_ip should return UTC as fallback" do
    # This is a placeholder implementation
    timezone = TimezoneDetectionService.detect_from_ip("192.168.1.1")
    assert_equal "UTC", timezone

    timezone = TimezoneDetectionService.detect_from_ip("invalid-ip")
    assert_equal "UTC", timezone

    timezone = TimezoneDetectionService.detect_from_ip(nil)
    assert_equal "UTC", timezone
  end

  test "should handle common browser timezone offsets correctly" do
    test_cases = [
      { offset: 0, expected_hours: 0 },      # UTC/GMT
      { offset: -60, expected_hours: 1 },    # GMT+1
      { offset: -120, expected_hours: 2 },   # GMT+2
      { offset: -300, expected_hours: 5 },   # EST
      { offset: -360, expected_hours: 6 },   # CST
      { offset: -420, expected_hours: 7 },   # MST
      { offset: -480, expected_hours: 8 }    # PST
    ]

    test_cases.each do |test_case|
      timezone = TimezoneDetectionService.detect_from_browser(test_case[:offset])

      # Verify timezone is valid and has the expected UTC offset
      tz = ActiveSupport::TimeZone[timezone]
      assert_not_nil tz, "Should return a valid timezone for offset #{test_case[:offset]}"

      expected_offset_seconds = test_case[:expected_hours] * 3600
      assert_equal expected_offset_seconds, tz.utc_offset,
        "Timezone '#{timezone}' should have UTC offset of #{test_case[:expected_hours]} hours"
    end
  end
end
