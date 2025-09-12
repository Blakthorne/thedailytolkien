#!/bin/bash

# Server Setup Script for The Daily Tolkien Deployment
# Run this script on your AWS Lightsail instance to prepare for deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Function to clean up problematic repositories
cleanup_repositories() {
    log_step "Cleaning up problematic repositories..."
    
    # Remove problematic Certbot PPA if it exists
    if [[ -f /etc/apt/sources.list.d/certbot-ubuntu-certbot-*.list ]]; then
        log_info "Removing problematic Certbot PPA..."
        sudo rm -f /etc/apt/sources.list.d/certbot-ubuntu-certbot-*.list
    fi
    
    # Remove any other problematic PPAs that might exist
    sudo find /etc/apt/sources.list.d/ -name "*certbot*" -delete 2>/dev/null || true
    
    # Clean up GPG keys for removed repositories
    sudo apt-key del 2048R/A2C794A6 2>/dev/null || true
    
    # Update package lists after cleanup
    sudo apt update || {
        log_warn "Initial apt update failed, attempting to fix..."
        sudo apt --fix-broken install -y
        sudo dpkg --configure -a
        sudo apt update
    }
    
    log_info "Repository cleanup completed ✅"
}

# Function to update system packages
update_system() {
    log_step "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    log_info "System packages updated ✅"
}

# Function to install Docker
install_docker() {
    log_step "Installing Docker..."
    
    # Remove any old Docker installations
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Install dependencies
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Create keyrings directory if it doesn't exist
    sudo mkdir -p /usr/share/keyrings
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Set up the stable repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package lists and install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    log_info "Docker installed ✅"
    log_warn "Please log out and back in for Docker group changes to take effect"
}

# Function to install Docker Compose
install_docker_compose() {
    log_step "Installing Docker Compose..."
    
    # Install Docker Compose v2 (comes with docker-compose-plugin above)
    # Create symlink for backward compatibility
    sudo ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
    
    log_info "Docker Compose installed ✅"
}

# Function to install Nginx
install_nginx() {
    log_step "Installing Nginx..."
    
    sudo apt install -y nginx
    
    # Enable and start Nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
    
    # Configure firewall for Nginx
    sudo ufw allow 'Nginx Full'
    
    log_info "Nginx installed and configured ✅"
}

# Function to install Certbot for SSL certificates
install_certbot() {
    log_step "Installing Certbot for SSL certificates..."
    
    # Use official Ubuntu packages instead of PPAs for better compatibility
    sudo apt install -y certbot python3-certbot-nginx
    
    # Verify Certbot installation
    if command -v certbot &> /dev/null; then
        log_info "Certbot installed successfully (version: $(certbot --version 2>&1 | head -n1))"
    else
        log_error "Certbot installation failed"
        exit 1
    fi
    
    log_info "Certbot installed ✅"
}

# Function to configure firewall
configure_firewall() {
    log_step "Configuring UFW firewall..."
    
    # Enable UFW if not already enabled
    sudo ufw --force enable
    
    # Allow SSH (port 22)
    sudo ufw allow ssh
    
    # Allow HTTP and HTTPS
    sudo ufw allow 'Nginx Full'
    
    # Allow Docker port for application (internal only)
    sudo ufw allow from 127.0.0.1 to any port 3001
    
    # Show status
    sudo ufw status
    
    log_info "Firewall configured ✅"
}

# Function to create application directories
create_app_directories() {
    log_step "Creating application directories..."
    
    mkdir -p ~/thedailytolkien
    mkdir -p ~/backups
    
    log_info "Application directories created ✅"
}

# Function to configure Git (for GitHub Actions deployment)
configure_git() {
    log_step "Configuring Git..."
    
    if ! command -v git &> /dev/null; then
        sudo apt install -y git
    fi
    
    log_info "Git configured ✅"
}

# Function to install additional utilities
install_utilities() {
    log_step "Installing additional utilities..."
    
    sudo apt install -y curl wget unzip htop fail2ban
    
    # Configure fail2ban for SSH protection
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
    
    log_info "Additional utilities installed ✅"
}

# Function to setup SSH key for GitHub Actions
setup_ssh_info() {
    log_step "SSH Key Setup Information"
    
    echo ""
    log_info "To complete the GitHub Actions setup, you need to:"
    echo "1. Generate an SSH key pair if you haven't already:"
    echo "   ssh-keygen -t rsa -b 4096 -C 'github-actions@thedailytolkien'"
    echo ""
    echo "2. Add the public key to your server's ~/.ssh/authorized_keys"
    echo ""
    echo "3. Add the following secrets to your GitHub repository settings:"
    echo "   - HOST: 98.86.217.231"
    echo "   - USERNAME: $(whoami)"
    echo "   - SSH_PRIVATE_KEY: (content of your private key)"
    echo "   - RAILS_MASTER_KEY: (content of config/master.key)"
    echo ""
    log_info "Current user: $(whoami)"
    log_info "SSH directory: ~/.ssh/"
}

# Function to display next steps
show_next_steps() {
    log_step "Next Steps"
    
    echo ""
    log_info "Server setup completed! Next steps:"
    echo ""
    echo "1. 🔐 Set up SSL certificates:"
    echo "   sudo certbot --nginx -d thedailytolkien.davidpolar.com"
    echo ""
    echo "2. 🔑 Configure GitHub Actions secrets in your repository:"
    echo "   - HOST: 98.86.217.231"
    echo "   - USERNAME: $(whoami)"
    echo "   - SSH_PRIVATE_KEY: (your private SSH key)"
    echo "   - RAILS_MASTER_KEY: (from config/master.key)"
    echo ""
    echo "3. 🌐 Update your domain DNS to point to this server:"
    echo "   A record: thedailytolkien.davidpolar.com -> 98.86.217.231"
    echo ""
    echo "4. 🚀 Deploy by pushing to main branch or running GitHub Actions manually"
    echo ""
    echo "5. 🔍 Monitor logs:"
    echo "   - Application: docker-compose -f ~/thedailytolkien/docker-compose.prod.yml logs -f"
    echo "   - Nginx: sudo tail -f /var/log/nginx/thedailytolkien.*.log"
    echo ""
    log_warn "Remember to log out and back in for Docker group changes to take effect!"
}

# Main execution
main() {
    log_info "=== The Daily Tolkien Server Setup ==="
    echo "This script will prepare your AWS Lightsail instance for deployment."
    echo ""
    
    check_root
    cleanup_repositories
    update_system
    install_docker
    install_docker_compose
    install_nginx
    install_certbot
    configure_firewall
    create_app_directories
    configure_git
    install_utilities
    setup_ssh_info
    show_next_steps
    
    log_info "🎉 Server setup completed successfully!"
}

# Execute main function
main "$@"
