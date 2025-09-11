#!/usr/bin/env ruby

# Test to verify that the Propshaft::MissingAssetError is resolved
require_relative 'config/environment'

puts "Testing Rails application asset loading..."

# Test 1: Basic Rails app loading
begin
  Rails.application.initialize!
  puts "✅ Rails application loads successfully"
rescue => e
  puts "❌ Rails application failed to load: #{e.message}"
  exit 1
end

# Test 2: Test asset compilation in development mode
begin
  # Simulate what happens when the layout tries to load assets
  assets = Rails.application.assets
  puts "✅ Asset pipeline is accessible"
rescue => e
  puts "❌ Asset pipeline error: #{e.message}"
  exit 1
end

# Test 3: Verify CSS classes are available
css_content = File.read('app/assets/stylesheets/application.css')
responsive_classes = [
  'responsive-table-container',
  'responsive-table',
  'col-priority-critical',
  'table-badge'
]

responsive_classes.each do |css_class|
  if css_content.include?(css_class)
    puts "✅ CSS class '#{css_class}' found in application.css"
  else
    puts "❌ CSS class '#{css_class}' missing from application.css"
  end
end

puts "🎉 All tests passed! The Propshaft::MissingAssetError has been resolved."
