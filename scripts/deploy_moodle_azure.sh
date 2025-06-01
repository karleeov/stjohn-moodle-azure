#!/bin/bash
# deploy_moodle_azure.sh - Complete Moodle deployment script for Azure
# Created: May 30, 2025

set -e  # Exit immediately if a command fails
trap 'echo "An error occurred. Exiting..."; exit 1' ERR

# Configuration Variables - CUSTOMIZE THESE
RESOURCE_GROUP="rg-karlli-4586_ai"
LOCATION="eastus2"
STORAGE_ACCOUNT="moodlestore05301440"  # Use existing storage account
CONTAINER_NAME="moodlebackup"
MYSQL_SERVER_NAME="moodledb0530"  # Use existing MySQL server
MYSQL_ADMIN_USER="moodleadmin"
# MYSQL_ADMIN_PASSWORD will be prompted for security
MYSQL_DB_NAME="moodledb"
APP_SERVICE_PLAN="MoodlePlan"
WEB_APP_NAME="moodle-site-$(date +%m%d)"  # Creates unique name using month/day

# Local Moodle paths
LOCAL_MOODLE_DIR="/Users/karlli/moodle-dev/moodle_azure_migration/moodle_code"
LOCAL_MOODLEDATA_DIR="/Users/karlli/moodle-dev/moodle_azure_migration/moodledata"
LOCAL_DB_FILE="/Users/karlli/moodle-dev/moodle_azure_migration/moodle_database.sql"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display step information
display_step() {
    echo -e "\n${BLUE}====== STEP $1: $2 ======${NC}"
}

# Function to display success message
display_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to display error message
display_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
}

# Function to display warning message
display_warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
display_step "0" "Checking prerequisites"

if ! command_exists az; then
    display_error "Azure CLI not found. Please install it first."
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

if ! command_exists mysql; then
    display_warning "MySQL client not found. You'll need it to import your database."
    echo "For Mac, install with: brew install mysql-client"
fi

# Check Azure login status
display_step "1" "Verifying Azure login"
az account show --output none || {
    display_warning "Not logged in to Azure. Please login."
    az login
}
display_success "Logged in to Azure"

# Verify Resource Group exists
display_step "1a" "Verifying Resource Group"
echo "Using existing resource group: $RESOURCE_GROUP in $LOCATION"
if az group show --name "$RESOURCE_GROUP" --output none 2>/dev/null; then
    display_success "Resource group verified"
else
    display_error "Resource group $RESOURCE_GROUP not found"
    exit 1
fi

# Validate local files exist
display_step "1b" "Validating Local Files"
if [ ! -d "$LOCAL_MOODLE_DIR" ]; then
    display_error "Moodle code directory not found at $LOCAL_MOODLE_DIR"
    exit 1
fi

if [ ! -d "$LOCAL_MOODLEDATA_DIR" ]; then
    display_error "Moodledata directory not found at $LOCAL_MOODLEDATA_DIR"
    exit 1
fi

if [ ! -f "$LOCAL_DB_FILE" ]; then
    display_error "Database file not found at $LOCAL_DB_FILE"
    exit 1
fi
display_success "All local files validated"

