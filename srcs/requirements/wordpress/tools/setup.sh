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
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="$(cat /run/secrets/wp_admin_password)" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --path="/var/www/html" \
        --allow-root

    # Create and set homepage
    wp post create \
        --post_type=page \
        --post_title="Home" \
        --post_content="<h1>Welcome to ${DOMAIN_NAME}</h1><p>Welcome to my WordPress site!</p>" \
        --post_status=publish \
        --post_name="home" \
        --allow-root

    # Set homepage as front page
    HOMEPAGE_ID=$(wp post list --post_type=page --post_name="home" --format=ids --allow-root)
    wp option update show_on_front 'page' --allow-root
    wp option update page_on_front "$HOMEPAGE_ID" --allow-root

    # Create sample blog post
    wp post create \
        --post_type=post \
        --post_title="Welcome" \
        --post_content="Welcome to my first blog post!" \
        --post_status=publish \
        --allow-root

    # Create additional user
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="$(cat /run/secrets/wp_user_password)" \
        --allow-root

    # Update URLs in options table
    wp option update home "https://${DOMAIN_NAME}" --allow-root
    wp option update siteurl "https://${DOMAIN_NAME}" --allow-root

    # Disable default themes and plugins
    wp theme delete twentytwentytwo twentytwentythree --allow-root
    wp theme activate twentytwentyone --allow-root
    wp plugin deactivate akismet hello --allow-root
    wp plugin delete akismet hello --allow-root

    # Set permalink structure
    wp rewrite structure '/%postname%/' --allow-root

    # Set correct permissions
    chown -R www-data:www-data /var/www/html
fi

# Start PHP-FPM
exec php-fpm8.2 -F