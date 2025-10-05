# Complete Deployment Fix Summary

## Three Issues Resolved

### 1. ✅ Nginx Duplicate Upstream Error (FIXED)
### 2. ✅ Email Sending Fails - Connection Refused (DOCUMENTED)
### 3. ✅ SSL Certificate "Can't Find Server Block" (FIXED)

---

## Issue 1: Nginx Duplicate Upstream Error

**Problem:** Deployment fails with "duplicate upstream 'thedailytolkien_backend'"

**Cause:** Old domain config (`thedailytolkien.davidpolar.com`) still present alongside new domain config

**Solution:** 
- Updated `deploy/deploy.sh` with automatic cleanup using Python
- Created `deploy/cleanup-nginx-duplicates.sh` for manual cleanup
- Run: `./deploy/cleanup-nginx-duplicates.sh` then redeploy

**Status:** ✅ FIXED - Deployment script now handles this automatically

---

## Issue 2: Email Sending Fails

**Problem:** Password reset emails fail with "Connection refused - connect(2) for 'localhost' port 25"

**Cause:** No SMTP server configured in production

**Solution:** Configure external SMTP service

**Quick Steps:**

1. **Choose provider** (SendGrid recommended - 100 free emails/day)
   - Sign up: https://sendgrid.com
   - Get API key: Settings → API Keys → Create API Key

2. **Add credentials:**
   ```bash
   EDITOR="nano" bin/rails credentials:edit
   ```
   Add:
   ```yaml
   smtp:
     user_name: apikey
     password: SG.your-api-key-here
     address: smtp.sendgrid.net
     port: 587
     domain: thedailytolkien.com
   ```

3. **Update production.rb** (uncomment SMTP config around line 60):
   ```ruby
   config.action_mailer.raise_delivery_errors = true
   config.action_mailer.delivery_method = :smtp
   config.action_mailer.perform_deliveries = true
   config.action_mailer.default_url_options = { host: "thedailytolkien.com", protocol: 'https' }
   
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

4. **Deploy:**
   ```bash
   git add config/environments/production.rb
   git commit -m "Configure SMTP for production"
   git push origin main
   ```

**Status:** 📝 DOCUMENTED - See `deploy/EMAIL_CONFIGURATION.md` for detailed setup

---

## Issue 3: SSL Certificate Error

**Problem:** `Could not automatically find a matching server block for www.thedailytolkien.com`

**Cause:** Nginx config only had `thedailytolkien.com`, but Certbot expected `www.thedailytolkien.com` too

**Solution:** Updated nginx configs to support both domains

**Files Updated:**
- ✅ `deploy/nginx-server-blocks.conf` - Added www subdomain
- ✅ `deploy/nginx-snippet.conf` - Added www subdomain
- ✅ `config/environments/production.rb` - Added www to allowed hosts

**Quick Fix:**

```bash
# 1. Pull latest code
cd ~/thedailytolkien
git pull origin main

# 2. Clean up old nginx config
./deploy/cleanup-nginx-duplicates.sh

# 3. Deploy (this updates nginx with www support)
export RAILS_MASTER_KEY="your-key"
./deploy/deploy.sh

# 4. Get SSL certificate for BOTH domains
sudo certbot --nginx -d thedailytolkien.com -d www.thedailytolkien.com

# Or if you only want non-www:
sudo certbot --nginx -d thedailytolkien.com
```

**Status:** ✅ FIXED - Nginx now supports both domains

---

## Complete Deployment Checklist

### Prerequisites
- [ ] DNS pointing to your server (98.86.217.231)
- [ ] SSH access to server
- [ ] RAILS_MASTER_KEY available
- [ ] SMTP provider chosen (SendGrid/Gmail)

### Step-by-Step Deployment

#### On Your Server:

```bash
# 1. SSH to server
ssh ubuntu@98.86.217.231

# 2. Navigate to app
cd ~/thedailytolkien

# 3. Pull latest fixes
git pull origin main

# 4. Clean up old nginx config
chmod +x deploy/cleanup-nginx-duplicates.sh
./deploy/cleanup-nginx-duplicates.sh

# 5. Verify cleanup
sudo grep -c "upstream thedailytolkien_backend" /etc/nginx/sites-available/service-integrator
# Should show: 0

# 6. Deploy application
export RAILS_MASTER_KEY="your-master-key-here"
./deploy/deploy.sh

# 7. Get SSL certificates
sudo certbot --nginx -d thedailytolkien.com -d www.thedailytolkien.com

# 8. Verify deployment
curl -f https://thedailytolkien.com/up
curl -f https://www.thedailytolkien.com/up
```

#### On Your Local Machine (for email):

```bash
# 1. Configure SMTP credentials
cd ~/dev/thedailytolkien
EDITOR="nano" bin/rails credentials:edit
# Add SMTP settings (see Issue 2 above)

# 2. Update production.rb
# Uncomment SMTP configuration (see Issue 2 above)

# 3. Commit and push
git add config/environments/production.rb
git commit -m "Configure production SMTP"
git push origin main