# Prompt for MySQL password
echo ""
echo "Please enter a strong password for MySQL admin user (minimum 8 characters, include uppercase, lowercase, numbers, and special characters):"
read -s MYSQL_ADMIN_PASSWORD
echo ""
if [ ${#MYSQL_ADMIN_PASSWORD} -lt 8 ]; then
    display_error "Password must be at least 8 characters long"
    exit 1
fi
display_success "MySQL password set"

# Create Storage Account
display_step "1c" "Creating Storage Account"
echo "Checking storage account: $STORAGE_ACCOUNT"
if az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --output none 2>/dev/null; then
    display_success "Storage account already exists"
else
    echo "Creating storage account: $STORAGE_ACCOUNT"
    az storage account create \
        --name $STORAGE_ACCOUNT \
        --resource-group $RESOURCE_GROUP \
        --location $LOCATION \
        --sku Standard_LRS \
        --kind StorageV2
    display_success "Storage account created"
fi

# Create MySQL Server
display_step "2" "Creating Azure MySQL Server"
echo "Checking MySQL server: $MYSQL_SERVER_NAME"
if az mysql flexible-server show --name $MYSQL_SERVER_NAME --resource-group $RESOURCE_GROUP --output none 2>/dev/null; then
    display_success "MySQL server already exists"
else
    echo "Creating MySQL server: $MYSQL_SERVER_NAME"
    az mysql flexible-server create \
        --resource-group $RESOURCE_GROUP \
        --name $MYSQL_SERVER_NAME \
        --location $LOCATION \
        --admin-user $MYSQL_ADMIN_USER \
        --admin-password $MYSQL_ADMIN_PASSWORD \
        --sku-name Standard_B2ms \
        --tier Burstable \
        --version 8.0.21 \
        --yes
    display_success "MySQL server created"
fi

# Create MySQL Database
display_step "3" "Creating MySQL Database"
echo "Checking database: $MYSQL_DB_NAME on server $MYSQL_SERVER_NAME"
if az mysql flexible-server db show --resource-group $RESOURCE_GROUP --server-name $MYSQL_SERVER_NAME --database-name $MYSQL_DB_NAME --output none 2>/dev/null; then
    display_success "MySQL database already exists"
else
    echo "Creating database: $MYSQL_DB_NAME on server $MYSQL_SERVER_NAME"
    az mysql flexible-server db create \
        --resource-group $RESOURCE_GROUP \
        --server-name $MYSQL_SERVER_NAME \
        --database-name $MYSQL_DB_NAME
    display_success "MySQL database created"
fi

# Configure MySQL Firewall Rules
display_step "4" "Configuring MySQL Firewall Rules"
echo "Allowing Azure services to access MySQL"
az mysql flexible-server firewall-rule create \
    --resource-group $RESOURCE_GROUP \
    --name $MYSQL_SERVER_NAME \
    --rule-name AllowAzureServices \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 0.0.0.0

# Get local IP and allow it for database imports
LOCAL_IP=$(curl -s https://api.ipify.org)
if [ -n "$LOCAL_IP" ]; then
    echo "Allowing your IP address ($LOCAL_IP) to access MySQL"
    az mysql flexible-server firewall-rule create \
        --resource-group $RESOURCE_GROUP \
        --name $MYSQL_SERVER_NAME \
        --rule-name AllowMyIP \
        --start-ip-address $LOCAL_IP \
        --end-ip-address $LOCAL_IP
else
    display_warning "Could not determine your IP address. You'll need to manually add a firewall rule for database imports."
fi

# Import Database
display_step "5" "Preparing Database Import"
echo "Using local database file: $LOCAL_DB_FILE"

if [ -f "$LOCAL_DB_FILE" ]; then
    echo "Database file found."
    echo "To import the database, run this command manually (the script can't store your password securely):"
    echo "mysql -h $MYSQL_SERVER_NAME.mysql.database.azure.com -u $MYSQL_ADMIN_USER@$MYSQL_SERVER_NAME -p $MYSQL_DB_NAME < $LOCAL_DB_FILE"
else
    display_error "Database file not found at $LOCAL_DB_FILE. Please check the path."
    exit 1
fi

# Create App Service Plan & Web App
display_step "6" "Creating App Service & Web App"
echo "Creating App Service Plan: $APP_SERVICE_PLAN"
az appservice plan create \
    --name $APP_SERVICE_PLAN \
    --resource-group $RESOURCE_GROUP \
    --sku P1V2 \
    --is-linux

echo "Creating Web App: $WEB_APP_NAME"
az webapp create \
    --resource-group $RESOURCE_GROUP \
    --plan $APP_SERVICE_PLAN \
    --name $WEB_APP_NAME \
    --runtime "PHP|8.1"

# Configure PHP Settings
display_step "7" "Configuring PHP Settings"
echo "Setting PHP configuration for Moodle"
az webapp config appsettings set \
    --resource-group $RESOURCE_GROUP \
    --name $WEB_APP_NAME \
    --settings \
    PHP_INI_SCAN_DIR="/usr/local/etc/php/conf.d:/home/site/ini" \
    PHP_MEMORY_LIMIT=512M \
    MAX_EXECUTION_TIME=300 \
    UPLOAD_MAX_FILESIZE=50M \
    POST_MAX_SIZE=50M

# Get Storage Key first
display_step "8" "Getting Storage Account Key"
STORAGE_KEY=$(az storage account keys list \
    --resource-group $RESOURCE_GROUP \
    --account-name $STORAGE_ACCOUNT \
    --query "[0].value" \
    --output tsv)

if [ -z "$STORAGE_KEY" ]; then
    display_error "Storage key retrieval failed. Cannot proceed with storage operations."
    exit 1
fi

# Create file share
display_step "8a" "Creating Azure File Share"
az storage share create \
    --name moodledata \
    --account-name $STORAGE_ACCOUNT \
    --account-key "$STORAGE_KEY" \
    --quota 100

# Upload Moodledata Content
display_step "8b" "Uploading Moodledata Content"
echo "Using local moodledata from: $LOCAL_MOODLEDATA_DIR"

if [ -d "$LOCAL_MOODLEDATA_DIR" ]; then
    echo "Uploading moodledata to Azure Files..."
    az storage file upload-batch \
        --account-name $STORAGE_ACCOUNT \
        --account-key "$STORAGE_KEY" \
        --destination moodledata \
        --source "$LOCAL_MOODLEDATA_DIR"
    display_success "Moodledata uploaded successfully"
else
    display_error "Moodledata directory not found at $LOCAL_MOODLEDATA_DIR. Please check the path."
    exit 1
fi

# Mount storage to web app
display_step "8c" "Mounting Storage to Web App"
echo "Mounting Moodledata to Web App"
az webapp config storage-account add \
    --resource-group $RESOURCE_GROUP \
    --name $WEB_APP_NAME \
    --custom-id MoodleData \
    --storage-type AzureFiles \
    --share-name moodledata \
    --account-name $STORAGE_ACCOUNT \
    --mount-path /home/site/wwwroot/moodledata \
    --access-key "$STORAGE_KEY"
display_success "Storage mounted successfully"

# Deploy Moodle Code
display_step "9" "Deploying Moodle Code"
echo "Using local Moodle code from: $LOCAL_MOODLE_DIR"

if [ -d "$LOCAL_MOODLE_DIR" ]; then
    echo "Creating ZIP deployment package"

    # Create temporary directory for deployment
    rm -rf /tmp/moodle_deployment || true
    mkdir -p /tmp/moodle_deployment

    # Copy Moodle files to temp directory
    echo "Copying Moodle files..."
    cp -R "$LOCAL_MOODLE_DIR"/* /tmp/moodle_deployment/

    # Create ZIP file for deployment
    echo "Creating ZIP file..."
    cd /tmp/moodle_deployment
    zip -r /tmp/moodle_deployment.zip . || {
        display_error "ZIP creation failed.";
        exit 1;
    }

    echo "Deploying to Azure Web App"
    az webapp deployment source config-zip \
        --resource-group $RESOURCE_GROUP \
        --name $WEB_APP_NAME \
        --src /tmp/moodle_deployment.zip \
        || {
            display_error "Deployment failed.";
            exit 1;
        }
else
    display_error "Moodle code directory not found at $LOCAL_MOODLE_DIR. Please check the path."
    exit 1
fi

# Create Moodle configuration file
display_step "10" "Creating Moodle Configuration File"
echo "Creating config.php for Moodle"

CONFIG_PHP=$(cat << 'EOF'
<?php
$CFG = new stdClass();

$CFG->dbtype    = 'mysqli';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'MYSQL_SERVER_NAME.mysql.database.azure.com:3306';
$CFG->dbname    = 'MYSQL_DB_NAME';
$CFG->dbuser    = 'MYSQL_ADMIN_USER@MYSQL_SERVER_NAME';
$CFG->dbpass    = 'MYSQL_ADMIN_PASSWORD';
$CFG->prefix    = 'mdl_';
$CFG->dboptions = array(
    'ssl' => array(
        'verify_server_cert' => false,
    )
);

$CFG->wwwroot   = 'https://WEB_APP_NAME.azurewebsites.net';
$CFG->dataroot  = '/home/site/wwwroot/moodledata';
$CFG->directorypermissions = 0777;
$CFG->admin = 'admin';

// This is important for Azure - helps with load balancing
$CFG->sslproxy = true;

// Caching settings (Recommended for Azure)
$CFG->sessiontimeout = 7200;  // 2 hours
$CFG->session_handler_class = '\core\session\file';
$CFG->session_file_save_path = ini_get('session.save_path');

// Debugging (turn off for production)
$CFG->debug = 0;
$CFG->debugdisplay = 0;

require_once(__DIR__ . '/lib/setup.php');
EOF
)

# Replace placeholders
CONFIG_PHP=${CONFIG_PHP//MYSQL_SERVER_NAME/$MYSQL_SERVER_NAME}
CONFIG_PHP=${CONFIG_PHP//MYSQL_DB_NAME/$MYSQL_DB_NAME}
CONFIG_PHP=${CONFIG_PHP//MYSQL_ADMIN_USER/$MYSQL_ADMIN_USER}
CONFIG_PHP=${CONFIG_PHP//MYSQL_ADMIN_PASSWORD/$MYSQL_ADMIN_PASSWORD}
CONFIG_PHP=${CONFIG_PHP//WEB_APP_NAME/$WEB_APP_NAME}

# Save config.php to file
echo "$CONFIG_PHP" > /tmp/config.php

echo "Config file created at /tmp/config.php"
echo "You'll need to upload this file to your Azure Web App at /home/site/wwwroot/config.php"
echo "You can do this through FTP or the Azure Portal's Console feature"

# Upload plugins
display_step "11" "Uploading Plugins"
echo "To install your plugins, you'll need to:"
echo "1. Access your Moodle site at https://$WEB_APP_NAME.azurewebsites.net"
echo "2. Log in as admin"
echo "3. Go to Site Administration > Plugins > Install plugins"
echo "4. Upload your plugin ZIP files"

# Clean up
display_step "12" "Cleaning Up"
echo "Removing temporary files"
rm -f /tmp/moodle_database.sql || true
rm -f /tmp/moodle_code.tar.gz || true
rm -rf /tmp/moodle_extracted || true
rm -f /tmp/moodle_deployment.zip || true

# Display summary
display_step "COMPLETE" "Moodle Deployment Summary"
echo "Resource Group: $RESOURCE_GROUP"
echo "MySQL Server: $MYSQL_SERVER_NAME.mysql.database.azure.com:3306"
echo "Database: $MYSQL_DB_NAME"
echo "Web App URL: https://$WEB_APP_NAME.azurewebsites.net"
echo "Storage Account: $STORAGE_ACCOUNT"

echo -e "\n${GREEN}==========================${NC}"
echo -e "${GREEN}Next Steps:${NC}"
echo -e "${GREEN}==========================${NC}"
echo "1. Import your database (see command above)"
echo "2. Upload config.php to your web app"
echo "3. Visit https://$WEB_APP_NAME.azurewebsites.net to complete setup"
echo "4. Install your plugins through the Moodle admin interface"
echo -e "${GREEN}==========================${NC}"
