# The Quote model represents a single quote from J.R.R. Tolkien's works.
# This model is the core of "The Daily Tolkien" application, storing quotes
# that are displayed daily on the home page. Each quote includes metadata
# about its source and display history to manage the rotation system.
#
# The model ensures data integrity through validations and provides methods
# for selecting quotes for daily display.
class Quote < ApplicationRecord
  # Validations ensure that essential data is present and correctly formatted.
  # The text and book fields are required as they are fundamental to the quote.
  validates :text, presence: true
  validates :book, presence: true

  # days_displayed must be a non-negative integer, tracking how many times
  # this quote has been shown to users.
  validates :days_displayed, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # last_date_displayed and first_date_displayed are optional integers representing
  # Unix timestamps. They track when the quote was last and first displayed.
  # These can be nil if the quote hasn't been displayed yet.
  validates :last_date_displayed, numericality: { only_integer: true }, allow_nil: true
  validates :first_date_displayed, numericality: { only_integer: true }, allow_nil: true

  # chapter, context, and character are optional string fields that provide
  # additional metadata about the quote's origin and content.
  # No validations are needed here as they can be nil.
end
