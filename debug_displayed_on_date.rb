#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

puts "=== Understanding displayed_on_date method ==="
puts

# Create a test quote
quote = Quote.create!(
  text: "Test quote for debugging",
  book: "Test Book", 
  character: "Test Character",
  last_date_displayed: 1.day.ago.to_i,
  first_date_displayed: 1.day.ago.to_i
)

date_string = Time.at(quote.last_date_displayed).strftime("%Y-%m-%d")
date = Date.parse(date_string)

puts "Quote last_date_displayed: #{quote.last_date_displayed}"
puts "Quote time: #{Time.at(quote.last_date_displayed)}"
puts "Date string: #{date_string}"
puts "Parsed date: #{date}"

# Check what displayed_on_date actually does
timestamp_start = date.beginning_of_day.to_i
timestamp_end = date.end_of_day.to_i

puts "\nManual calculation:"
puts "timestamp_start: #{timestamp_start} (#{Time.at(timestamp_start)})"
puts "timestamp_end: #{timestamp_end} (#{Time.at(timestamp_end)})"
puts "Quote timestamp in range? #{(timestamp_start..timestamp_end).include?(quote.last_date_displayed)}"

# Test the actual method
quotes_found = Quote.displayed_on_date(date)
puts "\nQuote.displayed_on_date(#{date}):"
puts "Quotes found: #{quotes_found.count}"

if quotes_found.any?
  found_quote = quotes_found.first
  puts "Found quote timestamp: #{found_quote.last_date_displayed}"
  puts "Found quote time: #{Time.at(found_quote.last_date_displayed)}"
end

# Let's also check what SQL query is generated
puts "\nSQL query generated:"
puts Quote.displayed_on_date(date).to_sql

# Clean up
quote.destroy

puts "\n=== Debug Complete ==="
