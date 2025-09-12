# The Daily Tolkien - Production Deployment Plan

## Overview

This deployment plan outlines the complete setup for deploying The Daily Tolkien Rails application to AWS Lightsail using Docker containers with Nginx reverse proxy and automated deployment via GitHub Actions.

**Deployment Details:**

-   **Domain:** thedailytolkien.davidpolar.com
-   **Server IP:** 98.86.217.231
-   **Platform:** AWS Lightsail Instance
-   **Container:** Docker with Rails 8.0.2.1
-   **Proxy:** Nginx with SSL/TLS termination
-   **CI/CD:** GitHub Actions

## Prerequisites

### Server Requirements

-   AWS Lightsail instance (minimum 1GB RAM, 1 vCPU)
-   Ubuntu 20.04 or later
-   Static IP address assigned
-   Domain DNS configured to point to server IP

### Local Requirements

-   Repository access with push permissions
-   SSH key pair for server access
-   Rails master key from `config/master.key`

## Phase 1: Initial Server Setup

### Step 1: Connect to Server

```bash
ssh ubuntu@98.86.217.231
```

### Step 2: Run Server Setup Script

```bash
# Download and run the server setup script
curl -O https://raw.githubusercontent.com/[your-username]/thedailytolkien/main/deploy/server-setup.sh
chmod +x server-setup.sh
./server-setup.sh
```

**What this script does:**

-   Updates system packages
-   Installs Docker and Docker Compose
-   Installs and configures Nginx
-   Installs Certbot for SSL certificates
-   Configures UFW firewall
-   Creates application directories
-   Installs security tools (fail2ban)

### Step 3: Configure DNS

Ensure your domain DNS is configured:

```
A Record: thedailytolkien.davidpolar.com → 98.86.217.231
```

### Step 4: Set Up SSL Certificates

```bash
sudo certbot --nginx -d thedailytolkien.davidpolar.com
```

## Phase 2: GitHub Actions Setup

### Step 1: Generate SSH Key for Deployment

```bash
# On your server
ssh-keygen -t rsa -b 4096 -C "github-actions@thedailytolkien"
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
cat ~/.ssh/id_rsa  # Copy this private key for GitHub secrets
```

### Step 2: Configure GitHub Repository Secrets

In your GitHub repository settings → Secrets and variables → Actions, add:

| Secret Name        | Value                                     |
| ------------------ | ----------------------------------------- |
| `HOST`             | `98.86.217.231`                           |
| `USERNAME`         | `ubuntu` (or your server username)        |
| `SSH_PRIVATE_KEY`  | Contents of `~/.ssh/id_rsa` (private key) |
| `RAILS_MASTER_KEY` | Contents of `config/master.key`           |

### Step 3: Verify GitHub Actions Workflow

The workflow is configured in `.github/workflows/deploy.yml` and will:

1. Run tests and security scans
2. Build Docker image
3. Deploy to server
4. Update Nginx configuration
5. Verify deployment

## Phase 3: Application Configuration

### Docker Configuration

The application uses:

-   **docker-compose.prod.yml** for production orchestration
-   **Dockerfile** optimized for production
-   Port mapping: Container 80 → Host 3001
-   Persistent volumes for database, storage, and logs

### Nginx Configuration

-   **Reverse proxy** from port 443 (HTTPS) to port 3001 (app)
-   **SSL termination** with Let's Encrypt certificates
-   **Security headers** and rate limiting
-   **Gzip compression** for static assets
-   **Health check bypass** for monitoring

### Rails Configuration

-   **Production environment** configured for domain
-   **SSL forced** with HSTS headers
-   **Host authorization** for domain and IP
-   **Asset serving** through Rails (proxied by Nginx)

## Phase 4: Deployment Process

### Automatic Deployment

1. Push code to `main` branch
2. GitHub Actions automatically triggers
3. Tests run and verify code quality
4. Docker image builds and deploys
5. Application starts with zero-downtime deployment

### Manual Deployment

