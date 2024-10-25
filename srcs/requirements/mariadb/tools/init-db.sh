#!/bin/bash

# Initialisiere MariaDB wenn nötig
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    # Starte temporären Server
    mariadbd --user=mysql &
    sleep 5  # Warte kurz bis Server bereit ist

    # Lese die Secrets
    ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
    DB_PASSWORD=$(cat /run/secrets/db_password)

    # Konfiguriere Datenbank
    mariadb -u root << EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    # Beende temporären Server
    mariadb-admin -u root shutdown
fi

# Starte MariaDB
exec mariadbd --user=mysql