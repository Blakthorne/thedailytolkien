#!/usr/bin/env ruby

# Set the Rails environment to test
ENV['RAILS_ENV'] = 'test'

# Load the Rails application
require_relative 'config/environment'

# Clear existing quotes to start fresh
Quote.delete_all

# Create a quote like in the test
quote = Quote.create!(
  text: "Test quote for archive controller testing",
  book: "Test Book",
  character: "Test Character",
  last_date_displayed: 1.day.ago.to_i,
  first_date_displayed: 1.day.ago.to_i
)

puts "=== Created quote ==="
puts "ID: #{quote.id}"
puts "Text: #{quote.text}"
puts "last_date_displayed: #{quote.last_date_displayed}"
puts "Time: #{Time.at(quote.last_date_displayed)}"

# Try to get the date string like the test does
date_string = Time.at(quote.last_date_displayed).strftime("%Y-%m-%d")
puts "\n=== Date string: #{date_string} ==="

# Convert back to date like the controller does
date = Date.parse(date_string)
puts "Parsed date: #{date}"

# Test displayed_on_date method
quotes = Quote.displayed_on_date(date)
puts "\n=== Quotes found for #{date}: #{quotes.count} ==="
quotes.each do |q|
  puts "  - Text: #{q.text[0..50]}..."
end

# Let's check the UTC range calculation
start_time = date.beginning_of_day.in_time_zone('UTC').to_i
end_time = date.end_of_day.in_time_zone('UTC').to_i
puts "\n=== UTC range ==="
puts "Start: #{start_time} (#{Time.at(start_time)})"
puts "End: #{end_time} (#{Time.at(end_time)})"
puts "Quote timestamp: #{quote.last_date_displayed} (#{Time.at(quote.last_date_displayed)})"
puts "In range? #{quote.last_date_displayed >= start_time && quote.last_date_displayed <= end_time}"
