#!/bin/bash
# monitor_import.sh - Monitor database import progress

# Configuration
MYSQL_HOST="moodledb0530.mysql.database.azure.com"
MYSQL_USER="moodleadmin"
MYSQL_PASSWORD="MoodleAzure2024!"
MYSQL_DB="moodledb"
MYSQL_CLIENT="/opt/homebrew/Cellar/mysql-client/9.3.0/bin/mysql"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}====== Database Import Monitor ======${NC}"
echo "Checking import progress..."
echo ""

while true; do
    # Check if tables exist
    TABLE_COUNT=$($MYSQL_CLIENT -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -s -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$MYSQL_DB';" 2>/dev/null || echo "0")
    
    if [ "$TABLE_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Tables found: $TABLE_COUNT${NC}"
        
        # Check for specific Moodle tables
        USER_COUNT=$($MYSQL_CLIENT -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -s -N -e "SELECT COUNT(*) FROM $MYSQL_DB.mdl_user;" 2>/dev/null || echo "0")
        COURSE_COUNT=$($MYSQL_CLIENT -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -s -N -e "SELECT COUNT(*) FROM $MYSQL_DB.mdl_course;" 2>/dev/null || echo "0")
        
        echo "Users: $USER_COUNT"
        echo "Courses: $COURSE_COUNT"
        
        if [ "$USER_COUNT" -gt 0 ] && [ "$COURSE_COUNT" -gt 0 ]; then
            echo -e "${GREEN}✓ Import appears successful!${NC}"
            break
        fi
    else
        echo "No tables found yet... import still in progress"
    fi
    
    echo "Waiting 30 seconds before next check..."
    sleep 30
    echo ""
done

echo ""
echo -e "${GREEN}Database import completed successfully!${NC}"
echo ""
echo "Final statistics:"
$MYSQL_CLIENT -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "
SELECT 'Tables' as Type, COUNT(*) as Count FROM information_schema.tables WHERE table_schema = '$MYSQL_DB'
UNION ALL
SELECT 'Users', COUNT(*) FROM $MYSQL_DB.mdl_user
UNION ALL
SELECT 'Courses', COUNT(*) FROM $MYSQL_DB.mdl_course
UNION ALL
SELECT 'Course Modules', COUNT(*) FROM $MYSQL_DB.mdl_course_modules;" 2>/dev/null

echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "1. Run: ./complete_moodle_setup.sh"
echo "2. Visit: https://moodle-site-0530.azurewebsites.net"
echo ""
echo "Database password: $MYSQL_PASSWORD"
