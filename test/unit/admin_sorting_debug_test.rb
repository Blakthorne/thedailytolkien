require "test_helper"

class AdminSortingDebugTest < ActiveSupport::TestCase
  test "string comparison works as expected" do
    # Test basic string comparison to verify our logic
    strings = [
      "You shall not pass!",
      "Even the smallest person can change the course of the future",
      "All that is gold does not glitter"
    ]

    # Convert to lowercase and sort
    sorted = strings.map(&:downcase).sort
    puts "Original strings: #{strings}"
    puts "Sorted strings: #{sorted}"

    expected = [
      "all that is gold does not glitter",
      "even the smallest person can change the course of the future",
      "you shall not pass!"
    ]

    assert_equal expected, sorted, "Basic string sorting should work alphabetically"
  end

  test "book names sort correctly" do
    books = [
      "The Two Towers",
      "The Fellowship of the Ring",
      "The Return of the King"
    ]

    sorted = books.map(&:downcase).sort
    puts "Original books: #{books}"
    puts "Sorted books: #{sorted}"

    expected = [
      "the fellowship of the ring",
      "the return of the king",
      "the two towers"
    ]

    assert_equal expected, sorted, "Book names should sort alphabetically"
  end

  test "javascript comparison function" do
    # Test the comparison logic we're using in JavaScript
    def js_compare(a, b)
      a = a.downcase.strip
      b = b.downcase.strip
      return -1 if a < b
      return 1 if a > b
      0
    end

    # Test cases
    assert_equal(-1, js_compare("All that is gold", "Even the smallest"))
    assert_equal(1, js_compare("You shall not pass", "All that is gold"))
    assert_equal(0, js_compare("Same text", "Same text"))

    # Test with quote marks
    assert_equal(-1, js_compare('"All that is gold"', '"Even the smallest"'))
  end
end
