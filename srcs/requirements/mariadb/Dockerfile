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

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/
COPY tools/init-db.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/init-db.sh && \
    mkdir -p /var/lib/mysql /var/run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

USER mysql

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init-db.sh"]