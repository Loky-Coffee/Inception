#!/bin/bash

# Initialisiere die Datenbank wenn sie noch nicht existiert
if [ ! -d "/var/lib/mysql/mysql" ]; then
    # Initialisiere MariaDB Datenverzeichnis
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    # Starte einen temporären MariaDB Server
    mysqld --user=mysql --datadir=/var/lib/mysql &
    
    # Warte bis der Server bereit ist
    until mysqladmin ping >/dev/null 2>&1; do
        sleep 1
    done

    # Lese die Secrets
    ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
    DB_PASSWORD=$(cat /run/secrets/db_password)

    # Konfiguriere die Datenbank
    mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    # Beende den temporären Server
    mysqladmin -u root shutdown
fi

# Starte den eigentlichen MariaDB Server
exec mysqld --user=mysql