```bash
# SSH to server
ssh ubuntu@98.86.217.231

# Navigate to application directory
cd ~/thedailytolkien

# Run manual deployment
export RAILS_MASTER_KEY="your-master-key-here"
./deploy/deploy.sh
```

## Phase 5: Multi-App Nginx Configuration

**IMPORTANT:** This deployment is designed to work with existing multi-app server setups. The deployment script will NOT overwrite your existing Nginx configuration.

### Current Multi-App Setup

Your server uses:
- **Main Nginx config file:** `/etc/nginx/sites-available/service-integrator`
- **Enabled sites:** `/etc/nginx/sites-enabled/service-integrator` (symlinked)

### How The Daily Tolkien Integrates

The deployment script will:
1. **Check** if your multi-app config exists at `/etc/nginx/sites-available/service-integrator`
2. **Backup** your current configuration before making changes
3. **Append** The Daily Tolkien configuration to your existing config (if not already present)
4. **Test** and **reload** Nginx safely

### Manual Nginx Configuration (if needed)

If you need to manually add The Daily Tolkien to your multi-app configuration:

```bash
# 1. Backup your current config
sudo cp /etc/nginx/sites-available/service-integrator /etc/nginx/sites-available/service-integrator.backup

# 2. Add The Daily Tolkien configuration
sudo cat ~/thedailytolkien/deploy/nginx-snippet.conf >> /etc/nginx/sites-available/service-integrator

# 3. Test and reload
sudo nginx -t && sudo systemctl reload nginx
```

### Nginx Configuration Details

The Daily Tolkien uses:
- **Upstream backend:** `127.0.0.1:3001` (Docker container)
- **Domain:** `thedailytolkien.davidpolar.com`
- **SSL certificates:** `/etc/letsencrypt/live/thedailytolkien.davidpolar.com/`
- **Rate limiting:** 10 requests/second with burst of 20

This configuration is designed to coexist with your other applications without conflicts.

## Phase 6: Environment Variable Management

### RAILS_MASTER_KEY Setup

The deployment now properly handles the Rails master key:

1. **GitHub Actions** passes the key via secrets
2. **Deployment script** creates a `.env` file for Docker Compose
3. **Docker container** receives the environment variable correctly

### Verifying Environment Variables

```bash
# Check if RAILS_MASTER_KEY is set in the container
docker-compose -f ~/thedailytolkien/docker-compose.prod.yml exec web env | grep RAILS_MASTER_KEY

# Check Docker Compose environment file
cat ~/thedailytolkien/.env
```

## Phase 7: Troubleshooting Deployment Issues

## Phase 8: Monitoring and Maintenance

### Log Monitoring

```bash
# Application logs
docker-compose -f ~/thedailytolkien/docker-compose.prod.yml logs -f

# Nginx logs
sudo tail -f /var/log/nginx/thedailytolkien.access.log
sudo tail -f /var/log/nginx/thedailytolkien.error.log

# System logs
journalctl -u docker -f

# Check environment variables in container
docker-compose -f ~/thedailytolkien/docker-compose.prod.yml exec web env | grep RAILS_MASTER_KEY
```

### Health Checks

-   **Application health:** https://thedailytolkien.davidpolar.com/up
-   **Docker container status:** `docker-compose ps`
-   **Nginx status:** `sudo systemctl status nginx`

### Backup Strategy

The deployment script automatically creates backups:

-   **Database backups:** Daily SQL dumps
-   **Storage backups:** Compressed volume backups
-   **Location:** `~/backups/YYYY-MM-DD_HH-MM-SS/`

### SSL Certificate Renewal

Certbot automatically renews certificates. Verify with:

```bash
sudo certbot renew --dry-run
```

### Security Updates

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Docker images
cd ~/thedailytolkien
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

## Troubleshooting Legacy Issues

### Common Issues

## Phase 7: Troubleshooting Deployment Issues

### Common Issues and Solutions

#### 1. "Welcome to nginx!" Default Page

**Symptoms:** Browser shows default Nginx page instead of The Daily Tolkien
**Cause:** Nginx configuration not properly applied or site not enabled

