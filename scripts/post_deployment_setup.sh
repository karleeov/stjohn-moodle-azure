#!/bin/bash
# post_deployment_setup.sh - Configure monitoring and backups after Moodle deployment

set -e

# Configuration Variables - CUSTOMIZE THESE TO MATCH YOUR DEPLOYMENT
RESOURCE_GROUP="MoodleResourceGroup"
WEB_APP_NAME="moodle-site-$(date +%m%d)"  # Should match your deployment
MYSQL_SERVER_NAME="moodledb$(date +%m%d)"  # Should match your deployment

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

display_step "1" "Setting up Application Insights"
echo "Creating Application Insights for monitoring"
az monitor app-insights component create \
    --app MoodleInsights \
    --location westus2 \
    --resource-group $RESOURCE_GROUP \
    --application-type web

# Get instrumentation key
INSIGHTS_KEY=$(az monitor app-insights component show \
    --app MoodleInsights \
    --resource-group $RESOURCE_GROUP \
    --query instrumentationKey \
    --output tsv)

# Configure App Service to use Application Insights
az webapp config appsettings set \
    --resource-group $RESOURCE_GROUP \
    --name $WEB_APP_NAME \
    --settings \
    APPINSIGHTS_INSTRUMENTATIONKEY="$INSIGHTS_KEY" \
    APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=$INSIGHTS_KEY"

display_success "Application Insights configured"

display_step "2" "Configuring Database Backup Retention"
echo "Setting MySQL backup retention to 14 days"
az mysql flexible-server update \
    --resource-group $RESOURCE_GROUP \
    --name $MYSQL_SERVER_NAME \
    --backup-retention 14

display_success "Database backup retention configured"

display_step "3" "Creating Performance Alerts"
echo "Setting up CPU usage alert"

# Get the resource ID for the web app
WEB_APP_ID=$(az webapp show \
    --name $WEB_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query id \
    --output tsv)

# Create high CPU alert
az monitor metrics alert create \
    --name "MoodleHighCPU" \
    --resource-group $RESOURCE_GROUP \
    --scopes $WEB_APP_ID \
    --condition "avg Percentage CPU > 80" \
    --window-size 5m \
    --evaluation-frequency 1m \
    --description "Alert when CPU usage exceeds 80%"

# Create high memory alert
az monitor metrics alert create \
    --name "MoodleHighMemory" \
    --resource-group $RESOURCE_GROUP \
    --scopes $WEB_APP_ID \
    --condition "avg MemoryPercentage > 85" \
    --window-size 5m \
    --evaluation-frequency 1m \
    --description "Alert when memory usage exceeds 85%"

display_success "Performance alerts configured"

display_step "4" "Setting up Budget Alert"
echo "Creating budget alert for cost management"

# Create budget (adjust amount as needed)
az consumption budget create \
    --name "MoodleBudget" \
    --amount 300 \
    --time-grain monthly \
    --start-date $(date +%Y-%m-01) \
    --resource-group $RESOURCE_GROUP \
    --category cost

display_success "Budget alert configured"

display_step "5" "Enabling Diagnostic Logs"
echo "Configuring diagnostic logging"

# Enable application logging
az webapp log config \
    --resource-group $RESOURCE_GROUP \
    --name $WEB_APP_NAME \
    --application-logging filesystem \
    --level information \
    --web-server-logging filesystem

display_success "Diagnostic logging enabled"

display_step "COMPLETE" "Post-Deployment Setup Summary"
echo "✓ Application Insights monitoring enabled"
echo "✓ Database backup retention set to 14 days"
echo "✓ Performance alerts configured (CPU > 80%, Memory > 85%)"
echo "✓ Budget alert set for $300/month"
echo "✓ Diagnostic logging enabled"
echo ""
echo "Next steps:"
echo "1. Access Application Insights in Azure Portal to view metrics"
echo "2. Configure email notifications for alerts"
echo "3. Set up automated backups for moodledata if needed"
echo "4. Review and adjust budget limits based on actual usage"
