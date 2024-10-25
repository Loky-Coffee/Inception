#!/bin/bash
# /requirements/nginx/tools/setup.sh

# SSL-Zertifikate erstellen
/usr/local/bin/ssl.sh

# Warte auf WordPress
until curl -s wordpress:9000 > /dev/null; do
    echo "Waiting for WordPress..."
    sleep 5
done

# Überprüfe die NGINX-Konfiguration
nginx -t || exit 1

# Starte NGINX
exec "$@"