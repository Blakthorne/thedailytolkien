#!/usr/bin/env ruby

# Create sample tags for testing
tags_data = [
  { name: 'wisdom', description: 'Quotes about wisdom and knowledge' },
  { name: 'courage', description: 'Quotes about bravery and heroism' },
  { name: 'friendship', description: 'Quotes about companionship and loyalty' },
  { name: 'hope', description: 'Quotes about hope and perseverance' },
  { name: 'gandalf', description: 'Quotes spoken by Gandalf' },
  { name: 'frodo', description: 'Quotes spoken by Frodo' },
  { name: 'aragorn', description: 'Quotes spoken by Aragorn' }
]

tags_data.each do |tag_data|
  tag = Tag.find_or_create_by(name: tag_data[:name]) do |t|
    t.description = tag_data[:description]
  end
  puts "Created/Found tag: #{tag.name}"
end

puts "Created #{tags_data.count} test tags successfully!"
