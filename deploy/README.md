# Deploy Directory

This directory contains all the files needed for deploying The Daily Tolkien to production.

## Files Overview

### 📋 Documentation

-   **`DEPLOYMENT_PLAN.md`** - Comprehensive deployment guide with step-by-step instructions
-   **`README.md`** - This file, explaining the deploy directory contents

### 🚀 Deployment Scripts

-   **`deploy.sh`** - Main deployment script with backup, deployment, and verification
-   **`server-setup.sh`** - Initial server setup script for AWS Lightsail instance

### 🔧 Configuration Files

-   **`nginx.conf`** - Nginx reverse proxy configuration for production
-   **`../docker-compose.prod.yml`** - Production Docker Compose configuration
-   **`../.github/workflows/deploy.yml`** - GitHub Actions automated deployment workflow

## Quick Start

### 1. Server Setup (Run once)

```bash
# On your AWS Lightsail instance
curl -O https://raw.githubusercontent.com/[your-repo]/thedailytolkien/main/deploy/server-setup.sh
chmod +x server-setup.sh
./server-setup.sh
```

### 2. Configure GitHub Actions

Add these secrets to your GitHub repository:

-   `HOST`: 98.86.217.231
-   `USERNAME`: ubuntu
-   `SSH_PRIVATE_KEY`: Your SSH private key
-   `RAILS_MASTER_KEY`: Contents of config/master.key

### 3. Deploy

Push to main branch for automatic deployment, or run manually:

```bash
export RAILS_MASTER_KEY="your-key-here"
./deploy.sh
```

## Security Features

-   ✅ SSL/TLS encryption with Let's Encrypt
-   ✅ Security headers (HSTS, CSP, XSS Protection)
-   ✅ Rate limiting to prevent abuse
-   ✅ Firewall configuration with UFW
-   ✅ Fail2ban for SSH protection
-   ✅ Regular security updates

## Monitoring

### Health Checks

-   Application: https://thedailytolkien.com/up
-   Container: `docker-compose -f docker-compose.prod.yml ps`

### Logs

```bash
# Application logs
docker-compose -f docker-compose.prod.yml logs -f

# Nginx logs
sudo tail -f /var/log/nginx/thedailytolkien.*.log
```

## Support

For issues or questions:

1. Check the logs using commands above
2. Review DEPLOYMENT_PLAN.md for troubleshooting
3. Verify all secrets are correctly configured in GitHub
