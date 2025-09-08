require "test_helper"

class SortingAlgorithmTest < ActiveSupport::TestCase
  test "natural comparison handles mixed alphanumeric content correctly" do
    # Test data that would fail with simple string comparison
    test_pairs = [
      [ "Chapter 1", "Chapter 2", -1 ],    # 1 < 2
      [ "Chapter 2", "Chapter 10", -1 ],   # 2 < 10 (not "10" < "2" in string sort)
      [ "Chapter 10", "Chapter 20", -1 ],  # 10 < 20
      [ "Chapter 20", "Chapter 100", -1 ], # 20 < 100
      [ "Chapter 100", "Chapter 20", 1 ],  # 100 > 20
      [ "abc", "def", -1 ],                # Simple alphabetic
      [ "Item1", "Item10", -1 ],           # Mixed alphanumeric
      [ "Item10", "Item2", 1 ]            # 10 > 2 numerically
    ]

    test_pairs.each do |a, b, expected|
      result = natural_compare(a.downcase, b.downcase)
      # Normalize result to -1, 0, or 1
      normalized = result < 0 ? -1 : (result > 0 ? 1 : 0)
      assert_equal expected, normalized, "natural_compare('#{a}', '#{b}') should return #{expected} but got #{result}"
    end
  end

  test "numeric type detection works correctly" do
    test_cases = [
      [ "123", true ],
      [ "123.45", true ],
      [ "0", true ],
      [ "12.0", true ],
      [ "abc", false ],
      [ "123abc", false ],
      [ "", false ],
      [ "12.34.56", false ] # Invalid number
    ]

    test_cases.each do |value, expected|
      result = is_numeric(value)
      assert_equal expected, result, "is_numeric('#{value}') should return #{expected}"
    end
  end

  test "column type detection logic" do
    # Simulate rows data for type detection
    numeric_rows = [
      [ "1", "2", "10", "20", "100" ]
    ]

    text_rows = [
      [ "Chapter 1", "Chapter 2", "Book Title", "Author Name", "Character" ]
    ]

    mixed_rows = [
      [ "123", "abc", "456", "def", "789" ]
    ]

    # Test numeric detection (80% threshold)
    assert_equal "numeric", detect_column_type_ruby(numeric_rows[0])
    assert_equal "text", detect_column_type_ruby(text_rows[0])
    assert_equal "text", detect_column_type_ruby(mixed_rows[0]) # Mixed should default to text
  end

  private

  # Ruby implementation of the JavaScript natural comparison function
  def natural_compare(a, b)
    ax = []
    bx = []

    a.gsub(/(\d+)|(\D+)/) { ax << [ $1 ? $1.to_i : Float::INFINITY, $2 || "" ] }
    b.gsub(/(\d+)|(\D+)/) { bx << [ $1 ? $1.to_i : Float::INFINITY, $2 || "" ] }

    while !ax.empty? && !bx.empty?
      an = ax.shift
      bn = bx.shift
      nn = (an[0] <=> bn[0]).nonzero? || (an[1] <=> bn[1])
      return nn if nn != 0
    end

    ax.length - bx.length
  end

  # Ruby implementation of numeric detection
  def is_numeric(value)
    return false if value.nil? || value.strip.empty?
    /^\d+$/.match?(value) || /^\d+\.\d+$/.match?(value)
  end

  # Ruby implementation of column type detection
  def detect_column_type_ruby(sample_values)
    return "text" if sample_values.empty?

    numeric_count = 0
    total_samples = 0

    sample_values.each do |value|
      next if value.nil? || value.strip.empty?
      total_samples += 1
      numeric_count += 1 if is_numeric(value)
    end

    return "text" if total_samples == 0

    numeric_ratio = numeric_count.to_f / total_samples
    return "numeric" if numeric_ratio >= 0.8
    "text"
  end
end
