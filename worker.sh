#!/bin/bash

echo "Starting Pixelfed Webserver"

# wait till the webserver is started
sleep 3

php artisan config:cache

# Migrate database if the app was upgraded
php artisan migrate --force
# Run other specific migratins if required
php artisan update

# Refresh the environment
php artisan storage:link
php artisan horizon:assets
php artisan route:cache
php artisan view:cache

# Finally run Apache
exec php artisan horizon