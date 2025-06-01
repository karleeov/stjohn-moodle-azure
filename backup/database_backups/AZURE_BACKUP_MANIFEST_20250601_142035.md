# Azure MySQL Flexible Server Backup

**Backup Date**: Sun Jun  1 14:20:37 HKT 2025
**Backup ID**: 20250601_142035
**Database Server**: moodledb0530.mysql.database.azure.com
**Resource Group**: rg-karlli-4586_ai

## Azure Automatic Backups

Azure MySQL Flexible Server automatically creates backups with the following features:

### Backup Configuration
- **Backup Retention**: 7 days (default)
- **Backup Type**: Full and incremental backups
- **Backup Frequency**: 
  - Full backup: Once per week
  - Incremental backup: Every 5 minutes
- **Geographic Redundancy**: Available if configured

### Current Server Information
- **Version**: 8.0.21
- **SKU**: Standard_B2ms
- **Storage**: UnknownGB
- **Database**: moodle

## Point-in-Time Recovery

Azure supports point-in-time recovery within the retention period:

### Restore Commands
```bash
# Restore to a specific point in time
az mysql flexible-server restore \
    --resource-group rg-karlli-4586_ai \
    --name moodledb0530-restored \
    --source-server moodledb0530 \
    --restore-time "2024-01-01T12:00:00Z"

# Restore to latest backup
az mysql flexible-server restore \
    --resource-group rg-karlli-4586_ai \
    --name moodledb0530-restored \
    --source-server moodledb0530
```

## Manual Database Export

For additional backup security, you can export the database manually:

### Using Azure CLI (requires MySQL client)
```bash
# Export database
mysqldump \
    --host=moodledb0530.mysql.database.azure.com \
    --user=moodleadmin \
    --password \
    --single-transaction \
    --routines \
    --triggers \
    --databases moodle > moodle_backup_20250601_142035.sql
```

### Using Azure Database Migration Service
1. Go to Azure Portal
2. Navigate to Database Migration Service
3. Create migration project
4. Export database to storage account

## Backup Verification

### Check Backup Status
```bash
# List available backups (if supported)
az mysql flexible-server backup list \
    --resource-group rg-karlli-4586_ai \
    --server-name moodledb0530

# Check server status
az mysql flexible-server show \
    --resource-group rg-karlli-4586_ai \
    --name moodledb0530 \
    --query "state"
```

## Recovery Procedures

### 1. Point-in-Time Recovery
- Use Azure CLI restore commands above
- Specify exact timestamp for recovery
- Creates new server instance

### 2. Database Migration
- Export from backup server
- Import to new server
- Update application connection strings

### 3. Complete Infrastructure Recovery
```bash
# 1. Restore infrastructure
cd ../terraform
terraform apply

# 2. Restore database
az mysql flexible-server restore \
    --resource-group rg-karlli-4586_ai \
    --name moodledb0530 \
    --source-server BACKUP_SERVER_NAME

# 3. Deploy application
cd ../deployment
./deploy.sh
```

## Monitoring and Alerts

### Set up backup monitoring
```bash
# Create alert for backup failures
az monitor metrics alert create \
    --name "MySQL Backup Alert" \
    --resource-group rg-karlli-4586_ai \
    --scopes "/subscriptions/SUBSCRIPTION_ID/resourceGroups/rg-karlli-4586_ai/providers/Microsoft.DBforMySQL/flexibleServers/moodledb0530" \
    --condition "count backup_storage_used > 0" \
    --description "Alert when backup storage is used"
```

## Best Practices

1. **Regular Testing**: Test restore procedures monthly
2. **Multiple Backups**: Use both Azure automatic and manual exports
3. **Geographic Distribution**: Enable geo-redundant backups
4. **Documentation**: Keep recovery procedures updated
5. **Access Control**: Limit backup access to authorized personnel

## Security Considerations

- ✅ Backups are encrypted at rest
- ✅ Access controlled via Azure RBAC
- ✅ Network isolation available
- ✅ Audit logging enabled

## Backup Status
- **Azure Automatic Backups**: ✅ Enabled (7-day retention)
- **Manual Export**: ⏳ Available (requires MySQL client)
- **Point-in-Time Recovery**: ✅ Available
- **Geo-Redundancy**: ⚠️  Check configuration

**Backup documentation created**: Sun Jun  1 14:20:37 HKT 2025
