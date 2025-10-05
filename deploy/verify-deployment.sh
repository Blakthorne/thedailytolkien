#!/bin/bash

# Quick deployment verification script for The Daily Tolkien
# Run this script to verify the deployment is working correctly

set -e

echo "🔍 The Daily Tolkien Deployment Verification"
echo "============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() {
    echo -e "${GREEN}✅ $1${NC}"
}

check_fail() {
    echo -e "${RED}❌ $1${NC}"
}

check_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo ""
echo "1. Checking Docker container status..."
if docker-compose -f docker-compose.prod.yml ps -q web | grep -q .; then
    check_pass "Docker container is running"
else
    check_fail "Docker container is not running"
    exit 1
fi

echo ""
echo "2. Checking environment variables..."
if docker-compose -f docker-compose.prod.yml exec -T web env | grep -q RAILS_MASTER_KEY; then
    check_pass "RAILS_MASTER_KEY is set in container"
else
    check_fail "RAILS_MASTER_KEY is missing in container"
fi

echo ""
echo "3. Checking application health..."
if docker-compose -f docker-compose.prod.yml exec -T web curl -f http://localhost/up > /dev/null 2>&1; then
    check_pass "Application health check passed"
else
    check_fail "Application health check failed"
fi

echo ""
echo "4. Checking Nginx configuration..."
if sudo nginx -t > /dev/null 2>&1; then
    check_pass "Nginx configuration is valid"
else
    check_fail "Nginx configuration has errors"
fi

echo ""
echo "5. Checking if site is enabled..."
if [ -L "/etc/nginx/sites-enabled/service-integrator" ]; then
    check_pass "Multi-app site is enabled"
else
    check_warn "Multi-app site symlink missing"
fi

echo ""
echo "6. Checking domain configuration..."
if sudo grep -q "thedailytolkien.com" /etc/nginx/sites-available/service-integrator 2>/dev/null; then
    check_pass "The Daily Tolkien domain found in Nginx config"
else
    check_warn "The Daily Tolkien domain not found in Nginx config"
fi

echo ""
echo "7. Testing external connectivity..."
if curl -f -s -I https://thedailytolkien.com/up > /dev/null 2>&1; then
    check_pass "External HTTPS connectivity working"
else
    check_warn "External HTTPS connectivity not working (DNS or SSL issue)"
fi

echo ""
echo "8. Checking SSL certificate..."
if echo | openssl s_client -connect thedailytolkien.com:443 -servername thedailytolkien.com 2>/dev/null | openssl x509 -noout -dates > /dev/null 2>&1; then
    check_pass "SSL certificate is valid"
else
    check_warn "SSL certificate issue"
fi

echo ""
echo "============================================="
echo "🎉 Verification complete!"
echo ""
echo "If you see any warnings or failures above, please check:"
echo "1. DNS is pointing to this server"
echo "2. SSL certificates are properly configured"
echo "3. Nginx configuration includes The Daily Tolkien"
echo "4. RAILS_MASTER_KEY is properly set"
echo ""
echo "Useful commands:"
echo "- View logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "- Check config: sudo nginx -t"
echo "- Restart app: docker-compose -f docker-compose.prod.yml restart"
