#!/bin/bash

# Install wp-cli
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# Wait for MariaDB
until nc -z ${WP_DB_HOST} ${MARIADB_PORT}; do
    echo "Waiting for MariaDB to start on port ${MARIADB_PORT}..."
    sleep 2
done
echo "MariaDB is ready!"

if [ ! -f /var/www/html/wp-config.php ]; then
    echo "WordPress not installed. Proceeding with installation..."

    # Create wp-config.php
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="$(cat /run/secrets/db_password)" \
        --dbhost="${WP_DB_HOST}" \
        --path="/var/www/html" \
        --allow-root

    # Install WordPress
    wp core install \
        --url="${WP_URL}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="$(cat /run/secrets/wp_admin_password)" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --path="/var/www/html" \
        --allow-root

    # Create default page
    wp post create \
        --post_type=page \
        --post_title="Welcome to ${WP_TITLE}" \
        --post_content="<h1>Welcome to ${DOMAIN_NAME}!</h1><p>This is your WordPress installation running in Docker.</p>" \
        --post_status=publish \
        --allow-root

    # Set homepage
    wp option update show_on_front 'page' --allow-root
    wp option update page_on_front $(wp post list --post_type=page --post_status=publish --format=ids --allow-root | head -n 1) --allow-root

    # Create additional user
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="$(cat /run/secrets/wp_user_password)" \
        --allow-root

    # Set correct permissions
    chown -R www-data:www-data /var/www/html
fi

# Start PHP-FPM
exec php-fpm8.2 -F