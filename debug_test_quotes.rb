#!/usr/bin/env ruby

# Set the Rails environment to test
ENV['RAILS_ENV'] = 'test'

# Load the Rails application
require_relative 'config/environment'

puts "=== All quotes in test database ==="
Quote.all.each do |quote|
  time = Time.at(quote.last_date_displayed)
  puts "ID: #{quote.id}, Text: #{quote.text[0..50]}..., last_date_displayed: #{quote.last_date_displayed} (#{time})"
end

puts "\n=== Testing displayed_on_date for 2025-09-10 ==="
date = Date.new(2025, 9, 10)
quotes = Quote.displayed_on_date(date)
puts "Found #{quotes.count} quotes for #{date}"
quotes.each do |quote|
  time = Time.at(quote.last_date_displayed)
  puts "  - Text: #{quote.text[0..50]}..., last_date_displayed: #{quote.last_date_displayed} (#{time})"
end
