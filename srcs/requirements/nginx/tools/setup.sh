#!/bin/bash

echo "Starting setup script..."

SSL_DIR="/etc/nginx/ssl"
SSL_CERT="$SSL_DIR/nginx.crt"
SSL_KEY="$SSL_DIR/nginx.key"
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
C=DE
ST=Baden-Wuerttemberg
L=Heilbronn
O=42School Root CA
OU=IT
CN=42School Root CA
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
C=DE
ST=Baden-Wuerttemberg
L=Heilbronn
O=42School
OU=IT
CN=aalatzas.42.fr

[req_ext]
subjectAltName = @alt_names
basicConstraints = CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment

[alt_names]
DNS.1 = aalatzas.42.fr
DNS.2 = www.aalatzas.42.fr
EOF

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

if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
    echo "Creating SSL certificates for aalatzas.42.fr..."
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
    
    echo "SSL certificates created."
    rm -f $SSL_CSR
else
    echo "SSL certificates already exist."
fi

# Berechtigungen setzen
chmod 600 $SSL_KEY $ROOT_CA_KEY
chmod 644 $SSL_CERT $ROOT_CA_CERT

echo "Listing SSL directory contents:"
ls -la $SSL_DIR

# Warte auf WordPress
echo "Waiting for WordPress..."
while ! nc -z wordpress 9000; do
    sleep 1
done

echo "Starting NGINX..."
exec nginx -g "daemon off;"