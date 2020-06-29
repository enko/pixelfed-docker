#!/bin/bash

echo "Setting up Pixelfed"

mkdir -p /home/pixelfed/apache/logs
mkdir -p /home/pixelfed/apache/locks
mkdir -p /home/pixelfed/apache/runtime

if [ ! -f "/home/pixelfed/storage/app/cities.json" ]; then
    echo "Initializing storage"
    cp -R /home/pixelfed/pixelfed/storage/* /home/pixelfed/storage
fi

if [ ! -f "/home/pixelfed/bootstrap/app.php" ]; then
    echo "Initializing bootstrap"
    cp -R /home/pixelfed/pixelfed/bootstrap/* /home/pixelfed/bootstrap
fi

php artisan config:cache

# Migrate database if the app was upgraded
php artisan migrate --force
# Run other specific migratins if required
php artisan update

# Refresh the environment
php artisan storage:link
php artisan horizon:publish
php artisan horizon:assets
php artisan route:cache
php artisan view:cache
