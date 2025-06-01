# Moodle on Azure with Terraform

This Terraform configuration deploys a complete Moodle environment on Azure.

## Architecture

- **Resource Group**: Container for all resources
- **MySQL Flexible Server**: Database backend for Moodle
- **App Service Plan**: Compute plan for the web application
- **Linux Web App**: Hosts the Moodle PHP application

## Prerequisites

1. **Azure CLI** installed and authenticated
2. **Terraform** installed (version 1.0+)
3. **Azure subscription** with appropriate permissions

## Quick Start

1. **Clone and navigate to terraform directory**
   ```bash
   cd terraform
   ```

2. **Copy and configure variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Plan the deployment**
   ```bash
   terraform plan
   ```

5. **Apply the configuration**
   ```bash
   terraform apply
   ```

6. **Deploy Moodle code**
   ```bash
   # After infrastructure is created, deploy your Moodle files
   az webapp deployment source config-zip \
     --resource-group $(terraform output -raw resource_group_name) \
     --name $(terraform output -raw app_service_name) \
     --src moodle.zip
   ```

## Configuration

### Required Variables

- `mysql_admin_password`: Strong password for MySQL admin user

### Optional Variables

All other variables have sensible defaults but can be customized in `terraform.tfvars`.

## Outputs

- `resource_group_name`: Name of the created resource group
- `mysql_server_fqdn`: Fully qualified domain name of MySQL server
- `app_service_url`: URL of the deployed web application
- `app_service_name`: Name of the App Service for deployments

## Security Considerations

1. **Use strong passwords** for MySQL
2. **Enable SSL** for MySQL connections in production
3. **Configure firewall rules** appropriately
4. **Use Azure Key Vault** for sensitive configuration in production
5. **Enable monitoring and logging**

## Cost Optimization

- **Development**: Use B1 App Service Plan and B_Standard_B1s MySQL
- **Production**: Use P1v2+ App Service Plan and GP_Standard_D2s+ MySQL
- **Consider reserved instances** for long-term deployments

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Advanced Configuration

For production deployments, consider:
- Azure Application Gateway for load balancing
- Azure CDN for static content
- Azure Redis Cache for session storage
- Azure Storage for file uploads
- Azure Monitor for logging and alerting
