#!/bin/bash

if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    mariadbd --user=mysql & 
    sleep 5

    mysql -e "CREATE DATABASE IF NOT EXISTS example_db;"
    mysql -e "CREATE USER IF NOT EXISTS 'example_db'@'%' IDENTIFIED BY 'example_db';"
    mysql -e "GRANT ALL PRIVILEGES ON example_db.* TO 'example_db'@'%';"
    mysql -e "FLUSH PRIVILEGES;"

    pkill mariadbd
    sleep 5
fi

exec mariadbd --user=mysql