#! /bin/bash

# if wait-for-it.sh is not installed, install it
if [ ! -f .devcontainer/wait-for-it.sh ]; then
  curl -sSL https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh -o wait-for-it.sh
  chmod +x ./.devcontainer/wait-for-it.sh
fi

docker-compose --file=".devcontainer/docker-compose.yml" up -d

# Set executable permission for the current directory
# remove the existing /var/www/html directory
# create a symbolic link to the current directory at /var/www/html
# This is needed for apache to serve the site
sudo chmod a+x "$(pwd)" && sudo rm -rf /var/www/html && sudo ln -s "$(pwd)" /var/www/html

# Starts the Apache server
# This is necessary to access the site from the browser
apache2ctl start

# Install composer dependencies
composer install --no-interaction

# Setup mysql
.devcontainer/wait-for-it.sh 127.0.0.1:3306 --timeout=120 -- echo "MySQL is up!"

sleep 30

mysql -h 127.0.0.1 -u root --password=root -e "SET @@global.sql_mode='NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';"

# Create the .env file
# Some variables are built from github variables.
# These variables may change when the workspace is restarted.
# Some variables are built from custom variables set in the github repo codespace settings.


# Check if WORKSPACE_NAME is not set and CODESPACE_NAME is set
# If true, set WORKSPACE_NAME to CODESPACE_NAME
# If WORKSPACE_NAME is still not set, generate a random string
# and set WORKSPACE_NAME to the random string
if [ -z "$WORKSPACE_NAME" ] && [ -n "$CODESPACE_NAME" ]; then
  WORKSPACE_NAME=$CODESPACE_NAME
else
  WORKSPACE_NAME=$(openssl rand -hex 8)
fi

# Check if VSCODE_PROXY_URI is not set and LAUNCH_POD_PROXY_URI is set
# If true, set VSCODE_PROXY_URI to LAUNCH_POD_PROXY_URI
if [ -z "$VSCODE_PROXY_URI" ] && [ -n "$LAUNCH_POD_PROXY_URI" ]; then
  VSCODE_PROXY_URI=$LAUNCH_POD_PROXY_URI
# If VSCODE_PROXY_URI is still not set, but GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN is set
# Construct VSCODE_PROXY_URI using the GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN
elif [ -z "$VSCODE_PROXY_URI" ] && [ -n "$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN" ]; then
  VSCODE_PROXY_URI="https://{{port}}.$GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN"
fi

# Construct VSCODE_PROXY_URI_APACHE by replacing {{port}} with 8001
# This is used for the Apache2 proxy
VSCODE_PROXY_URI_APACHE=${VSCODE_PROXY_URI//\{\{port\}\}/8001}
# Remove the trailing slash from VSCODE_PROXY_URI_APACHE
# This is because the .env file can't have a trailing slash
VSCODE_PROXY_URI_APACHE=${VSCODE_PROXY_URI_APACHE%/}

cat >.env <<EOL
APP_NAME=Laravel
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_TIMEZONE=UTC
APP_URL="${VSCODE_PROXY_URI_APACHE}"

APP_LOCALE=en
APP_FALLBACK_LOCALE=en
APP_FAKER_LOCALE=en_US

APP_MAINTENANCE_DRIVER=file
# APP_MAINTENANCE_STORE=database

BCRYPT_ROUNDS=12

LOG_CHANNEL=stack
LOG_STACK=single
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=mysql 
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=Inventory_db
DB_USERNAME=root
DB_PASSWORD=root

SESSION_DRIVER=database
SESSION_LIFETIME=120
SESSION_ENCRYPT=false
SESSION_PATH=/
SESSION_DOMAIN=null

BROADCAST_CONNECTION=log
FILESYSTEM_DISK=local
QUEUE_CONNECTION=database

CACHE_STORE=database
CACHE_PREFIX=

MEMCACHED_HOST=127.0.0.1

REDIS_CLIENT=phpredis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=""
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME="${SMTP_USERNAME}"
MAIL_PASSWORD="${SMTP_PASSWORD}"
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS="${SMTP_USERNAME}"
MAIL_FROM_NAME="TASIMPCO"

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
AWS_USE_PATH_STYLE_ENDPOINT=false

VITE_APP_NAME="${WORKSPACE_NAME}"
EOL

php artisan key:generate
php artisan migrate
php artisan db:seed

nvm install 18
nvm use 18
nvm alias default 18

cd frontend && npm install
