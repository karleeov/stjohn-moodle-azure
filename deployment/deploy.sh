#!/bin/bash

# Moodle Azure Deployment Script
# This script deploys Moodle to Azure App Service

set -e

# Configuration
RESOURCE_GROUP="rg-karlli-4586_ai"
APP_NAME="moodle-site-0530"
DB_SERVER="moodledb0530"
LOCATION="East US"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v az &> /dev/null; then
        error "Azure CLI is not installed. Please install it first."
    fi
    
    if ! az account show &> /dev/null; then
        error "Not logged into Azure. Please run 'az login' first."
    fi
    
    success "Prerequisites check passed"
}

# Check if resources exist
check_resources() {
    log "Checking Azure resources..."
    
    # Check resource group
    if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        error "Resource group $RESOURCE_GROUP does not exist"
    fi
    
    # Check app service
    if ! az webapp show --resource-group "$RESOURCE_GROUP" --name "$APP_NAME" &> /dev/null; then
        error "App Service $APP_NAME does not exist"
    fi
    
    # Check database
    if ! az mysql flexible-server show --resource-group "$RESOURCE_GROUP" --name "$DB_SERVER" &> /dev/null; then
        error "MySQL server $DB_SERVER does not exist"
    fi
    
    success "All resources exist"
}

# Deploy emergency fix first
deploy_emergency_fix() {
    log "Deploying emergency status page..."
    
    if [ -d "../emergency_fix" ]; then
        cd ../emergency_fix
        zip -r ../emergency_fix.zip . -x "*.git*" "*.DS_Store*"
        cd ../deployment
        
        az webapp deployment source config-zip \
            --resource-group "$RESOURCE_GROUP" \
            --name "$APP_NAME" \
            --src ../emergency_fix.zip
        
        success "Emergency fix deployed"
    else
        warning "Emergency fix directory not found, skipping..."
    fi
}

# Deploy main Moodle application
deploy_moodle() {
    log "Deploying main Moodle application..."
    
    if [ -d "../moodle_code" ]; then
        cd ../moodle_code
        
        # Remove any existing zip
        rm -f ../moodle_deployment.zip
        
        # Create deployment package
        log "Creating deployment package..."
        zip -r ../moodle_deployment.zip . -x "*.git*" "*.DS_Store*" "config.php"
        
        cd ../deployment
        
        # Deploy to Azure
        log "Uploading to Azure App Service..."
        az webapp deployment source config-zip \
            --resource-group "$RESOURCE_GROUP" \
            --name "$APP_NAME" \
            --src ../moodle_deployment.zip
        
        success "Moodle application deployed"
    else
        error "Moodle code directory not found"
    fi
}

# Configure app settings
configure_app_settings() {
    log "Configuring application settings..."
    
    # Set PHP version
    az webapp config set \
        --resource-group "$RESOURCE_GROUP" \
        --name "$APP_NAME" \
        --php-version "8.1"
    
    # Set default documents
    az webapp config set \
        --resource-group "$RESOURCE_GROUP" \
        --name "$APP_NAME" \
        --startup-file "index.php"
    
    # Configure app settings
    az webapp config appsettings set \
        --resource-group "$RESOURCE_GROUP" \
        --name "$APP_NAME" \
        --settings \
        MYSQL_HOST="$DB_SERVER.mysql.database.azure.com" \
        MYSQL_DATABASE="moodle" \
        MYSQL_USER="moodleadmin" \
        WEBSITE_DYNAMIC_CACHE=0 \
        WEBSITE_LOCAL_CACHE_OPTION=Never
    
    success "Application settings configured"
}

# Restart application
restart_app() {
    log "Restarting application..."
    
    az webapp restart \
        --resource-group "$RESOURCE_GROUP" \
        --name "$APP_NAME"
    
    success "Application restarted"
}

# Check deployment status
check_deployment() {
    log "Checking deployment status..."
    
    # Wait a moment for restart
    sleep 10
    
    # Check if site is responding
    SITE_URL="https://$APP_NAME.azurewebsites.net"
    
    if curl -s -o /dev/null -w "%{http_code}" "$SITE_URL" | grep -q "200\|302"; then
        success "Site is responding: $SITE_URL"
    else
        warning "Site may not be fully ready yet. Check: $SITE_URL"
    fi
    
    # Show deployment list
    az webapp deployment list \
        --resource-group "$RESOURCE_GROUP" \
        --name "$APP_NAME" \
        --output table
}

# Main deployment function
main() {
    log "Starting Moodle deployment to Azure..."
    
    check_prerequisites
    check_resources
    deploy_emergency_fix
    configure_app_settings
    deploy_moodle
    restart_app
    check_deployment
    
    success "Deployment completed successfully!"
    log "Site URL: https://$APP_NAME.azurewebsites.net"
    log "Check deployment status with: az webapp deployment list --resource-group $RESOURCE_GROUP --name $APP_NAME --output table"
}

# Run main function
main "$@"
