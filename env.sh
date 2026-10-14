# Settings for this GlitchTip app. Restart the app after you edit this file.
# Lines are NAME=value. The package defaults are already set; uncomment a line to override it.
#
# Every GlitchTip setting: https://glitchtip.com/documentation/install/#configuration

# Local signup closes after the first account. Set true to leave the signup page open.
# ENABLE_USER_REGISTRATION=false

# Cloudron sign-in can create accounts when this is true. Set false to close that after the first account.
# Later people then need an invitation, and invitations only go to existing accounts.
# ENABLE_SOCIAL_APPS_USER_REGISTRATION=false

# After the first organization, only a superuser can create another one.
# ENABLE_ORGANIZATION_CREATION=false

# Name shown in the interface. Markdown is allowed.
# GLITCHTIP_INSTANCE_NAME="My GlitchTip"

# Retention, in days. GLITCHTIP_RETENTION_DAYS is the default for the specific settings below it.
# GLITCHTIP_RETENTION_DAYS=90
# GLITCHTIP_EVENT_RETENTION_DAYS=90
# GLITCHTIP_EVENT_HOT_DAYS=30
# GLITCHTIP_TRANSACTION_RETENTION_DAYS=90
# GLITCHTIP_LOG_RETENTION_DAYS=90
# GLITCHTIP_LOG_HOT_DAYS=7
# GLITCHTIP_UPTIME_RETENTION_DAYS=90
# GLITCHTIP_FILE_RETENTION_DAYS=90
# GLITCHTIP_RELEASE_RETENTION_DAYS=365

# GLITCHTIP_ENABLE_UPTIME=true
# GLITCHTIP_UPTIME_ALLOW_PRIVATE_IPS=false
# GLITCHTIP_ENABLE_LOGS=true
# GLITCHTIP_ENABLE_MCP=false
# LOG_LEVEL=WARNING

# Background work. Raise these together with the app memory limit.
# VTASKS_CONCURRENCY=4
# DATABASE_POOL_MAX_SIZE=5
# GRANIAN_WORKERS=1
# GRANIAN_WORKERS_MAX_RSS=512
