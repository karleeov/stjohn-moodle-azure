#!/bin/bash
# test_deployment.sh - Test Moodle Azure deployment

set -e

# Configuration Variables - CUSTOMIZE THESE TO MATCH YOUR DEPLOYMENT
RESOURCE_GROUP="rg-karlli-4586_ai"
WEB_APP_NAME="moodle-site-0530"
MYSQL_SERVER_NAME="moodledb0530"
MYSQL_ADMIN_USER="moodleadmin"
MYSQL_DB_NAME="moodledb"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display test results
display_test() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS: $2${NC}"
    else
        echo -e "${RED}✗ FAIL: $2${NC}"
    fi
}

echo -e "${BLUE}====== MOODLE AZURE DEPLOYMENT TESTS ======${NC}"

# Test 1: Check if web app is accessible
echo -e "\n${BLUE}Test 1: Web App Accessibility${NC}"
WEB_APP_URL="https://$WEB_APP_NAME.azurewebsites.net"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$WEB_APP_URL" || echo "000")

if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "302" ]; then
    display_test 0 "Web app is accessible at $WEB_APP_URL"
else
    display_test 1 "Web app not accessible (HTTP $HTTP_STATUS)"
fi

# Test 2: Check MySQL server connectivity
echo -e "\n${BLUE}Test 2: MySQL Server Connectivity${NC}"
MYSQL_HOST="$MYSQL_SERVER_NAME.mysql.database.azure.com"
echo "Testing connection to $MYSQL_HOST"
echo "You'll be prompted for the MySQL password..."

if mysql -h "$MYSQL_HOST" -u "$MYSQL_ADMIN_USER@$MYSQL_SERVER_NAME" -p -e "SELECT 1;" > /dev/null 2>&1; then
    display_test 0 "MySQL server is accessible"
else
    display_test 1 "MySQL server connection failed"
fi

# Test 3: Check database exists and has data
echo -e "\n${BLUE}Test 3: Database Content Verification${NC}"
echo "Checking if Moodle database has expected tables..."

USER_COUNT=$(mysql -h "$MYSQL_HOST" -u "$MYSQL_ADMIN_USER@$MYSQL_SERVER_NAME" -p -s -N -e "SELECT COUNT(*) FROM $MYSQL_DB_NAME.mdl_user;" 2>/dev/null || echo "0")

if [ "$USER_COUNT" -gt 0 ]; then
    display_test 0 "Database contains $USER_COUNT users"
else
    display_test 1 "Database appears empty or inaccessible"
fi

# Test 4: Check Azure resources exist
echo -e "\n${BLUE}Test 4: Azure Resources Verification${NC}"

# Check Resource Group
if az group show --name "$RESOURCE_GROUP" > /dev/null 2>&1; then
    display_test 0 "Resource group '$RESOURCE_GROUP' exists"
else
    display_test 1 "Resource group '$RESOURCE_GROUP' not found"
fi

# Check Web App
if az webapp show --name "$WEB_APP_NAME" --resource-group "$RESOURCE_GROUP" > /dev/null 2>&1; then
    display_test 0 "Web app '$WEB_APP_NAME' exists"
else
    display_test 1 "Web app '$WEB_APP_NAME' not found"
fi

# Check MySQL Server
if az mysql flexible-server show --name "$MYSQL_SERVER_NAME" --resource-group "$RESOURCE_GROUP" > /dev/null 2>&1; then
    display_test 0 "MySQL server '$MYSQL_SERVER_NAME' exists"
else
    display_test 1 "MySQL server '$MYSQL_SERVER_NAME' not found"
fi

# Test 5: Performance test
echo -e "\n${BLUE}Test 5: Basic Performance Test${NC}"
if command -v ab > /dev/null 2>&1; then
    echo "Running Apache Bench test (10 requests, 2 concurrent)..."
    AB_RESULT=$(ab -n 10 -c 2 "$WEB_APP_URL/" 2>/dev/null | grep "Requests per second" | awk '{print $4}')

    if [ -n "$AB_RESULT" ]; then
        display_test 0 "Performance test completed: $AB_RESULT requests/second"
    else
        display_test 1 "Performance test failed"
    fi
else
    echo -e "${YELLOW}⚠ Apache Bench not installed. Install with: brew install ab${NC}"
fi

# Test 6: SSL Certificate
echo -e "\n${BLUE}Test 6: SSL Certificate Verification${NC}"
SSL_CHECK=$(echo | openssl s_client -servername "$WEB_APP_NAME.azurewebsites.net" -connect "$WEB_APP_NAME.azurewebsites.net:443" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null || echo "failed")

if [ "$SSL_CHECK" != "failed" ]; then
    display_test 0 "SSL certificate is valid"
else
    display_test 1 "SSL certificate verification failed"
fi

echo -e "\n${BLUE}====== TEST SUMMARY ======${NC}"
echo "Manual verification steps:"
echo "1. Visit $WEB_APP_URL and verify Moodle loads"
echo "2. Log in with admin credentials"
echo "3. Check that courses and content are visible"
echo "4. Test file upload functionality"
echo "5. Verify plugins are working correctly"
echo ""
echo "Monitoring URLs:"
echo "- Azure Portal: https://portal.azure.com"
echo "- Resource Group: https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP"
echo "- Application Insights: Search for 'MoodleInsights' in Azure Portal"
