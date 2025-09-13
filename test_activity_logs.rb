require_relative 'config/environment'

begin
  puts "Testing activity logs rendering..."

  # Create test activity
  admin = User.find_by(role: 'admin')
  activity = ActivityLog.create!(
    user: admin,
    action: 'dashboard_view',
    ip_address: '127.0.0.1',
    user_agent: 'Test'
  )

  puts "Activity created: #{activity.id}"

  # Try to render the view
  app = ActionDispatch::Integration::Session.new(Rails.application)
  app.host = 'localhost'
  app.post '/users/sign_in', params: {
    user: { email: admin.email, password: 'password123' }
  }

  puts "Signed in, now accessing activity logs..."
  app.get '/admin/activity_logs'

  puts "Response status: #{app.response.status}"
  if app.response.status != 200
    puts "Error response body:"
    puts app.response.body
  else
    puts "Success! Page loaded."
  end

rescue => e
  puts "Error: #{e.class.name}: #{e.message}"
  puts e.backtrace.first(5)
end
