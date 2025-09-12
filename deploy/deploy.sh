#!/bin/bash

# Deploy script for The Daily Tolkien
# This script handles the deployment of the Rails application using Docker

set -e

echo "🚀 Starting deployment of The Daily Tolkien..."

# Configuration
APP_NAME="thedailytolkien"
COMPOSE_FILE="docker-compose.prod.yml"
BACKUP_DIR="/home/$(whoami)/backups/$(date +%Y-%m-%d_%H-%M-%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Function to check if required environment variables are set
check_env_vars() {
    log_info "Checking environment variables..."
    
    if [ -z "$RAILS_MASTER_KEY" ]; then
        log_error "RAILS_MASTER_KEY environment variable is not set!"
        exit 1
    fi
    
    log_info "Environment variables check passed ✅"
}

# Function to create backup
create_backup() {
    log_info "Creating backup..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup database if container is running
    if docker-compose -f "$COMPOSE_FILE" ps -q web | grep -q .; then
        log_info "Backing up database..."
        docker-compose -f "$COMPOSE_FILE" exec -T web ./bin/rails db:dump > "$BACKUP_DIR/database.sql" 2>/dev/null || log_warn "Database backup failed (this is normal on first deployment)"
    fi
    
    # Backup storage volume
    if docker volume ls | grep -q "${APP_NAME}_rails_storage"; then
        log_info "Backing up storage volume..."
        docker run --rm -v "${APP_NAME}_rails_storage":/source -v "$BACKUP_DIR":/backup alpine tar czf /backup/storage.tar.gz -C /source . || log_warn "Storage backup failed"
    fi
    
    log_info "Backup created at: $BACKUP_DIR"
}

# Function to deploy the application
deploy_app() {
    log_info "Deploying application..."
    
    # Stop existing containers
    log_info "Stopping existing containers..."
    docker-compose -f "$COMPOSE_FILE" down --remove-orphans || true
    
    # Remove old images (keep the latest for rollback)
    log_info "Cleaning up old Docker images..."
    docker image prune -f || true
    
    # Start the new deployment
    log_info "Starting new deployment..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Wait for application to be ready
    log_info "Waiting for application to be ready..."
    timeout=60
    count=0
    while [ $count -lt $timeout ]; do
        if docker-compose -f "$COMPOSE_FILE" exec -T web curl -f http://localhost/up > /dev/null 2>&1; then
            log_info "Application is ready! ✅"
            break
        fi
        count=$((count + 1))
        if [ $count -eq $timeout ]; then
            log_error "Application failed to start within $timeout seconds"
            exit 1
        fi
        sleep 1
    done
}

# Function to run database migrations
run_migrations() {
    log_info "Running database migrations..."
    docker-compose -f "$COMPOSE_FILE" exec -T web ./bin/rails db:create db:migrate || {
        log_error "Database migrations failed!"
        exit 1
    }
    log_info "Database migrations completed ✅"
}

# Function to verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check if container is running
    if ! docker-compose -f "$COMPOSE_FILE" ps -q web | grep -q .; then
        log_error "Application container is not running!"
        exit 1
    fi
    
    # Check health endpoint
    if ! docker-compose -f "$COMPOSE_FILE" exec -T web curl -f http://localhost/up > /dev/null 2>&1; then
        log_error "Application health check failed!"
        exit 1
    fi
    
    log_info "Deployment verification passed ✅"
}

# Function to show status
show_status() {
    log_info "Deployment Status:"
    docker-compose -f "$COMPOSE_FILE" ps
    
    log_info "Application URL: https://thedailytolkien.davidpolar.com"
}

# Main execution
main() {
    log_info "=== The Daily Tolkien Deployment ==="
    
    check_env_vars
    create_backup
    deploy_app
    run_migrations
    verify_deployment
    show_status
    
    log_info "🎉 Deployment completed successfully!"
}

# Execute main function
main "$@"
