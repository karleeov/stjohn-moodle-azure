#!/bin/bash
# fix_moodle_deployment.sh - Fix Moodle deployment issues on Azure

set -e

# Configuration
RESOURCE_GROUP="rg-karlli-4586_ai"
WEB_APP_NAME="moodle-site-0530"
MYSQL_SERVER_NAME="moodledb0530"
MYSQL_ADMIN_USER="moodleadmin"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}====== MOODLE AZURE DEPLOYMENT FIX ======${NC}"
echo "This script will help fix your Moodle deployment issues."
echo ""

# Step 1: Get MySQL password
echo -e "${YELLOW}Step 1: Database Configuration${NC}"
echo "Your current database configuration:"
echo "  Server: $MYSQL_SERVER_NAME.mysql.database.azure.com"
echo "  Database: moodledb"
echo "  Username: $MYSQL_ADMIN_USER"
echo ""
read -s -p "Enter your MySQL admin password: " MYSQL_PASSWORD
echo ""

if [ -z "$MYSQL_PASSWORD" ]; then
    echo -e "${RED}Error: Password cannot be empty${NC}"
    exit 1
fi

# Step 2: Test database connection
echo -e "${YELLOW}Step 2: Testing Database Connection${NC}"
mysql -h $MYSQL_SERVER_NAME.mysql.database.azure.com -u $MYSQL_ADMIN_USER@$MYSQL_SERVER_NAME -p$MYSQL_PASSWORD -e "SELECT 1;" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database connection successful${NC}"
else
    echo -e "${RED}✗ Database connection failed. Please check your password.${NC}"
    exit 1
fi

# Step 3: Update config.php with correct password
echo -e "${YELLOW}Step 3: Updating Moodle Configuration${NC}"
sed -i.bak "s/YOUR_MYSQL_PASSWORD_HERE/$MYSQL_PASSWORD/g" moodle_code/config.php
echo -e "${GREEN}✓ Configuration updated${NC}"

# Step 4: Remove hostingstart.html if it exists
echo -e "${YELLOW}Step 4: Cleaning up deployment files${NC}"
if [ -f "moodle_code/hostingstart.html" ]; then
    rm moodle_code/hostingstart.html
    echo -e "${GREEN}✓ Removed hostingstart.html${NC}"
fi

# Step 5: Create new deployment package
echo -e "${YELLOW}Step 5: Creating deployment package${NC}"
cd moodle_code
zip -r ../moodle_fixed_deployment.zip . -x "*.git*" "*.DS_Store*" > /dev/null
cd ..
echo -e "${GREEN}✓ Deployment package created${NC}"

# Step 6: Deploy to Azure
echo -e "${YELLOW}Step 6: Deploying to Azure${NC}"
az webapp deployment source config-zip \
    --resource-group $RESOURCE_GROUP \
    --name $WEB_APP_NAME \
    --src moodle_fixed_deployment.zip

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Deployment successful${NC}"
else
    echo -e "${RED}✗ Deployment failed${NC}"
    exit 1
fi

# Step 7: Test the deployment
echo -e "${YELLOW}Step 7: Testing deployment${NC}"
echo "Waiting for deployment to complete..."
sleep 30

# Test if site is accessible
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$WEB_APP_NAME.azurewebsites.net/test.php)
if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ Test page accessible${NC}"
else
    echo -e "${RED}✗ Test page not accessible (HTTP $HTTP_STATUS)${NC}"
fi

# Test main Moodle page
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://$WEB_APP_NAME.azurewebsites.net/)
if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✓ Main Moodle page accessible${NC}"
    echo -e "${GREEN}🎉 Deployment fixed successfully!${NC}"
    echo ""
    echo "Your Moodle site is now available at:"
    echo "https://$WEB_APP_NAME.azurewebsites.net"
elif [ "$HTTP_STATUS" = "302" ]; then
    echo -e "${GREEN}✓ Main Moodle page redirecting (this is normal for initial setup)${NC}"
    echo -e "${GREEN}🎉 Deployment fixed successfully!${NC}"
    echo ""
    echo "Your Moodle site is now available at:"
    echo "https://$WEB_APP_NAME.azurewebsites.net"
else
    echo -e "${YELLOW}⚠ Main page returned HTTP $HTTP_STATUS${NC}"
    echo "This might be normal if Moodle needs initial setup."
    echo ""
    echo "Please visit: https://$WEB_APP_NAME.azurewebsites.net"
    echo "And check if Moodle installation wizard appears."
fi

echo ""
echo -e "${BLUE}====== NEXT STEPS ======${NC}"
echo "1. Visit your site: https://$WEB_APP_NAME.azurewebsites.net"
echo "2. If you see the Moodle installation wizard, follow the setup steps"
echo "3. If you see errors, check the Azure App Service logs"
echo "4. Remember to turn off debugging in config.php for production"

# Restore original config.php backup
echo ""
echo -e "${YELLOW}Restoring config.php backup (password removed for security)${NC}"
if [ -f "moodle_code/config.php.bak" ]; then
    mv moodle_code/config.php.bak moodle_code/config.php
    echo -e "${GREEN}✓ Config backup restored${NC}"
fi

echo -e "${GREEN}Script completed!${NC}"
