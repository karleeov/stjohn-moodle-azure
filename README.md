# 🎓 Moodle Azure Deployment Backup

This repository contains a complete backup of the Moodle deployment on Azure App Service, including infrastructure code, configuration files, and deployment scripts.

## 📋 Repository Contents

### 🏗️ Infrastructure (Terraform)
- **`terraform/`** - Complete Infrastructure as Code
  - `main.tf` - Core Azure resources (App Service, MySQL, etc.)
  - `variables.tf` - Configurable parameters
  - `outputs.tf` - Resource information
  - `terraform.tfvars.example` - Configuration template

### 🚀 Deployment Files
- **`deployment/`** - Deployment scripts and configurations
  - `deploy.sh` - Automated deployment script
  - `web.config` - IIS/Azure App Service configuration
  - `config.php.template` - Moodle configuration template

### 🔧 Emergency Fixes
- **`emergency_fix/`** - Status page and emergency fixes
  - `index.html` - Professional status page
  - `index.php` - PHP fallback with auto-redirect
  - `debug.php` - Diagnostic information

### 📚 Moodle Core
- **`moodle_code/`** - Complete Moodle installation
  - Full Moodle 4.x codebase
  - Custom configurations
  - Azure-optimized settings

## 🌐 Live Deployment

- **Site URL**: https://moodle-site-0530.azurewebsites.net/
- **Resource Group**: rg-karlli-4586_ai
- **App Service**: moodle-site-0530
- **Database**: moodledb0530 (MySQL Flexible Server)

## 🚀 Quick Deployment

### Prerequisites
- Azure CLI installed and configured
- Terraform installed
- Git installed

### Deploy Infrastructure
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

### Deploy Application
```bash
cd deployment
chmod +x deploy.sh
./deploy.sh
```

## 📊 Azure CLI Commands

### Check Deployment Status
```bash
# View deployment status
az webapp deployment list --resource-group rg-karlli-4586_ai --name moodle-site-0530 --output table

# Check app status
az webapp show --resource-group rg-karlli-4586_ai --name moodle-site-0530 --query "state"

# Stream logs
az webapp log tail --resource-group rg-karlli-4586_ai --name moodle-site-0530
```

### Application Management
```bash
# Restart application
az webapp restart --resource-group rg-karlli-4586_ai --name moodle-site-0530

# Scale application
az webapp up --resource-group rg-karlli-4586_ai --name moodle-site-0530 --sku P1v2

# View configuration
az webapp config show --resource-group rg-karlli-4586_ai --name moodle-site-0530
```

### Database Management
```bash
# Check database status
az mysql flexible-server show --resource-group rg-karlli-4586_ai --name moodledb0530

# View firewall rules
az mysql flexible-server firewall-rule list --resource-group rg-karlli-4586_ai --name moodledb0530
```

## 🔧 Troubleshooting

### Common Issues

1. **404 Not Found Error**
   - Check if deployment is complete
   - Verify default documents configuration
   - Restart the app service

2. **Database Connection Issues**
   - Verify firewall rules allow Azure services
   - Check connection string in app settings
   - Ensure database is running

3. **File Permission Issues**
   - Check web.config for proper PHP settings
   - Verify file upload limits
   - Review application logs

### Emergency Recovery
If the site goes down, deploy the emergency fix:
```bash
cd emergency_fix
zip -r ../emergency_fix.zip .
az webapp deployment source config-zip --resource-group rg-karlli-4586_ai --name moodle-site-0530 --src ../emergency_fix.zip
```

## 📈 Features

### ✅ Implemented
- ✅ Complete Moodle 4.x installation
- ✅ Azure App Service deployment
- ✅ MySQL Flexible Server database
- ✅ Professional error handling
- ✅ Terraform infrastructure management
- ✅ Emergency status page
- ✅ Automated deployment scripts

### 🔄 In Progress
- 🔄 SSL certificate configuration
- 🔄 CDN integration
- 🔄 Backup automation
- 🔄 Monitoring and alerts

### 📋 Planned
- 📋 Multi-environment support (Dev/Staging/Prod)
- 📋 CI/CD pipeline integration
- 📋 Performance optimization
- 📋 Security hardening

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Azure App     │    │   MySQL Flexible │    │   Azure Storage │
│   Service       │◄──►│   Server         │    │   (Future)      │
│   (Moodle)      │    │   (Database)     │    │   (Files)       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                        │
         └────────────────────────┼────────────────────────┘
                                  │
                    ┌─────────────────┐
                    │   Terraform     │
                    │   (IaC)         │
                    └─────────────────┘
```

## 📝 Configuration

### Environment Variables
- `MYSQL_HOST` - Database server hostname
- `MYSQL_DATABASE` - Database name
- `MYSQL_USER` - Database username
- `MYSQL_PASSWORD` - Database password
- `MOODLE_URL` - Site URL
- `MOODLE_DATAROOT` - Data directory path

### Key Files
- `config.php` - Moodle configuration
- `web.config` - IIS/Azure configuration
- `terraform/main.tf` - Infrastructure definition

## 🔒 Security

- Database firewall configured for Azure services only
- HTTPS enforced (when SSL configured)
- Sensitive data excluded from repository
- Environment-specific configurations

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Azure App Service logs
3. Verify Terraform state consistency
4. Check database connectivity

## 📄 License

This deployment configuration is provided as-is for educational and development purposes.

---

**Last Updated**: $(date)
**Deployment Status**: ✅ Active
**Version**: 1.0.0
