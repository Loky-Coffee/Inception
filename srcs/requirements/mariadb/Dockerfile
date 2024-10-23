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

RUN mkdir -p /var/lib/mysql /var/run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

RUN echo '[mysqld]\nskip-host-cache\nskip-name-resolve' > /etc/mysql/conf.d/docker.cnf

RUN mysql_install_db --user=mysql --datadir=/var/lib/mysql

USER mysql

EXPOSE 3306

CMD ["mariadbd"]
