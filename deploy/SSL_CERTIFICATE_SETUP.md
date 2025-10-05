# SSL Certificate Setup Guide

## Issue: Certbot Can't Find Server Block

**Error Message:**
```
Could not automatically find a matching server block for www.thedailytolkien.com. 
Set the `server_name` directive to use the Nginx installer.
```

**Cause:** Certbot was looking for `www.thedailytolkien.com` but your nginx configuration only had `thedailytolkien.com`.

**Solution:** The nginx configuration has been updated to support both domains.

---

## Quick Fix Steps

### Option 1: Certificate for Both Domains (Recommended)

This is the **recommended approach** as it handles both `thedailytolkien.com` and `www.thedailytolkien.com`.

```bash
# 1. SSH to your server
ssh ubuntu@98.86.217.231

# 2. Navigate to app directory
cd ~/thedailytolkien

# 3. Pull latest changes (includes www subdomain support)
git pull origin main

# 4. Remove old nginx config (if deployment hasn't run yet)
./deploy/cleanup-nginx-duplicates.sh

# 5. Manually update nginx config with new version
sudo bash -c "cat deploy/nginx-server-blocks.conf > /tmp/tdt-nginx.conf"
sudo bash -c "cat /tmp/tdt-nginx.conf >> /etc/nginx/sites-available/service-integrator"

# 6. Test nginx configuration
sudo nginx -t

# 7. Reload nginx
sudo systemctl reload nginx

# 8. Get SSL certificate for BOTH domains
sudo certbot --nginx -d thedailytolkien.com -d www.thedailytolkien.com

# Follow prompts:
# - Enter email address
# - Agree to terms
# - Choose whether to redirect HTTP to HTTPS (select Yes/2)
```

### Option 2: Certificate for Non-WWW Only (Simpler)

If you don't want to support the www subdomain:

```bash
# Just get certificate for the main domain
sudo certbot --nginx -d thedailytolkien.com
```

---

## DNS Configuration

Before running Certbot, ensure your DNS is configured correctly:

### For Option 1 (Both domains):

```
A Record:     thedailytolkien.com     →  98.86.217.231
A Record:     www.thedailytolkien.com →  98.86.217.231
```

Or use a CNAME:
```
A Record:     thedailytolkien.com     →  98.86.217.231
CNAME Record: www.thedailytolkien.com →  thedailytolkien.com
```

### For Option 2 (Non-WWW only):

```
A Record:     thedailytolkien.com     →  98.86.217.231
```

### Verify DNS:

```bash
# Check non-www
dig thedailytolkien.com +short
# Should show: 98.86.217.231

# Check www (if using Option 1)
dig www.thedailytolkien.com +short
# Should show: 98.86.217.231 or thedailytolkien.com
```

---

## What Was Changed

To support both domains, the following files were updated:

1. **deploy/nginx-server-blocks.conf**
   - HTTP server block: `server_name thedailytolkien.com www.thedailytolkien.com;`
   - HTTPS server block: `server_name thedailytolkien.com www.thedailytolkien.com;`

2. **deploy/nginx-snippet.conf**
   - Same updates for consistency

3. **config/environments/production.rb**
   - Added `"www.thedailytolkien.com"` to `config.hosts` array

---

## Complete Deployment Process

If you haven't deployed yet or need to redeploy:

```bash
# 1. SSH to server
ssh ubuntu@98.86.217.231

# 2. Pull changes
cd ~/thedailytolkien
git pull origin main

# 3. Clean up old nginx config
./deploy/cleanup-nginx-duplicates.sh

# 4. Deploy application (this will update nginx)
export RAILS_MASTER_KEY="your-master-key"
./deploy/deploy.sh

# 5. Get SSL certificates
sudo certbot --nginx -d thedailytolkien.com -d www.thedailytolkien.com

# 6. Verify deployment
curl -I https://thedailytolkien.com/up
curl -I https://www.thedailytolkien.com/up
```

---

## Troubleshooting

### Issue: DNS not resolving

**Check DNS:**
```bash
dig thedailytolkien.com +short
dig www.thedailytolkien.com +short
```

**Solution:** Update your DNS records at your domain registrar (GoDaddy, Namecheap, etc.)

