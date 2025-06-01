#!/bin/bash
# clean_and_import_db.sh - Clean database file and import

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}====== Clean and Import Database ======${NC}"

# Configuration
MYSQL_HOST="moodledb0530.mysql.database.azure.com"
MYSQL_USER="moodleadmin"
MYSQL_PASSWORD="MoodleAzure2024!"
MYSQL_DB="moodledb"
ORIGINAL_FILE="moodle_database.sql"
CLEAN_FILE="moodle_database_clean.sql"
MYSQL_CLIENT="/opt/homebrew/Cellar/mysql-client/9.3.0/bin/mysql"

echo -e "${BLUE}Step 1: Cleaning database file...${NC}"

# Remove warning lines and empty lines from the beginning
echo "Removing mysqldump warnings and cleaning file..."
sed '/^mysqldump: \[Warning\]/d' "$ORIGINAL_FILE" | sed '/^$/d' > "$CLEAN_FILE"

# Check if the cleaned file starts with proper SQL
FIRST_LINE=$(head -1 "$CLEAN_FILE")
if [[ $FIRST_LINE == --* ]] || [[ $FIRST_LINE == /** ]] || [[ $FIRST_LINE == CREATE* ]] || [[ $FIRST_LINE == DROP* ]] || [[ $FIRST_LINE == USE* ]]; then
    echo -e "${GREEN}✓ Database file cleaned successfully${NC}"
    echo "First line: $FIRST_LINE"
else
    echo -e "${YELLOW}⚠ Warning: File might need more cleaning. First line: $FIRST_LINE${NC}"
fi

echo -e "\n${BLUE}Step 2: Testing connection...${NC}"
if echo "SELECT 1;" | $MYSQL_CLIENT -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Connection successful${NC}"
else
    echo -e "${RED}✗ Connection failed${NC}"
    exit 1
fi

echo -e "\n${BLUE}Step 3: Importing cleaned database...${NC}"
echo "This may take several minutes..."

# Import with progress indication
if pv "$CLEAN_FILE" 2>/dev/null | $MYSQL_CLIENT -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" 2>&1; then
    echo -e "${GREEN}✓ Database import successful!${NC}"
elif $MYSQL_CLIENT -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" < "$CLEAN_FILE" 2>&1; then
    echo -e "${GREEN}✓ Database import successful!${NC}"
else
    echo -e "${RED}✗ Database import failed${NC}"
    echo ""
    echo "Let's try a different approach..."
    
    # Try importing in smaller chunks or with different options
    echo "Trying with --force option..."
    if $MYSQL_CLIENT -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" --force "$MYSQL_DB" < "$CLEAN_FILE"; then
        echo -e "${GREEN}✓ Database import successful with --force option${NC}"
    else
        echo -e "${RED}✗ Import still failing${NC}"
        echo ""
        echo "Recommended: Use Azure Cloud Shell"
        echo "1. Go to https://portal.azure.com"
        echo "2. Open Cloud Shell"
        echo "3. Upload the cleaned file: $CLEAN_FILE"
        echo "4. Run: mysql -h $MYSQL_HOST -u $MYSQL_USER -p'$MYSQL_PASSWORD' $MYSQL_DB < $CLEAN_FILE"
        exit 1
    fi
fi

echo -e "\n${BLUE}Step 4: Verifying import...${NC}"
USER_COUNT=$($MYSQL_CLIENT -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -s -N -e "SELECT COUNT(*) FROM $MYSQL_DB.mdl_user;" 2>/dev/null || echo "0")

if [ "$USER_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ Verification successful: Found $USER_COUNT users in database${NC}"
    
    # Show some more stats
    echo ""
    echo "Database statistics:"
    $MYSQL_CLIENT -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "
    SELECT 
        'Users' as Table_Type, COUNT(*) as Count FROM $MYSQL_DB.mdl_user
    UNION ALL
    SELECT 
        'Courses' as Table_Type, COUNT(*) as Count FROM $MYSQL_DB.mdl_course
    UNION ALL
    SELECT 
        'Course Modules' as Table_Type, COUNT(*) as Count FROM $MYSQL_DB.mdl_course_modules;" 2>/dev/null || echo "Could not fetch detailed stats"
    
    echo ""
    echo -e "${GREEN}SUCCESS! Database imported successfully.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run: ./complete_moodle_setup.sh"
    echo "2. Visit: https://moodle-site-0530.azurewebsites.net"
    echo ""
    echo "Password for reference: $MYSQL_PASSWORD"
    
else
    echo -e "${YELLOW}⚠ Warning: Could not verify import or database appears empty${NC}"
    echo "You may need to check the import manually"
fi

# Clean up
echo ""
echo "Cleaned database file saved as: $CLEAN_FILE"
echo "You can delete the original file if the import was successful."
