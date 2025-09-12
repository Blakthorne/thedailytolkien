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
-   Port mapping: Container 80 → Host 3000
-   Persistent volumes for database, storage, and logs

### Nginx Configuration

-   **Reverse proxy** from port 443 (HTTPS) to port 3000 (app)
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

Since you mentioned another app runs on the same server, here's how to configure multiple apps:

### Example Nginx Configuration for Multiple Apps

```nginx
# /etc/nginx/sites-available/multiple-apps.conf

# App 1: The Daily Tolkien
upstream thedailytolkien_backend {
    server 127.0.0.1:3000;
}

# App 2: Another Application (example)
upstream otherapp_backend {
    server 127.0.0.1:3001;
}

# The Daily Tolkien configuration (existing)
server {
    listen 443 ssl http2;
    server_name thedailytolkien.davidpolar.com;
    # ... (rest of configuration from deploy/nginx.conf)
}

# Another App configuration
server {
    listen 443 ssl http2;
    server_name anotherapp.davidpolar.com;

    ssl_certificate /etc/letsencrypt/live/anotherapp.davidpolar.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/anotherapp.davidpolar.com/privkey.pem;

    location / {
        proxy_pass http://otherapp_backend;
        # ... (similar proxy settings)
    }
}
```

## Phase 6: Monitoring and Maintenance

### Log Monitoring

```bash
# Application logs
docker-compose -f ~/thedailytolkien/docker-compose.prod.yml logs -f

# Nginx logs
sudo tail -f /var/log/nginx/thedailytolkien.access.log
sudo tail -f /var/log/nginx/thedailytolkien.error.log

# System logs
journalctl -u docker -f
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

## Troubleshooting

### Common Issues

1. **Port conflicts:** Ensure port 3000 is available for the application
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
curl -f http://localhost:3000/up
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