**Solution:**
```bash
# Check if The Daily Tolkien config is in the multi-app config
sudo grep -n "thedailytolkien.davidpolar.com" /etc/nginx/sites-available/service-integrator

# Test Nginx configuration
sudo nginx -t

# Reload Nginx if test passes
sudo systemctl reload nginx

# Check if site is enabled
ls -la /etc/nginx/sites-enabled/

# If needed, enable the site manually
sudo ln -sf /etc/nginx/sites-available/service-integrator /etc/nginx/sites-enabled/
```

#### 2. RAILS_MASTER_KEY Warning in Logs

**Symptoms:** Docker logs show "WARN[0000] The 'RAILS_MASTER_KEY' variable is not set"
**Cause:** Environment variable not properly passed to Docker container

**Solution:**
```bash
# Check if .env file exists and contains the key
cat ~/thedailytolkien/.env

# If missing, create it manually
echo "RAILS_MASTER_KEY=your_actual_master_key_here" > ~/thedailytolkien/.env

# Restart the container
cd ~/thedailytolkien
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d

# Verify the key is now available in the container
docker-compose -f docker-compose.prod.yml exec web env | grep RAILS_MASTER_KEY
```

#### 3. Container Not Starting

**Symptoms:** Docker container fails to start or health checks fail
**Cause:** Various issues including environment, ports, or application errors

**Solution:**
```bash
# Check container status
docker-compose -f ~/thedailytolkien/docker-compose.prod.yml ps

# View container logs
docker-compose -f ~/thedailytolkien/docker-compose.prod.yml logs web

# Check if port 3001 is in use
sudo netstat -tlnp | grep :3001

# Restart containers
docker-compose -f ~/thedailytolkien/docker-compose.prod.yml restart
```

#### 4. SSL Certificate Issues

**Symptoms:** HTTPS not working or certificate warnings
**Cause:** SSL certificates not properly configured for the domain

**Solution:**
```bash
# Check certificate status
sudo certbot certificates

# Renew certificate if needed
sudo certbot renew --dry-run

# If certificate doesn't exist, create it
sudo certbot --nginx -d thedailytolkien.davidpolar.com
```

## Phase 8: Monitoring and Maintenance

### Common Issues

1. **Port conflicts:** Ensure port 3001 is available for the application
2. **SSL issues:** Verify domain points to server and certificates are valid
3. **Docker permissions:** Ensure user is in docker group
4. **Firewall issues:** Check UFW rules allow necessary ports

### Debug Commands

```bash
# Check container status
docker-compose -f docker-compose.prod.yml ps

# View container logs
docker-compose -f docker-compose.prod.yml logs web

# Test Nginx configuration
sudo nginx -t

# Check SSL certificate
openssl s_client -connect thedailytolkien.davidpolar.com:443

# Test internal connectivity
curl -f http://localhost:3001/up
```

## Security Considerations

1. **Firewall:** UFW configured to only allow necessary ports
2. **SSL/TLS:** Strong cipher suites and HSTS headers
3. **Rate limiting:** Nginx configured with rate limiting
4. **Security headers:** CSP, XSS protection, frame options
5. **Fail2ban:** SSH brute force protection
6. **Regular updates:** Automated security updates enabled

## Post-Deployment Checklist

-   [ ] Server setup script executed successfully
-   [ ] DNS pointing to server IP
-   [ ] SSL certificates installed and working
-   [ ] GitHub Actions secrets configured
-   [ ] First deployment completed successfully
-   [ ] Health check endpoint responding
-   [ ] Logs are accessible and monitoring
-   [ ] Backup strategy verified
-   [ ] Security settings reviewed

## Support and Rollback

### Rollback Procedure

If deployment fails, rollback using:

```bash
cd ~/thedailytolkien
# Restore from latest backup
docker-compose -f docker-compose.prod.yml down
# Restore database and restart with previous image
```

### Getting Help

-   Check application logs for errors
-   Review Nginx error logs
-   Verify GitHub Actions workflow logs
-   Test connectivity with curl commands

---

**Deployment Status:** Ready for production deployment
**Last Updated:** September 12, 2025
