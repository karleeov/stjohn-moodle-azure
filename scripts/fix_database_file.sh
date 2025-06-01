#!/bin/bash
# fix_database_file.sh - Properly clean and import database

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}====== Fix Database File and Import ======${NC}"

# Configuration
MYSQL_HOST="moodledb0530.mysql.database.azure.com"
MYSQL_USER="moodleadmin"
MYSQL_PASSWORD="MoodleAzure2024!"
MYSQL_DB="moodledb"
ORIGINAL_FILE="moodle_database.sql"
CLEAN_FILE="moodle_database_fixed.sql"
MYSQL_CLIENT="/opt/homebrew/Cellar/mysql-client/9.3.0/bin/mysql"

echo -e "${BLUE}Step 1: Analyzing original database file...${NC}"
echo "File size: $(wc -c < "$ORIGINAL_FILE") bytes"
echo "Total lines: $(wc -l < "$ORIGINAL_FILE") lines"

echo -e "\n${BLUE}Step 2: Creating properly cleaned database file...${NC}"

# Remove all warning lines, error lines, and empty lines, then clean up
grep -v "mysqldump: \[Warning\]" "$ORIGINAL_FILE" | \
grep -v "mysqldump: Error:" | \
grep -v "^$" | \
sed '/^mysqldump:/d' > "$CLEAN_FILE"

echo "Cleaned file size: $(wc -c < "$CLEAN_FILE") bytes"
echo "Cleaned file lines: $(wc -l < "$CLEAN_FILE") lines"

# Check if we have actual SQL content
if grep -q "CREATE TABLE\|INSERT INTO\|DROP TABLE" "$CLEAN_FILE"; then
    echo -e "${GREEN}✓ Found SQL statements in cleaned file${NC}"
else
    echo -e "${RED}✗ No SQL statements found. Let's try a different approach...${NC}"
    
    # Alternative: Extract only the SQL parts
    echo "Trying alternative cleaning method..."
    awk '/^--/ || /^\/\*/ || /^CREATE/ || /^INSERT/ || /^DROP/ || /^USE/ || /^SET/ || /^LOCK/ || /^UNLOCK/ || /^ALTER/ {print}' "$ORIGINAL_FILE" > "$CLEAN_FILE"
    
    if grep -q "CREATE TABLE\|INSERT INTO" "$CLEAN_FILE"; then
        echo -e "${GREEN}✓ Alternative cleaning successful${NC}"
    else
        echo -e "${RED}✗ Still no SQL content found${NC}"
        echo "Let's check what's actually in the file..."
        echo "First 10 lines of original file:"
        head -10 "$ORIGINAL_FILE"
        echo ""
        echo "Last 10 lines of original file:"
        tail -10 "$ORIGINAL_FILE"
        exit 1
    fi
fi

echo -e "\n${BLUE}Step 3: Testing connection...${NC}"
if echo "SELECT 1;" | $MYSQL_CLIENT -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Connection successful${NC}"
else
    echo -e "${RED}✗ Connection failed${NC}"
    exit 1
fi

echo -e "\n${BLUE}Step 4: Importing fixed database...${NC}"
echo "This may take several minutes..."

# Try import with error handling
if $MYSQL_CLIENT -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB" < "$CLEAN_FILE" 2>&1 | tee import_log.txt; then
    echo -e "${GREEN}✓ Import command completed${NC}"
else
    echo -e "${RED}✗ Import command failed${NC}"
    echo "Check import_log.txt for details"
fi

echo -e "\n${BLUE}Step 5: Verifying import...${NC}"

# Check if tables were created
TABLE_COUNT=$($MYSQL_CLIENT -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -s -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$MYSQL_DB';" 2>/dev/null || echo "0")

echo "Tables created: $TABLE_COUNT"

if [ "$TABLE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓ Tables found in database${NC}"
    
    # Check for users
    USER_COUNT=$($MYSQL_CLIENT -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -s -N -e "SELECT COUNT(*) FROM $MYSQL_DB.mdl_user;" 2>/dev/null || echo "0")
    echo "Users found: $USER_COUNT"
    
    if [ "$USER_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Database import successful!${NC}"
        
        # Show some stats
        echo ""
        echo "Database statistics:"
        $MYSQL_CLIENT -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "
        SELECT 'Tables' as Type, COUNT(*) as Count FROM information_schema.tables WHERE table_schema = '$MYSQL_DB'
        UNION ALL
        SELECT 'Users', COUNT(*) FROM $MYSQL_DB.mdl_user
        UNION ALL
        SELECT 'Courses', COUNT(*) FROM $MYSQL_DB.mdl_course;" 2>/dev/null
        
        echo ""
        echo -e "${GREEN}SUCCESS! Database imported successfully.${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Run: ./complete_moodle_setup.sh"
        echo "2. Visit: https://moodle-site-0530.azurewebsites.net"
        
    else
        echo -e "${YELLOW}⚠ Tables created but no users found${NC}"
        echo "The import may be incomplete"
    fi
    
else
    echo -e "${RED}✗ No tables found - import failed${NC}"
    echo ""
    echo "Troubleshooting options:"
    echo "1. Check import_log.txt for error details"
    echo "2. Try using Azure Cloud Shell:"
    echo "   - Go to https://portal.azure.com"
    echo "   - Open Cloud Shell"
    echo "   - Upload $CLEAN_FILE"
    echo "   - Run: mysql -h $MYSQL_HOST -u $MYSQL_USER -p'$MYSQL_PASSWORD' $MYSQL_DB < $CLEAN_FILE"
    echo ""
    echo "3. Or recreate the database dump without warnings:"
    echo "   - Export from your local Moodle without --single-transaction"
    echo "   - Use: mysqldump -u user -p database > clean_dump.sql"
fi

echo ""
echo "Files created:"
echo "- Cleaned SQL file: $CLEAN_FILE"
echo "- Import log: import_log.txt"
