#!/bin/bash

# Debugging aktivieren
set -x
echo "Starting initialization script..."

# Ersetze Umgebungsvariablen in der Konfigurationsdatei
envsubst '${MARIADB_PORT}' < /etc/mysql/mariadb.conf.d/50-server.cnf.template > /etc/mysql/mariadb.conf.d/50-server.cnf

# Prüfe ob die WordPress-Datenbank existiert
if ! mariadb -u root -e "USE ${MYSQL_DATABASE}" 2>/dev/null; then
    echo "Initializing MariaDB database..."

    # Wenn die MySQL-Verzeichnisse nicht existieren, initialisiere sie
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        mariadb-install-db --user=mysql --datadir=/var/lib/mysql
    fi

    # Starte temporären Server
    echo "Starting temporary MariaDB server..."
    mariadbd --user=mysql &

    # Warte bis Server wirklich bereit ist
    until mariadb-admin ping >/dev/null 2>&1; do
        echo "Waiting for MariaDB to be ready on port ${MARIADB_PORT}..."
        sleep 1
    done

    # Lese die Secrets
    ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
    DB_PASSWORD=$(cat /run/secrets/db_password)

    echo "Configuring MariaDB..."
    # Konfiguriere Datenbank
    mariadb << EOF
# Lösche anonyme Benutzer
DELETE FROM mysql.user WHERE User='';

# Lösche Test-Datenbank
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

# Erstelle WordPress-Datenbank
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

# Erstelle WordPress-Benutzer
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

# Setze Root-Passwort
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';

# Aktualisiere Privilegien
FLUSH PRIVILEGES;
EOF

    # Überprüfe, ob alles erstellt wurde
    echo "Verifying database setup..."
    mariadb -u root -p${ROOT_PASSWORD} -e "SHOW DATABASES; SELECT User, Host FROM mysql.user;"
    echo "Database initialization completed."

    # Beende temporären Server
    mariadb-admin -u root -p${ROOT_PASSWORD} shutdown
fi

echo "Starting MariaDB server on port ${MARIADB_PORT}..."
# Starte MariaDB
exec mariadbd --user=mysql