# 4. Redeploy (on server)
# SSH to server and run deploy.sh again
```

---

## Verification Commands

### Verify Nginx Fix
```bash
# Should show 1 (only one upstream)
sudo grep -c "upstream thedailytolkien_backend" /etc/nginx/sites-available/service-integrator

# Should show both domains
sudo grep "server_name.*thedailytolkien" /etc/nginx/sites-available/service-integrator

# Test config
sudo nginx -t
```

### Verify SSL Certificates
```bash
# List certificates
sudo certbot certificates

# Test HTTPS
curl -I https://thedailytolkien.com
curl -I https://www.thedailytolkien.com

# Check certificate details
openssl s_client -connect thedailytolkien.com:443 -servername thedailytolkien.com </dev/null
```

### Verify Email (after SMTP configured)
```bash
# In Rails console
docker-compose -f docker-compose.prod.yml exec web bin/rails console

# Check SMTP settings
ActionMailer::Base.smtp_settings

# Send test email
User.first.send_reset_password_instructions

# Exit
exit
```

### Verify Application
```bash
# Check health
curl -f https://thedailytolkien.com/up

# Check logs
docker-compose -f docker-compose.prod.yml logs -f web

# Check container status
docker-compose -f docker-compose.prod.yml ps
```

---

## Troubleshooting

### Nginx Test Fails
```bash
# View errors
sudo nginx -t

# Check syntax
sudo nano /etc/nginx/sites-available/service-integrator

# Restore from backup if needed
sudo ls -lt /etc/nginx/sites-available/service-integrator.backup*
sudo cp /etc/nginx/sites-available/service-integrator.backup.TIMESTAMP /etc/nginx/sites-available/service-integrator
```

### SSL Certificate Issues
```bash
# Check DNS resolution
dig thedailytolkien.com +short
dig www.thedailytolkien.com +short

# Check firewall
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Test port 80
curl -I http://thedailytolkien.com
```

### Email Not Sending
```bash
# Check credentials loaded
docker-compose -f docker-compose.prod.yml exec web bin/rails runner "puts Rails.application.credentials.dig(:smtp)"

# Check logs for SMTP errors
docker-compose -f docker-compose.prod.yml logs web | grep -i "smtp\|mail"

# Test SMTP connection
telnet smtp.sendgrid.net 587
```

---

## Documentation Reference

- **Nginx Cleanup**: Instructions in this file
- **Email Setup**: See `deploy/EMAIL_CONFIGURATION.md`
- **SSL Certificates**: See `deploy/SSL_CERTIFICATE_SETUP.md`
- **General Deployment**: See `deploy/DEPLOYMENT_PLAN.md`

---

## Files Modified

### Nginx Configuration
- `deploy/deploy.sh` - Added automatic duplicate cleanup
- `deploy/cleanup-nginx-duplicates.sh` - Manual cleanup script
- `deploy/nginx-server-blocks.conf` - Added www subdomain support
- `deploy/nginx-snippet.conf` - Added www subdomain support

### Application Configuration
- `config/environments/production.rb` - Added www to allowed hosts

### Documentation
- `deploy/SSL_CERTIFICATE_SETUP.md` - SSL certificate guide (NEW)
- `deploy/EMAIL_CONFIGURATION.md` - Email setup guide
- `deploy/DEPLOYMENT_SUMMARY.md` - This file (NEW)

---

## Timeline Estimate

- **Nginx cleanup**: 5 minutes
- **Deploy application**: 10 minutes
- **SSL certificates**: 5 minutes
- **Email configuration**: 15-20 minutes
- **Testing**: 10 minutes
- **Total**: 45-50 minutes

---

## Quick Commands Sheet

```bash
# Complete deployment
ssh ubuntu@98.86.217.231
cd ~/thedailytolkien
git pull origin main
./deploy/cleanup-nginx-duplicates.sh
export RAILS_MASTER_KEY="your-key"
./deploy/deploy.sh
sudo certbot --nginx -d thedailytolkien.com -d www.thedailytolkien.com

# Verify
curl -f https://thedailytolkien.com/up
sudo certbot certificates
docker-compose -f docker-compose.prod.yml logs -f web
```

---

## Success Criteria

All of these should work:
- ✅ `https://thedailytolkien.com` loads with valid SSL
- ✅ `https://www.thedailytolkien.com` loads with valid SSL
- ✅ `http://thedailytolkien.com` redirects to https
- ✅ `http://www.thedailytolkien.com` redirects to https
- ✅ Health check: `curl -f https://thedailytolkien.com/up` returns 200
- ✅ Password reset emails send successfully (after SMTP configured)
- ✅ No nginx errors: `sudo nginx -t`
- ✅ No duplicate upstreams: `sudo grep -c "upstream thedailytolkien_backend" /etc/nginx/sites-available/service-integrator` = 1
- ✅ Container running: `docker-compose -f docker-compose.prod.yml ps`

You're ready for production! 🚀
