#!/bin/bash

# Script to remove old The Daily Tolkien nginx configuration
# This handles removing the old domain configuration safely

set -e

NGINX_CONFIG="$1"

if [ -z "$NGINX_CONFIG" ] || [ ! -f "$NGINX_CONFIG" ]; then
    echo "Usage: $0 <nginx-config-file>"
    exit 1
fi

echo "Removing old The Daily Tolkien configuration from $NGINX_CONFIG..."

# Create a temporary file
TEMP_FILE=$(mktemp)

# Use awk to remove The Daily Tolkien blocks
awk '
    # Flag to track if we are inside a Daily Tolkien block
    /# The Daily Tolkien Configuration/ {
        in_tolkien = 1
        next
    }
    
    # If we hit another comment header (new section), stop skipping
    /^# [A-Z]/ && in_tolkien {
        in_tolkien = 0
    }
    
    # Skip lines while inside Daily Tolkien block
    in_tolkien {
        next
    }
    
    # Check for upstream block specific to thedailytolkien
    /^upstream thedailytolkien_backend/ {
        in_upstream = 1
        next
    }
    
    # End of upstream block
    in_upstream && /^}/ {
        in_upstream = 0
        next
    }
    
    # Skip lines in upstream block
    in_upstream {
        next
    }
    
    # Check for server blocks with old domain
    /server_name (thedailytolkien\.davidpolar\.com|thedailytolkien\.com)/ {
        # Go back and remove the "server {" line if it was just printed
        if (prev_line ~ /^server \{/) {
            # Mark to skip this server block
            in_server = 1
            lines_to_remove = NR - 1
            next
        }
        in_server = 1
        next
    }
    
    # Track server block depth
    /^server \{/ && !in_server {
        server_depth = 0
        prev_line = $0
    }
    
    /\{/ && in_server {
        server_depth++
    }
    
    /\}/ && in_server {
        server_depth--
        if (server_depth <= 0) {
            in_server = 0
            next
        }
        next
    }
    
    # Skip lines in server block
    in_server {
        next
    }
    
    # Print all other lines
    !in_tolkien && !in_upstream && !in_server {
        print
        prev_line = $0
    }
' "$NGINX_CONFIG" > "$TEMP_FILE"

# Replace original file with cleaned version
sudo mv "$TEMP_FILE" "$NGINX_CONFIG"

echo "Old configuration removed successfully"