### Issue: Certbot fails with "Connection refused"

**Cause:** Port 80 not open or nginx not running

**Solution:**
```bash
# Check nginx is running
sudo systemctl status nginx

# Check firewall
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Test port 80
curl -I http://thedailytolkien.com
```

### Issue: "Too many certificates already issued"

**Cause:** Let's Encrypt rate limit (5 certificates per week for same domain)

**Solution:** 
- Wait a week, or
- Use staging server to test: `sudo certbot --nginx --staging -d thedailytolkien.com -d www.thedailytolkien.com`
- Once working, get production cert

### Issue: Certificate obtained but site still shows "Not Secure"

**Check certificate:**
```bash
sudo certbot certificates
```

**Verify nginx is using the certificate:**
```bash
sudo grep -r "ssl_certificate" /etc/nginx/sites-enabled/
```

**Test SSL:**
```bash
openssl s_client -connect thedailytolkien.com:443 -servername thedailytolkien.com
```

**Solution:** Certbot should have automatically updated your nginx config. If not:
```bash
# Manually check the certificate paths in nginx config
sudo nano /etc/nginx/sites-available/service-integrator

# Look for:
ssl_certificate /etc/letsencrypt/live/thedailytolkien.com/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/thedailytolkien.com/privkey.pem;

# Test and reload
sudo nginx -t && sudo systemctl reload nginx
```

---

## Certificate Renewal

Certbot automatically sets up renewal. Verify:

```bash
# Check renewal configuration
sudo certbot renew --dry-run

# Check systemd timer
sudo systemctl status certbot.timer

# Manual renewal (if needed)
sudo certbot renew
```

---

## Verification Checklist

After obtaining certificates:

- [ ] Visit https://thedailytolkien.com - should show secure lock
- [ ] Visit https://www.thedailytolkien.com - should show secure lock
- [ ] Visit http://thedailytolkien.com - should redirect to https
- [ ] Visit http://www.thedailytolkien.com - should redirect to https
- [ ] Check health endpoint: `curl -f https://thedailytolkien.com/up`
- [ ] Check certificate: `sudo certbot certificates`
- [ ] Test password reset email flow
- [ ] Check application logs: `docker-compose -f docker-compose.prod.yml logs -f`

---

## Advanced: Redirect WWW to Non-WWW (Optional)

If you want www.thedailytolkien.com to always redirect to thedailytolkien.com:

Add this server block to your nginx config:

```nginx
# Redirect www to non-www
server {
    listen 443 ssl http2;
    server_name www.thedailytolkien.com;
    
    ssl_certificate /etc/letsencrypt/live/thedailytolkien.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/thedailytolkien.com/privkey.pem;
    
    return 301 https://thedailytolkien.com$request_uri;
}
```

Then change the main server block to only use non-www:
```nginx
server {
    listen 443 ssl http2;
    server_name thedailytolkien.com;  # Remove www here
    # ... rest of config
}
```

---

## Quick Command Reference

```bash
# Get certificate for both domains
sudo certbot --nginx -d thedailytolkien.com -d www.thedailytolkien.com

# Get certificate for non-www only
sudo certbot --nginx -d thedailytolkien.com

# List all certificates
sudo certbot certificates

# Test renewal
sudo certbot renew --dry-run

# Force renewal
sudo certbot renew --force-renewal

# Revoke certificate
sudo certbot revoke --cert-name thedailytolkien.com

# Delete certificate
sudo certbot delete --cert-name thedailytolkien.com
```

---

## Summary

**Problem:** Certbot couldn't find server block for www subdomain

**Solution:** Updated nginx configuration to support both `thedailytolkien.com` and `www.thedailytolkien.com`

**Next Steps:**
1. Pull latest code: `git pull origin main`
2. Deploy application: `./deploy/deploy.sh`
3. Get SSL certificate: `sudo certbot --nginx -d thedailytolkien.com -d www.thedailytolkien.com`
4. Verify both domains work with HTTPS

**Files Changed:**
- `deploy/nginx-server-blocks.conf`
- `deploy/nginx-snippet.conf`
- `config/environments/production.rb`
