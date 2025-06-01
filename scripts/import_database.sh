#!/bin/bash
# import_database.sh - Import Moodle database to Azure MySQL

set -e

# Configuration
MYSQL_HOST="moodledb0530.mysql.database.azure.com"
MYSQL_USER="moodleadmin"
MYSQL_DB="moodledb"
DB_FILE="moodle_database.sql"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}====== Moodle Database Import ======${NC}"
echo ""
echo "This script will import your Moodle database to Azure MySQL."
echo ""
echo "Connection details:"
echo "• Host: $MYSQL_HOST"
echo "• Username: $MYSQL_USER"
echo "• Database: $MYSQL_DB"
echo "• Source file: $DB_FILE"
echo ""

# Check if database file exists
if [ ! -f "$DB_FILE" ]; then
    echo -e "${RED}ERROR: Database file '$DB_FILE' not found!${NC}"
    echo "Please make sure you're in the correct directory and the file exists."
    exit 1
fi

echo -e "${GREEN}✓ Database file found${NC}"

# Find MySQL client
MYSQL_CLIENT=""
if command -v mysql >/dev/null 2>&1; then
    MYSQL_CLIENT="mysql"
elif [ -f "/opt/homebrew/Cellar/mysql-client/9.3.0/bin/mysql" ]; then
    MYSQL_CLIENT="/opt/homebrew/Cellar/mysql-client/9.3.0/bin/mysql"
elif [ -f "/opt/homebrew/anaconda3/bin/mysql" ]; then
    MYSQL_CLIENT="/opt/homebrew/anaconda3/bin/mysql"
elif [ -f "/usr/local/bin/mysql" ]; then
    MYSQL_CLIENT="/usr/local/bin/mysql"
else
    echo -e "${RED}ERROR: MySQL client not found!${NC}"
    echo "Please install MySQL client with: brew install mysql-client"
    exit 1
fi

echo -e "${GREEN}✓ MySQL client found: $MYSQL_CLIENT${NC}"

# Test connection first
echo ""
echo -e "${YELLOW}Testing connection to MySQL server...${NC}"
echo "You'll be prompted for your MySQL password."
echo ""

if $MYSQL_CLIENT -h "$MYSQL_HOST" -u "$MYSQL_USER" -p -e "SELECT 1;" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Connection successful!${NC}"
else
    echo -e "${RED}✗ Connection failed!${NC}"
    echo ""
    echo "Troubleshooting tips:"
    echo "1. Make sure you're using the correct password"
    echo "2. Check if your IP is allowed in MySQL firewall rules"
    echo "3. Verify the MySQL server is running"
    echo ""
    echo "You can check firewall rules with:"
    echo "az mysql flexible-server firewall-rule list --name moodledb0530 --resource-group rg-karlli-4586_ai"
    exit 1
fi

# Import database
echo ""
echo -e "${BLUE}Starting database import...${NC}"
echo "This may take a few minutes depending on your database size."
echo "You'll be prompted for your MySQL password again."
echo ""

if $MYSQL_CLIENT -h "$MYSQL_HOST" -u "$MYSQL_USER" -p "$MYSQL_DB" < "$DB_FILE"; then
    echo ""
    echo -e "${GREEN}✓ Database import completed successfully!${NC}"
    echo ""
    
    # Verify import
    echo "Verifying import..."
    USER_COUNT=$($MYSQL_CLIENT -h "$MYSQL_HOST" -u "$MYSQL_USER" -p -s -N -e "SELECT COUNT(*) FROM $MYSQL_DB.mdl_user;" 2>/dev/null || echo "0")
    
    if [ "$USER_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Verification successful: Found $USER_COUNT users in database${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: Could not verify import or database appears empty${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Run: ./complete_moodle_setup.sh"
    echo "2. Visit: https://moodle-site-0530.azurewebsites.net"
    
else
    echo ""
    echo -e "${RED}✗ Database import failed!${NC}"
    echo ""
    echo "Common issues and solutions:"
    echo "1. Check if the database file is valid SQL"
    echo "2. Ensure you have sufficient privileges"
    echo "3. Check for disk space issues"
    echo "4. Verify network connectivity"
    exit 1
fi
