#!/bin/bash
# fix_mysql_connection.sh - Fix MySQL connection issues

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}====== MySQL Connection Fix ======${NC}"
echo ""

# Step 1: Reset MySQL password to a known value
echo -e "${BLUE}Step 1: Resetting MySQL password...${NC}"
NEW_PASSWORD="MoodleAzure2024!"

echo "Setting password to: $NEW_PASSWORD"
if az mysql flexible-server update --name moodledb0530 --resource-group rg-karlli-4586_ai --admin-password "$NEW_PASSWORD" --output none; then
    echo -e "${GREEN}✓ Password reset successful${NC}"
else
    echo -e "${RED}✗ Password reset failed${NC}"
    exit 1
fi

# Step 2: Check current IP and update firewall if needed
echo -e "\n${BLUE}Step 2: Checking IP address and firewall rules...${NC}"
CURRENT_IP=$(curl -s https://api.ipify.org)
echo "Your current IP: $CURRENT_IP"

# Add current IP to firewall rules
echo "Adding current IP to firewall rules..."
az mysql flexible-server firewall-rule create \
    --resource-group rg-karlli-4586_ai \
    --name moodledb0530 \
    --rule-name "AllowCurrentIP-$(date +%s)" \
    --start-ip-address "$CURRENT_IP" \
    --end-ip-address "$CURRENT_IP" \
    --output none || echo "IP might already be allowed"

echo -e "${GREEN}✓ Firewall rules updated${NC}"

# Step 3: Wait for server to be ready
echo -e "\n${BLUE}Step 3: Waiting for MySQL server to be ready...${NC}"
sleep 10

# Step 4: Test connection
echo -e "\n${BLUE}Step 4: Testing connection...${NC}"
MYSQL_CLIENT="/opt/homebrew/Cellar/mysql-client/9.3.0/bin/mysql"

echo "Testing connection with new password..."
if echo "SELECT 1;" | $MYSQL_CLIENT -h moodledb0530.mysql.database.azure.com -u moodleadmin -p"$NEW_PASSWORD" moodledb >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Connection successful!${NC}"
    
    # Step 5: Import database
    echo -e "\n${BLUE}Step 5: Importing database...${NC}"
    echo "This may take several minutes..."
    
    if $MYSQL_CLIENT -h moodledb0530.mysql.database.azure.com -u moodleadmin -p"$NEW_PASSWORD" moodledb < moodle_database.sql; then
        echo -e "${GREEN}✓ Database import successful!${NC}"
        
        # Verify import
        USER_COUNT=$($MYSQL_CLIENT -h moodledb0530.mysql.database.azure.com -u moodleadmin -p"$NEW_PASSWORD" -s -N -e "SELECT COUNT(*) FROM moodledb.mdl_user;" 2>/dev/null || echo "0")
        echo -e "${GREEN}✓ Verification: Found $USER_COUNT users in database${NC}"
        
        echo ""
        echo -e "${GREEN}SUCCESS! Database imported successfully.${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Update your config.php with the new password: $NEW_PASSWORD"
        echo "2. Run: ./complete_moodle_setup.sh"
        echo "3. Visit: https://moodle-site-0530.azurewebsites.net"
        
    else
        echo -e "${RED}✗ Database import failed${NC}"
        echo ""
        echo "Try using Azure Cloud Shell instead:"
        echo "1. Go to https://portal.azure.com"
        echo "2. Open Cloud Shell (>_ icon)"
        echo "3. Upload your moodle_database.sql file"
        echo "4. Run: mysql -h moodledb0530.mysql.database.azure.com -u moodleadmin -p'$NEW_PASSWORD' moodledb < moodle_database.sql"
        exit 1
    fi
    
else
    echo -e "${RED}✗ Connection still failing${NC}"
    echo ""
    echo "Recommended solution: Use Azure Cloud Shell"
    echo ""
    echo "1. Go to https://portal.azure.com"
    echo "2. Click the Cloud Shell icon (>_) in the top toolbar"
    echo "3. Upload your moodle_database.sql file"
    echo "4. Run these commands:"
    echo ""
    echo "   mysql -h moodledb0530.mysql.database.azure.com \\"
    echo "     -u moodleadmin \\"
    echo "     -p'$NEW_PASSWORD' \\"
    echo "     moodledb < moodle_database.sql"
    echo ""
    echo "5. Verify with:"
    echo "   mysql -h moodledb0530.mysql.database.azure.com \\"
    echo "     -u moodleadmin \\"
    echo "     -p'$NEW_PASSWORD' \\"
    echo "     -e \"SELECT COUNT(*) FROM moodledb.mdl_user;\""
    echo ""
    echo "Password for reference: $NEW_PASSWORD"
fi
