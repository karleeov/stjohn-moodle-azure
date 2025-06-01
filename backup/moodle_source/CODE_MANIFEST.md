# Moodle Source Code Backup

**Backup Date**: Sun Jun  1 14:17:40 HKT 2025
**Moodle Version**:                                         //         RR    = release increments - 00 in DEV branches.
**Total Files**:    22209
**Total Size**: 256M

## Contents

This backup contains the complete Moodle source code with the following structure:

### Core Directories
- **admin/** - Administration interface and tools
- **auth/** - Authentication plugins
- **blocks/** - Block plugins
- **course/** - Course management
- **lib/** - Core libraries and APIs
- **mod/** - Activity modules (assignments, quizzes, etc.)
- **theme/** - Themes and appearance
- **user/** - User management

### Key Files
- **index.php** - Main entry point
- **config.php.template** - Configuration template (sanitized)
- **version.php** - Moodle version information
- **web.config** - Azure App Service configuration

### Excluded Files
- config.php (contains sensitive data)
- *.log files
- cache/ directory
- temp/ directory
- sessions/ directory

## Deployment Instructions

### 1. Prepare for Deployment
```bash
# Copy the source code
cp -r moodle_source/* /path/to/deployment/

# Configure database connection
cp config.php.template config.php
# Edit config.php with your database settings
```

### 2. Deploy to Azure
```bash
# Create deployment package
zip -r moodle_deployment.zip . -x "*.git*" "*.DS_Store*"

# Deploy to Azure App Service
az webapp deployment source config-zip \
    --resource-group rg-karlli-4586_ai \
    --name moodle-site-0530 \
    --src moodle_deployment.zip
```

### 3. Post-Deployment
1. Configure database connection in config.php
2. Set up file permissions
3. Run Moodle installation/upgrade
4. Configure site settings

## File Structure
```
moodle_source
moodle_source/competency
moodle_source/competency/classes
moodle_source/competency/classes/privacy
moodle_source/competency/classes/external
moodle_source/competency/tests
moodle_source/competency/tests/generator
moodle_source/blocks
moodle_source/blocks/blog_recent
moodle_source/blocks/blog_recent/classes
moodle_source/blocks/blog_recent/classes/privacy
moodle_source/blocks/blog_recent/tests
moodle_source/blocks/blog_recent/tests/behat
moodle_source/blocks/blog_recent/lang
moodle_source/blocks/blog_recent/lang/en
moodle_source/blocks/blog_recent/db
moodle_source/blocks/rss_client
moodle_source/blocks/rss_client/classes
moodle_source/blocks/rss_client/classes/privacy
moodle_source/blocks/rss_client/classes/output
...
```

**Backup completed**: Sun Jun  1 14:17:40 HKT 2025
