#!/bin/bash

# Manual cleanup script for The Daily Tolkien nginx configuration
# Run this on your server to remove duplicate configurations before redeploying

set -e

echo "🧹 The Daily Tolkien - Nginx Configuration Cleanup"
echo "=================================================="

NGINX_CONFIG="/etc/nginx/sites-available/service-integrator"

if [ ! -f "$NGINX_CONFIG" ]; then
    echo "ERROR: Configuration file not found: $NGINX_CONFIG"
    exit 1
fi

# Backup the current configuration
BACKUP_FILE="${NGINX_CONFIG}.backup-before-cleanup-$(date +%Y%m%d_%H%M%S)"
echo "📦 Creating backup: $BACKUP_FILE"
sudo cp "$NGINX_CONFIG" "$BACKUP_FILE"

echo "🔍 Checking for old configurations..."

# Check what we're dealing with
if sudo grep -q "thedailytolkien.davidpolar.com" "$NGINX_CONFIG"; then
    echo "✅ Found old domain (thedailytolkien.davidpolar.com) configuration"
fi

if sudo grep -q "server_name thedailytolkien.com" "$NGINX_CONFIG"; then
    echo "✅ Found new domain (thedailytolkien.com) configuration"
fi

# Count how many times the upstream appears
UPSTREAM_COUNT=$(sudo grep -c "upstream thedailytolkien_backend" "$NGINX_CONFIG" || echo "0")
echo "📊 Found $UPSTREAM_COUNT upstream thedailytolkien_backend blocks"

if [ "$UPSTREAM_COUNT" -gt 1 ]; then
    echo "⚠️  WARNING: Multiple upstream blocks detected! This will cause errors."
fi

echo ""
echo "🔧 Removing ALL The Daily Tolkien configurations..."
echo "   (We'll let the deployment script add the correct one)"

# Create a Python script to do the cleanup properly
sudo python3 <<'PYTHON_SCRIPT'
import re

config_file = "/etc/nginx/sites-available/service-integrator"

with open(config_file, 'r') as f:
    content = f.read()

# Remove upstream thedailytolkien_backend blocks
content = re.sub(
    r'upstream\s+thedailytolkien_backend\s*\{[^}]*\}',
    '',
    content,
    flags=re.DOTALL
)

# Remove server blocks with thedailytolkien.com or thedailytolkien.davidpolar.com
# This handles nested braces properly
def remove_server_blocks(text):
    lines = text.split('\n')
    result = []
    skip_until_brace_count = None
    brace_count = 0
    
    for line in lines:
        # Check if this line starts a server block for our domains
        if 'server_name' in line and ('thedailytolkien.com' in line or 'thedailytolkien.davidpolar.com' in line):
            # Find the opening server { brace
            # Go backwards to find it
            for i in range(len(result) - 1, -1, -1):
                if 'server' in result[i] and '{' in result[i]:
                    # Remove lines back to the server { line
                    result = result[:i]
                    skip_until_brace_count = 1
                    break
            continue
        
        if skip_until_brace_count is not None:
            # Count braces to know when the server block ends
            brace_count += line.count('{')
            brace_count -= line.count('}')
            
            if brace_count <= 0:
                skip_until_brace_count = None
                brace_count = 0
            continue
        
        result.append(line)
    
    return '\n'.join(result)

content = remove_server_blocks(content)

# Remove any comment lines for The Daily Tolkien
content = re.sub(r'# The Daily Tolkien.*\n', '', content)

# Remove excessive blank lines (more than 2 consecutive)
content = re.sub(r'\n{3,}', '\n\n', content)

# Write back
with open(config_file, 'w') as f:
    f.write(content)

print("✅ Cleanup completed")
PYTHON_SCRIPT

echo ""
echo "🧪 Testing nginx configuration..."
if sudo nginx -t; then
    echo "✅ Nginx configuration is valid!"
    echo ""
    echo "📝 Summary:"
    echo "   - Backup created: $BACKUP_FILE"
    echo "   - All The Daily Tolkien configurations removed"
    echo "   - Nginx configuration is valid"
    echo ""
    echo "🚀 Next steps:"
    echo "   1. Redeploy the application using your deployment script"
    echo "   2. The deployment will add the correct configuration for thedailytolkien.com"
    echo ""
    echo "   Or reload nginx now: sudo systemctl reload nginx"
else
    echo "❌ Nginx configuration test failed!"
    echo ""
    echo "⚠️  Restoring from backup..."
    sudo cp "$BACKUP_FILE" "$NGINX_CONFIG"
    echo "✅ Configuration restored from backup"
    echo ""
    echo "Please review the configuration manually or contact support."
    exit 1
fi
