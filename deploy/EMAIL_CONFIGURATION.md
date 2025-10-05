# Email Configuration for Production

## Problem

When trying to send password reset emails in production, you receive a 500 error with the log message:

```
Internal Server Error: Connection refused - connect(2) for "localhost" port 25
```

## Root Cause

Rails is trying to use the default SMTP settings, which attempt to connect to a local mail server on `localhost:25`. Since there's no mail server running on your application server, the connection is refused.

## Solution

You need to configure Rails to use an external SMTP service for sending emails. Here are the recommended options:

### Option 1: Gmail SMTP (Easiest for Testing/Small Scale)

#### Step 1: Get App Password from Google

1. Go to your Google Account settings
2. Navigate to Security → 2-Step Verification
3. Scroll down to "App passwords"
4. Generate an app password for "Mail"
5. Save this password securely

#### Step 2: Add Credentials to Rails

```bash
# On your local machine
EDITOR="nano" rails credentials:edit

# Add these lines:
smtp:
  user_name: your-email@gmail.com
  password: your-app-password-here
  address: smtp.gmail.com
  port: 587
  domain: thedailytolkien.com

# Save and exit (Ctrl+X, Y, Enter in nano)
```

#### Step 3: Update production.rb

Uncomment and configure the SMTP settings in `config/environments/production.rb`:

```ruby
# Enable email delivery errors
config.action_mailer.raise_delivery_errors = true
config.action_mailer.delivery_method = :smtp

# Set host to be used by links generated in mailer templates
config.action_mailer.default_url_options = { host: "thedailytolkien.com", protocol: 'https' }

# Specify outgoing SMTP server
config.action_mailer.smtp_settings = {
  user_name: Rails.application.credentials.dig(:smtp, :user_name),
  password: Rails.application.credentials.dig(:smtp, :password),
  address: Rails.application.credentials.dig(:smtp, :address),
  port: Rails.application.credentials.dig(:smtp, :port),
  domain: Rails.application.credentials.dig(:smtp, :domain),
  authentication: :plain,
  enable_starttls_auto: true
}
```

### Option 2: SendGrid (Recommended for Production)

SendGrid offers 100 emails/day free tier, which is perfect for a small application.

#### Step 1: Sign up for SendGrid

1. Go to https://sendgrid.com/
2. Sign up for a free account
3. Verify your email
4. Create an API key: Settings → API Keys → Create API Key
5. Save the API key securely

#### Step 2: Add Credentials to Rails

```bash
EDITOR="nano" rails credentials:edit

# Add these lines:
smtp:
  user_name: apikey
  password: your-sendgrid-api-key-here
  address: smtp.sendgrid.net
  port: 587
  domain: thedailytolkien.com

# Save and exit
```

#### Step 3: Update production.rb

Same as Gmail option above.

#### Step 4: Verify Sender Identity

SendGrid requires sender verification:

1. Go to SendGrid → Settings → Sender Authentication
2. Verify a single sender email address OR
3. Authenticate your domain (recommended for production)

### Option 3: Mailgun (Alternative)

Similar to SendGrid:

```yaml
smtp:
    user_name: postmaster@your-domain.mailgun.org
    password: your-mailgun-password
    address: smtp.mailgun.org
    port: 587
    domain: thedailytolkien.com
```

### Option 4: AWS SES (Most Scalable)

For larger scale:

```yaml
smtp:
    user_name: your-ses-smtp-username
    password: your-ses-smtp-password
    address: email-smtp.us-east-1.amazonaws.com
    port: 587
    domain: thedailytolkien.com
```

## Implementation Steps

### 1. Choose Your SMTP Provider

Pick one of the options above based on your needs:

-   **Gmail**: Quick setup, good for testing
-   **SendGrid**: Best for production, generous free tier
-   **Mailgun**: Good alternative to SendGrid
-   **AWS SES**: Best for high volume

### 2. Update Your Code

Edit `config/environments/production.rb`:

```ruby
# Find this section around line 56-70
config.action_mailer.raise_delivery_errors = true
config.action_mailer.delivery_method = :smtp
config.action_mailer.perform_deliveries = true

# Set host to be used by links generated in mailer templates
config.action_mailer.default_url_options = { host: "thedailytolkien.com", protocol: 'https' }

# Specify outgoing SMTP server
config.action_mailer.smtp_settings = {
  user_name: Rails.application.credentials.dig(:smtp, :user_name),
  password: Rails.application.credentials.dig(:smtp, :password),
  address: Rails.application.credentials.dig(:smtp, :address),
  port: Rails.application.credentials.dig(:smtp, :port),
  domain: Rails.application.credentials.dig(:smtp, :domain),
  authentication: :plain,
  enable_starttls_auto: true
}
```

### 3. Update Rails Credentials

```bash
# On your local machine
EDITOR="nano" rails credentials:edit
```

Add your SMTP settings (example for SendGrid):

```yaml
smtp:
    user_name: apikey
    password: SG.your-actual-sendgrid-api-key
    address: smtp.sendgrid.net
    port: 587
    domain: thedailytolkien.com
```

### 4. Configure Devise Mailer

Make sure Devise knows what email to send from. Edit `config/initializers/devise.rb`:

