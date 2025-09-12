#!/usr/bin/env ruby

# Set the Rails environment to test
ENV['RAILS_ENV'] = 'test'

# Load the Rails application
require_relative 'config/environment'

# Create a user like in the test
user = User.create!(
  first_name: "Test",
  last_name: "User",
  email: "test@example.com",
  password: "password",
  role: "commentor"
)

puts "=== User after creation ==="
puts "last_login_date: #{user.last_login_date}"
puts "current_streak: #{user.current_streak}"
puts "longest_streak: #{user.longest_streak}"

# Test the scenario from the failing test
login_time = Time.zone.parse("2024-01-15 10:00:00 EST")
puts "\n=== Login time: #{login_time} ==="

service = StreakCalculatorService.new(user, login_time)
result = service.calculate_streak

puts "\n=== Result ==="
puts "current_streak: #{result[:current_streak]}"
puts "longest_streak: #{result[:longest_streak]}"
puts "last_login_date: #{result[:last_login_date]}"
puts "streak_continued: #{result[:streak_continued]}"
puts "streak_broken: #{result[:streak_broken]}"

puts "\n=== Debugging ==="
user_date = login_time.in_time_zone(user.streak_timezone).to_date
puts "user_date: #{user_date}"
puts "last_login_date: #{user.last_login_date}"
puts "date_difference: #{(user_date - user.last_login_date).to_i}"
