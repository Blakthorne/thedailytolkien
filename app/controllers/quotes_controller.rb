# The QuotesController handles the display of Tolkien quotes on the website.
# Currently, it provides an index action that shows a daily quote.
# In the future, it may include actions for browsing quotes or administrative functions.
class QuotesController < ApplicationController
  # The index action is responsible for displaying the daily Tolkien quote.
  # It selects a quote from the database using a rotation system where each quote
  # is displayed for an entire day before moving to the next one. The selection
  # prioritizes quotes that have never been displayed, then those with the oldest last display date.
  def index
    # Get today's date as a Unix timestamp (start of day)
    today_start = Time.now.beginning_of_day.to_i
    tomorrow_start = Time.now.beginning_of_day.tomorrow.to_i

    # Find if there's already a quote selected for today
    @quote = Quote.where.not(text: nil)
                   .where(last_date_displayed: today_start...tomorrow_start)
                   .first

    # If no quote for today, select the next one in rotation
    if @quote.nil?
      @quote = Quote.where.not(text: nil)
                    .order(Arel.sql("last_date_displayed IS NULL DESC, last_date_displayed ASC, id ASC"))
                    .first

      if @quote
        # Update display tracking information for the new daily quote
        @quote.days_displayed += 1
        @quote.last_date_displayed = today_start
        @quote.first_date_displayed ||= today_start
        @quote.save
      end
    end

    # If no quotes exist in the database, @quote will be nil.
    # The view should handle this case gracefully, perhaps by showing
    # a message indicating that quotes are being prepared.
  end
end
