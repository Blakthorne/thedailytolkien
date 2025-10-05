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

### Option 2: SendPulse SMTP (Great Balance of Features & Price)

SendPulse offers a generous free tier (12,000 emails/month to 500 subscribers) and is excellent for transactional emails with good deliverability rates.

#### Step 1: Create SendPulse Account and Get SMTP Credentials

1. **Sign up for SendPulse**

    - Go to https://sendpulse.com/
    - Click "Sign Up" and create a free account
    - Verify your email address

2. **Access SMTP Settings**

    - Log in to your SendPulse dashboard
    - Navigate to **Settings** (gear icon in top right) → **SMTP**
    - Or go directly to: https://login.sendpulse.com/settings/smtp

3. **Generate SMTP Password**

    - In the SMTP settings page, you'll see:
        - **SMTP Server**: `smtp-pulse.com`
        - **Port**: `465` (SSL) or `2525` (TLS) or `25` (not recommended)
        - **Username**: Your SendPulse account email
    - Click **"Generate Password"** or **"Show Password"**
    - **Important**: Copy this SMTP password immediately - it's different from your login password
    - Store it securely (you'll need it for Rails configuration)

4. **Verify Your Sender Email/Domain** (Required)
    - Go to **Settings** → **Sender addresses**
    - Click **"Add sender address"**
    - Option A: **Single Email Verification** (Quick)
        - Enter: `noreply@thedailytolkien.com` (or your preferred sender)
        - SendPulse will send a verification email
        - Click the verification link
    - Option B: **Domain Verification** (Recommended for Production)
        - Enter your domain: `thedailytolkien.com`
        - SendPulse will provide DNS records to add:
            - **SPF record** (TXT record for domain authentication)
            - **DKIM record** (TXT record for email signing)
            - **Domain verification** (TXT record to prove ownership)
        - Add these records to your DNS provider
        - Wait 15-60 minutes for DNS propagation
        - Click "Verify Domain" in SendPulse

#### Step 2: Add DNS Records (For Domain Verification - Recommended)

If you chose domain verification above, add these records to your DNS:

```
Type: TXT
Host: @
Value: sendpulse-verification=abc123xyz... (from SendPulse)

Type: TXT
Host: @
Value: v=spf1 include:_spf.sendpulse.com ~all

Type: TXT
Host: pulse._domainkey
Value: k=rsa; p=MIGfMA0GCSqGSIb3... (DKIM key from SendPulse)
```

**DNS Configuration Tips:**

-   If using **Cloudflare**: Turn off proxy (gray cloud) for mail-related records
-   DNS changes can take 15-60 minutes to propagate
-   Verify with: `nslookup -type=TXT thedailytolkien.com`

#### Step 3: Add Credentials to Rails

```bash
# On your local machine
EDITOR="nano" rails credentials:edit

# Add these lines (using TLS on port 2525 - recommended):
smtp:
  user_name: your-sendpulse-email@example.com
  password: your-generated-smtp-password-here
  address: smtp-pulse.com
  port: 2525
  domain: thedailytolkien.com

# Alternative: Using SSL on port 465
smtp:
  user_name: your-sendpulse-email@example.com
  password: your-generated-smtp-password-here
  address: smtp-pulse.com
  port: 465
  domain: thedailytolkien.com

# Save and exit (Ctrl+X, Y, Enter in nano)
```

**Important Notes:**

-   `user_name` is your **SendPulse account email** (not "apikey")
-   `password` is the **generated SMTP password** (not your login password)
-   `port: 2525` uses TLS/STARTTLS (recommended for most servers)
-   `port: 465` uses SSL (use if port 2525 is blocked)
-   Avoid `port: 25` as it's often blocked by hosting providers

#### Step 4: Update production.rb

For **Port 2525 (TLS/STARTTLS - Recommended)**:

```ruby
# config/environments/production.rb

# Enable email delivery errors
config.action_mailer.raise_delivery_errors = true
config.action_mailer.delivery_method = :smtp
config.action_mailer.perform_deliveries = true

# Set host for links in mailer templates
config.action_mailer.default_url_options = { host: "thedailytolkien.com", protocol: 'https' }

# SendPulse SMTP configuration (TLS on port 2525)
config.action_mailer.smtp_settings = {
  user_name: Rails.application.credentials.dig(:smtp, :user_name),
  password: Rails.application.credentials.dig(:smtp, :password),
  address: Rails.application.credentials.dig(:smtp, :address),
  port: Rails.application.credentials.dig(:smtp, :port) || 2525,
  domain: Rails.application.credentials.dig(:smtp, :domain),
  authentication: :plain,
  enable_starttls_auto: true
}
```

For **Port 465 (SSL - Alternative)**:

```ruby
# SendPulse SMTP configuration (SSL on port 465)
config.action_mailer.smtp_settings = {
  user_name: Rails.application.credentials.dig(:smtp, :user_name),
  password: Rails.application.credentials.dig(:smtp, :password),
  address: Rails.application.credentials.dig(:smtp, :address),
  port: Rails.application.credentials.dig(:smtp, :port) || 465,
  domain: Rails.application.credentials.dig(:smtp, :domain),
  authentication: :plain,
  enable_starttls_auto: true,
  ssl: true,
  tls: true
}
```

#### Step 5: Configure Sender Email in Devise

```ruby
# config/initializers/devise.rb (around line 24)

# Must match verified sender in SendPulse
config.mailer_sender = 'noreply@thedailytolkien.com'
```

#### Step 6: Test SMTP Connection (Before Deploying)

```bash
# Test if SendPulse SMTP server is reachable
telnet smtp-pulse.com 2525

# Or using openssl for SSL/TLS:
openssl s_client -connect smtp-pulse.com:465
openssl s_client -connect smtp-pulse.com:2525 -starttls smtp

# Expected: Connection successful
# Exit: Ctrl+C
```

#### Step 7: Deploy and Test

```bash
# 1. Commit changes
git add config/environments/production.rb config/initializers/devise.rb
git commit -m "Configure SendPulse SMTP for production"
git push origin main

# 2. Deploy to server
ssh ubuntu@98.86.217.231
cd ~/thedailytolkien
git pull origin main
export RAILS_MASTER_KEY="your-master-key"
./deploy/deploy.sh

# 3. Test email sending
docker-compose -f docker-compose.prod.yml exec web bin/rails console

# Verify SMTP settings loaded
ActionMailer::Base.smtp_settings
# Should show: {:user_name=>"your-email@...", :address=>"smtp-pulse.com", :port=>2525, ...}

# Send test password reset
User.first.send_reset_password_instructions

# Or send manual test
ActionMailer::Base.mail(
  from: 'noreply@thedailytolkien.com',
  to: 'your-email@example.com',
  subject: 'SendPulse SMTP Test',
  body: 'This is a test from The Daily Tolkien via SendPulse SMTP'
).deliver_now

# Expected output: "Sent mail to your-email@example.com"
exit
```

#### Step 8: Verify in SendPulse Dashboard

1. Go to **Statistics** → **SMTP** in SendPulse
2. You should see:
    - **Emails sent**: Count of emails
    - **Delivery status**: Delivered, bounced, etc.
    - **Individual email tracking**: Opens, clicks (if enabled)

#### SendPulse Troubleshooting

**Error: "535 5.7.8 Authentication credentials invalid"**

-   **Cause**: Wrong SMTP password or username
-   **Fix**:
    -   Regenerate SMTP password in SendPulse settings
    -   Verify username is your SendPulse account email
    -   Check credentials: `Rails.application.credentials.dig(:smtp)`

**Error: "550 5.7.1 Sender address rejected"**

-   **Cause**: Sender email not verified in SendPulse
-   **Fix**:
    -   Go to SendPulse → Settings → Sender addresses
    -   Verify the email in `devise.rb` matches a verified sender
    -   Click verification link in email or complete domain verification

**Error: "Connection timeout" or "Connection refused"**

-   **Cause**: Port blocked by firewall
-   **Fix**:

    ```bash
    # Check firewall
    sudo ufw status

    # Allow ports
    sudo ufw allow 2525/tcp
    sudo ufw allow 465/tcp

    # Try alternative port (465 instead of 2525 or vice versa)
    ```

**Error: "Must issue a STARTTLS command first"**

-   **Cause**: TLS configuration mismatch
-   **Fix**:
    -   For port 2525: Use `enable_starttls_auto: true` (no ssl/tls options)
    -   For port 465: Use `enable_starttls_auto: true, ssl: true, tls: true`

**Emails go to spam**

-   **Fix**:
    -   Complete domain verification (not just email)
    -   Add SPF and DKIM DNS records
    -   Use consistent sender email
    -   Avoid spammy content
    -   Warm up sending (start with low volume)

#### SendPulse Free Tier Limits

-   **12,000 emails/month** to up to 500 subscribers
-   **Unlimited transactional emails** (password resets, confirmations, etc.)
-   Great deliverability rates
-   Email tracking and analytics
-   No credit card required for free tier

#### SendPulse Advantages

✅ **Generous free tier** (12,000 emails/month)  
✅ **Great for transactional emails** (password resets, notifications)  
✅ **Good deliverability** with proper domain setup  
✅ **Email tracking** and analytics dashboard  
✅ **Multiple SMTP ports** (25, 465, 2525) for firewall flexibility  
✅ **Easy domain verification** with clear DNS instructions  
✅ **No credit card required** for free plan

#### Quick Reference: SendPulse Credentials Format

```yaml
# In rails credentials:edit
smtp:
    user_name: your-sendpulse-email@example.com # Your SendPulse account email
    password: ABC123xyz... # Generated SMTP password (not login password)
    address: smtp-pulse.com # SendPulse SMTP server
    port: 2525 # TLS (recommended) or 465 for SSL
    domain: thedailytolkien.com # Your domain
```

### Option 3: SendGrid (Popular Alternative)

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

### Option 4: Mailgun (Alternative)

Similar to SendGrid:

```yaml
smtp:
    user_name: postmaster@your-domain.mailgun.org
    password: your-mailgun-password
    address: smtp.mailgun.org
    port: 587
    domain: thedailytolkien.com
```

### Option 5: AWS SES (Most Scalable)

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
-   **SendPulse**: Great balance of features & generous free tier (12,000 emails/month)
-   **SendGrid**: Popular choice, 100 emails/day free
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
