#!/bin/bash

# Warte auf MariaDB
until mysqladmin ping -h"mariadb" --silent; do
    echo "Waiting for MariaDB..."
    sleep 1
done

# Erstelle wp-config.php wenn sie nicht existiert
if [ ! -f wp-config.php ]; then
    # Lese die Secrets
    DB_PASSWORD=$(cat /run/secrets/db_password)
    
    # Erstelle wp-config.php direkt (nicht über tmp)
    cat > wp-config.php <<EOF
<?php
define( 'DB_NAME', '${WORDPRESS_DB_NAME}' );
define( 'DB_USER', '${WORDPRESS_DB_USER}' );
define( 'DB_PASSWORD', '${DB_PASSWORD}' );
define( 'DB_HOST', '${WORDPRESS_DB_HOST}' );
\$table_prefix = 'wp_';
require_once ABSPATH . 'wp-settings.php';
EOF

    chmod 644 wp-config.php
fi

# Starte PHP-FPM
exec "$@"