#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

puts "=== Archive Date Issue Debugging ==="
puts

# Create a test quote similar to the test
quote = Quote.create!(
  text: "Test quote for debugging",
  book: "Test Book",
  character: "Test Character",
  last_date_displayed: 1.day.ago.to_i,
  first_date_displayed: 1.day.ago.to_i
)

puts "Created quote with last_date_displayed: #{quote.last_date_displayed}"
puts "Time.at(#{quote.last_date_displayed}): #{Time.at(quote.last_date_displayed)}"

# Generate date string like the test does
date_string = Time.at(quote.last_date_displayed).strftime("%Y-%m-%d")
puts "Date string: #{date_string}"

# Test the controller logic
date = Date.parse(date_string).in_time_zone("UTC")
puts "Parsed date in UTC: #{date}"
puts "Date beginning_of_day: #{date.beginning_of_day}"
puts "Date end_of_day: #{date.end_of_day}"

timestamp_start = date.beginning_of_day.to_i
timestamp_end = date.end_of_day.to_i
puts "Timestamp range: #{timestamp_start} to #{timestamp_end}"
puts "Quote timestamp: #{quote.last_date_displayed}"
puts "Is quote timestamp in range? #{(timestamp_start..timestamp_end).include?(quote.last_date_displayed)}"

# Test the displayed_on_date method
quotes = Quote.displayed_on_date(date.to_date)
puts "Quotes found by displayed_on_date: #{quotes.count}"

# Clean up
quote.destroy

puts "\n=== Debug Complete ==="
