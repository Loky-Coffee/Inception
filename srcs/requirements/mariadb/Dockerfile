FROM debian:stable-slim

RUN apt-get update && apt-get install -y \
    gnupg \
    lsb-release \
    software-properties-common \
    wget \
    curl \
    libaio1 \
    libncurses5 \
    libtinfo5 \
    zlib1g \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup && \
    chmod +x mariadb_repo_setup && \
    ./mariadb_repo_setup && \
    apt-get update && apt-get install -y mariadb-server

RUN echo '[mysqld]\n\
user = mysql\n\
bind-address = 0.0.0.0\n\
port = 3306\n\
socket = /var/run/mysqld/mysqld.sock\n\
skip-networking = false' > /etc/mysql/mariadb.conf.d/50-server.cnf

RUN mkdir -p /var/lib/mysql /var/run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

RUN service mariadb start && \
    mysql -e "CREATE DATABASE IF NOT EXISTS example_db;" && \
    mysql -e "CREATE USER 'example_db'@'%' IDENTIFIED BY 'example_db';" && \
    mysql -e "GRANT ALL PRIVILEGES ON example_db.* TO 'example_db'@'%';" && \
    mysql -e "FLUSH PRIVILEGES;" && \
    service mariadb stop

USER mysql

EXPOSE 3306

CMD ["mariadbd"]