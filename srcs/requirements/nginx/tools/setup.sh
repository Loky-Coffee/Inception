#!/bin/bash

echo "Starting setup script..."

SSL_DIR="/etc/nginx/ssl"
SSL_CERT="${SSL_CERTIFICATE}"
SSL_KEY="${SSL_CERTIFICATE_KEY}"
SSL_CSR="$SSL_DIR/nginx.csr"
SSL_CONFIG="$SSL_DIR/openssl.cnf"
ROOT_CA_KEY="$SSL_DIR/rootCA.key"
ROOT_CA_CERT="$SSL_DIR/rootCA.crt"

mkdir -p $SSL_DIR
echo "Created SSL directory: $SSL_DIR"

# 1. Root CA Konfigurationsdatei
cat > $SSL_DIR/root_ca.cnf <<EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn

[dn]
C=${SSL_COUNTRY}
ST=${SSL_STATE}
L=${SSL_LOCALITY}
O=${SSL_ORGANIZATION} Root CA
OU=${SSL_ORG_UNIT}
CN=${SSL_ORGANIZATION} Root CA
EOF

# 2. Domain Konfigurationsdatei
cat > $SSL_CONFIG <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[dn]
C=${SSL_COUNTRY}
ST=${SSL_STATE}
L=${SSL_LOCALITY}
O=${SSL_ORGANIZATION}
OU=${SSL_ORG_UNIT}
CN=${DOMAIN_NAME}

[req_ext]
subjectAltName = @alt_names
basicConstraints = CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment

[alt_names]
DNS.1 = ${DOMAIN_NAME}
DNS.2 = www.${DOMAIN_NAME}
EOF

# Überprüfen und Erstellen der Root CA
if [ ! -f "$ROOT_CA_CERT" ] || [ ! -f "$ROOT_CA_KEY" ]; then
    echo "Creating Root CA..."
    openssl genrsa -out $ROOT_CA_KEY 4096
    openssl req -x509 -new -nodes \
        -key $ROOT_CA_KEY \
        -sha256 \
        -days 3650 \
        -out $ROOT_CA_CERT \
        -config $SSL_DIR/root_ca.cnf
fi

# Überprüfen und Erstellen der SSL-Zertifikate
if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
    echo "Creating SSL certificates for ${DOMAIN_NAME}..."
    openssl genrsa -out $SSL_KEY 2048
    openssl req -new \
        -key $SSL_KEY \
        -out $SSL_CSR \
        -config $SSL_CONFIG
    openssl x509 -req \
        -in $SSL_CSR \
        -CA $ROOT_CA_CERT \
        -CAkey $ROOT_CA_KEY \
        -CAcreateserial \
        -out $SSL_CERT \
        -days 365 \
        -sha256 \
        -extensions req_ext \
        -extfile $SSL_CONFIG

    echo "SSL certificates created successfully."
    rm -f $SSL_CSR
else
    echo "SSL certificates already exist. Skipping creation."
fi

# Setze korrekte Berechtigungen
chmod 600 $SSL_KEY $ROOT_CA_KEY
chmod 644 $SSL_CERT $ROOT_CA_CERT

echo "Current SSL directory contents:"
ls -la $SSL_DIR

# Ersetze Umgebungsvariablen in der Nginx-Konfiguration
echo "Configuring Nginx with environment variables..."
envsubst '${NGINX_PORT} ${DOMAIN_NAME} ${SSL_CERTIFICATE} ${SSL_CERTIFICATE_KEY} ${PHP_FPM_PORT} ${SSL_PROTOCOLS} ${SSL_CIPHERS}' \
    < /etc/nginx/conf.d/default.conf.template \
    > /etc/nginx/conf.d/default.conf

# Warte auf WordPress
echo "Waiting for WordPress container..."
until nc -z wordpress ${PHP_FPM_PORT}; do
    echo "Waiting for WordPress to start on port ${PHP_FPM_PORT}..."
    sleep 2
done
echo "WordPress is ready!"

# Starte Nginx
echo "Starting NGINX with SSL support..."
exec nginx -g "daemon off;"