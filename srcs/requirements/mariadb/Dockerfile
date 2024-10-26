FROM debian:stable-slim

# Install MariaDB
RUN apt-get update && apt-get install -y \
    mariadb-server \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /var/run/mysqld \
    && chown -R mysql:mysql /var/run/mysqld \
    && chmod 777 /var/run/mysqld

# Copy configuration files
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/
COPY tools/init-db.sh /usr/local/bin/

# Make sure the script is executable
RUN chmod +x /usr/local/bin/init-db.sh

# Create data directory
RUN mkdir -p /var/lib/mysql \
    && chown -R mysql:mysql /var/lib/mysql

EXPOSE 3306

# Set the entry point
ENTRYPOINT ["init-db.sh"]