```ruby
# Find this line (around line 24)
config.mailer_sender = 'noreply@thedailytolkien.com'
```

### 5. Commit and Deploy

```bash
# Commit the production.rb changes
git add config/environments/production.rb
git commit -m "Configure SMTP for production email sending"

# Push to repository
git push origin main

# Deploy to production
# (Your GitHub Actions will handle this, or manually:)
ssh ubuntu@98.86.217.231
cd ~/thedailytolkien
git pull origin main
export RAILS_MASTER_KEY="your-master-key"
./deploy/deploy.sh
```

### 6. Test Email Sending

```bash
# SSH to your server
ssh ubuntu@98.86.217.231

# Access Rails console
cd ~/thedailytolkien
docker-compose -f docker-compose.prod.yml exec web bin/rails console

# Send a test email
User.first.send_reset_password_instructions

# Or manually:
ActionMailer::Base.mail(
  from: 'noreply@thedailytolkien.com',
  to: 'your-email@example.com',
  subject: 'Test Email',
  body: 'This is a test email from The Daily Tolkien'
).deliver_now

# Exit console
exit
```

## Troubleshooting

### Issue: "Net::SMTPAuthenticationError"

**Cause**: Wrong username or password

**Solution**:

-   Verify credentials are correct
-   For Gmail: Make sure you're using an App Password, not your regular password
-   For SendGrid: Username should be literally "apikey"
-   Check credentials in Rails: `Rails.application.credentials.dig(:smtp, :password)`

### Issue: "Connection timeout"

**Cause**: Firewall blocking port 587

**Solution**:

```bash
# Check if port 587 is open
sudo ufw status
sudo ufw allow 587/tcp

# Test SMTP connection
telnet smtp.sendgrid.net 587
# or
openssl s_client -connect smtp.sendgrid.net:587 -starttls smtp
```

### Issue: "Must issue a STARTTLS command first"

**Cause**: STARTTLS not enabled

**Solution**: Make sure `enable_starttls_auto: true` is in your smtp_settings

### Issue: "Sender address rejected"

**Cause**: Sender not verified with email provider

**Solution**: Verify your sender email in SendGrid/Gmail settings

## Security Best Practices

1. **Never commit credentials to git**

    - Use Rails encrypted credentials
    - Keep `config/master.key` secure and out of version control

2. **Use environment-specific settings**

    - Different SMTP settings for development vs production
    - Test emails in development go to mailtrap.io or similar

3. **Monitor email sending**

    - Check SendGrid dashboard for delivery statistics
    - Set up bounce and spam complaint handling

4. **Rate limiting**

    - Be aware of your provider's rate limits
    - SendGrid free tier: 100 emails/day
    - Gmail: 500 emails/day

5. **SPF and DKIM**
    - Configure SPF records for your domain
    - Set up DKIM signing (SendGrid handles this automatically)

## Verification Checklist

-   [ ] SMTP credentials added to Rails encrypted credentials
-   [ ] `production.rb` configured with SMTP settings
-   [ ] `devise.rb` configured with correct sender email
-   [ ] Sender email verified with SMTP provider
-   [ ] Deployed to production
-   [ ] Tested password reset email sends successfully
-   [ ] Checked email arrives in inbox (not spam)
-   [ ] Verified links in email work correctly

## Quick Reference

### Check Current SMTP Configuration

```bash
# In Rails console on production
docker-compose -f docker-compose.prod.yml exec web bin/rails console

ActionMailer::Base.smtp_settings
# Should show your SMTP configuration

Rails.application.credentials.dig(:smtp)
# Should show your SMTP credentials
```

### View Email Logs

```bash
# Application logs
docker-compose -f docker-compose.prod.yml logs -f web | grep -i mail

# Check for email errors
docker-compose -f docker-compose.prod.yml logs web | grep -i "Net::SMTP\|Errno::ECONNREFUSED"
```

## Example: Complete production.rb Email Section

```ruby
# Around line 56-75 in config/environments/production.rb

# Email configuration
config.action_mailer.raise_delivery_errors = true
config.action_mailer.delivery_method = :smtp
config.action_mailer.perform_deliveries = true
config.action_mailer.default_url_options = {
  host: "thedailytolkien.com",
  protocol: 'https'
}

config.action_mailer.smtp_settings = {
  user_name: Rails.application.credentials.dig(:smtp, :user_name),
  password: Rails.application.credentials.dig(:smtp, :password),
  address: Rails.application.credentials.dig(:smtp, :address),
  port: Rails.application.credentials.dig(:smtp, :port) || 587,
  domain: Rails.application.credentials.dig(:smtp, :domain),
  authentication: :plain,
  enable_starttls_auto: true,
  open_timeout: 10,
  read_timeout: 10
}
```

## Next Steps

After configuring email:

1. Test the password reset flow thoroughly
2. Consider adding email delivery monitoring
3. Set up bounce handling
4. Configure email templates for your brand

## Support

If you continue to have issues:

1. Check production logs: `docker-compose -f docker-compose.prod.yml logs web`
2. Verify SMTP credentials: `Rails.application.credentials.dig(:smtp)`
3. Test SMTP connection: `telnet smtp.provider.com 587`
4. Check provider's status page for outages
