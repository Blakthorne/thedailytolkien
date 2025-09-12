#!/usr/bin/env ruby

# Set the Rails environment to test
ENV['RAILS_ENV'] = 'test'

# Load the Rails application
require_relative 'config/environment'

date = Date.new(2025, 9, 10)
puts "Date: #{date}"

# Calculate UTC range like displayed_on_date does
start_time = date.beginning_of_day.in_time_zone('UTC').to_i
end_time = date.end_of_day.in_time_zone('UTC').to_i

puts "UTC range:"
puts "Start: #{start_time} (#{Time.at(start_time)})"
puts "End: #{end_time} (#{Time.at(end_time)})"

# The quote timestamp from our test
quote_timestamp = 1757550432
puts "\nQuote timestamp: #{quote_timestamp} (#{Time.at(quote_timestamp)})"
puts "In range? #{quote_timestamp >= start_time && quote_timestamp <= end_time}"

# Let's also check what 1.day.ago gives us right now
yesterday_timestamp = 1.day.ago.to_i
puts "\n1.day.ago timestamp: #{yesterday_timestamp} (#{Time.at(yesterday_timestamp)})"

# And let's see what date that corresponds to in different timezones
puts "Yesterday as date (local): #{Time.at(yesterday_timestamp).to_date}"
puts "Yesterday as date (UTC): #{Time.at(yesterday_timestamp).utc.to_date}"
