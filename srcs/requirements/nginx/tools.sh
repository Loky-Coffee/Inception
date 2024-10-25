#!/bin/bash
#tools.sh

SSL_DIR="/etc/nginx/ssl"
SSL_CERT="$SSL_DIR/nginx.crt"
SSL_KEY="$SSL_DIR/nginx.key"

mkdir -p $SSL_DIR

if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
    echo "Erstelle SSL-Zertifikate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout $SSL_KEY \
        -out $SSL_CERT \
        -subj "/C=DE/ST=Baden-Wuerttemberg/L=Heilbronn/O=42School/OU=IT/CN=localhost"
    echo "SSL-Zertifikate erstellt."
else
    echo "SSL-Zertifikate existieren bereits."
fi
