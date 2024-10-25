#!/bin/bash

# Warte auf MariaDB
while ! nc -z mariadb 3306; do
    sleep 1
done

# Starte PHP-FPM
exec php-fpm8.2 -F