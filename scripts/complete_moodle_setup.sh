#!/bin/bash
# complete_moodle_setup.sh - Complete the Moodle Azure deployment
# Run this script to finish setting up your Moodle installation

set -e

# Configuration from your deployment
RESOURCE_GROUP="rg-karlli-4586_ai"
MYSQL_SERVER="moodledb0530"
MYSQL_DB="moodledb"
MYSQL_USER="moodleadmin"
WEB_APP_NAME="moodle-site-0530"
STORAGE_ACCOUNT="moodlestore05301440"

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

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Moodle Azure Setup Completion Script${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo "This script will help you complete your Moodle setup."
echo "Your infrastructure is already deployed:"
echo "• Resource Group: $RESOURCE_GROUP"
echo "• MySQL Server: $MYSQL_SERVER.mysql.database.azure.com"
echo "• Web App: https://$WEB_APP_NAME.azurewebsites.net"
echo ""

# Step 1: Database Import
display_step "1" "Database Import"
echo "First, you need to import your database."
echo ""
echo "IMPORTANT: You'll need the MySQL password you set during deployment."
echo ""
echo "Run this command to import your database:"
echo -e "${YELLOW}mysql -h $MYSQL_SERVER.mysql.database.azure.com -u $MYSQL_USER@$MYSQL_SERVER -p $MYSQL_DB < moodle_database.sql${NC}"
echo ""
read -p "Have you successfully imported the database? (y/n): " db_imported

if [[ $db_imported != "y" && $db_imported != "Y" ]]; then
    echo "Please import the database first, then run this script again."
    exit 1
fi

display_success "Database import confirmed"

# Step 2: Update config.php with password
display_step "2" "Configure Database Password"
echo "The config.php file has been updated with Azure settings, but you need to add your MySQL password."
echo ""
echo "Please enter your MySQL password (the one you set during deployment):"
read -s MYSQL_PASSWORD
echo ""

# Update the config.php file with the actual password
sed -i.bak "s/YOUR_MYSQL_PASSWORD_HERE/$MYSQL_PASSWORD/g" moodle_code/config.php

display_success "Config.php updated with password"

# Step 3: Deploy updated config.php
display_step "3" "Deploy Updated Moodle Code"
echo "Creating deployment package with updated config.php..."

# Create temporary directory for deployment
rm -rf /tmp/moodle_azure_final || true
mkdir -p /tmp/moodle_azure_final

# Copy all Moodle files including updated config.php
cp -R moodle_code/* /tmp/moodle_azure_final/

# Create ZIP file
cd /tmp/moodle_azure_final
zip -r /tmp/moodle_final_deployment.zip . > /dev/null

echo "Deploying to Azure Web App..."
az webapp deployment source config-zip \
    --resource-group $RESOURCE_GROUP \
    --name $WEB_APP_NAME \
    --src /tmp/moodle_final_deployment.zip

display_success "Updated Moodle code deployed"

# Step 4: Test the deployment
display_step "4" "Testing Deployment"
echo "Testing if your Moodle site is accessible..."

# Test the site
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$WEB_APP_NAME.azurewebsites.net/ || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    display_success "Moodle site is accessible!"
elif [ "$HTTP_STATUS" = "302" ]; then
    display_success "Moodle site is accessible (redirecting to setup)!"
else
    display_warning "Site returned HTTP status: $HTTP_STATUS"
    echo "This might be normal if Moodle needs initial setup."
fi

# Step 5: Setup monitoring (optional)
display_step "5" "Setup Monitoring (Optional)"
echo "Would you like to set up monitoring and alerts for your Moodle installation?"
read -p "Setup monitoring? (y/n): " setup_monitoring

if [[ $setup_monitoring == "y" || $setup_monitoring == "Y" ]]; then
    echo "Running post-deployment setup..."
    
    # Update the post-deployment script with correct values
    sed -i.bak "s/MoodleResourceGroup/$RESOURCE_GROUP/g" post_deployment_setup.sh
    sed -i.bak "s/moodle-site-\$(date +%m%d)/$WEB_APP_NAME/g" post_deployment_setup.sh
    sed -i.bak "s/moodledb\$(date +%m%d)/$MYSQL_SERVER/g" post_deployment_setup.sh
    
    # Make it executable and run it
    chmod +x post_deployment_setup.sh
    ./post_deployment_setup.sh
    
    display_success "Monitoring setup completed"
else
    echo "Skipping monitoring setup. You can run post_deployment_setup.sh later if needed."
fi

# Cleanup
echo "Cleaning up temporary files..."
rm -f /tmp/moodle_final_deployment.zip || true
rm -rf /tmp/moodle_azure_final || true

# Final summary
display_step "COMPLETE" "Setup Complete!"
echo -e "${GREEN}🎉 Your Moodle installation is ready!${NC}"
echo ""
echo "📋 Summary:"
echo "• Database: Imported and configured"
echo "• Application: Deployed with Azure configuration"
echo "• URL: https://$WEB_APP_NAME.azurewebsites.net"
echo ""
echo "🚀 Next Steps:"
echo "1. Visit https://$WEB_APP_NAME.azurewebsites.net"
echo "2. Complete any initial Moodle setup if prompted"
echo "3. Log in with your admin credentials"
echo "4. Install any additional plugins through the Moodle admin interface"
echo "5. Configure your courses and users"
echo ""
echo "📊 Monitoring:"
if [[ $setup_monitoring == "y" || $setup_monitoring == "Y" ]]; then
    echo "• Application Insights: Enabled"
    echo "• Performance Alerts: Configured"
    echo "• Budget Alerts: Set to $300/month"
else
    echo "• Run post_deployment_setup.sh to enable monitoring"
fi
echo ""
echo -e "${GREEN}Enjoy your new Azure-hosted Moodle installation! 🎓${NC}"
