# Setup script for admin demo
puts "Setting up admin demo data..."

# Check if we have users
puts "\nCurrent users:"
User.all.each do |user|
  puts "- #{user.email} (#{user.role})"
end

# Create admin user if none exists
admin = User.find_by(role: 'admin')
unless admin
  puts "\nCreating admin user..."
  admin = User.create!(
    name: "Admin User",
    email: "admin@thedailytolkien.com",
    password: "password123",
    password_confirmation: "password123",
    role: "admin"
  )
  puts "Created admin user: #{admin.email}"
end

# Check quotes
puts "\nCurrent quotes count: #{Quote.count}"
if Quote.count < 5
  puts "Creating sample quotes..."
  [
    { quote: "All we have to decide is what to do with the time that is given us.",
      author: "Gandalf",
      book: "Fellowship of the Ring" },
    { quote: "Even the smallest person can change the course of the future.",
      author: "Galadriel",
      book: "Fellowship of the Ring" },
    { quote: "I will not say: do not weep; for not all tears are an evil.",
      author: "Gandalf",
      book: "Return of the King" },
    { quote: "The world is indeed full of peril, and in it there are many dark places.",
      author: "Haldir",
      book: "Fellowship of the Ring" }
  ].each do |quote_data|
    Quote.create!(quote_data)
  end
  puts "Created sample quotes"
end

# Check activity logs
puts "\nCurrent activity logs count: #{ActivityLog.count}"

puts "\nSetup complete!"
puts "Admin email: #{admin.email}"
puts "Admin password: password123"
puts "Access admin at: http://localhost:3000/admin"
