#!/bin/bash

SSL_DIR="/etc/nginx/ssl"
SSL_CERT="$SSL_DIR/nginx.crt"
SSL_KEY="$SSL_DIR/nginx.key"
SSL_CSR="$SSL_DIR/nginx.csr"
SSL_CONFIG="$SSL_DIR/openssl.cnf"
ROOT_CA_KEY="$SSL_DIR/rootCA.key"
ROOT_CA_CERT="$SSL_DIR/rootCA.crt"

mkdir -p $SSL_DIR

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
    echo "Erstelle Root CA..."
    # Root CA Key erstellen
    openssl genrsa -out $ROOT_CA_KEY 4096
    
    # Root CA Zertifikat erstellen
    openssl req -x509 -new -nodes \
        -key $ROOT_CA_KEY \
        -sha256 \
        -days 3650 \
        -out $ROOT_CA_CERT \
        -config $SSL_DIR/root_ca.cnf
fi

if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
    echo "Erstelle SSL-Zertifikate für aalatzas.42.fr..."
    # Private Key erstellen
    openssl genrsa -out $SSL_KEY 2048
    
    # CSR erstellen
    openssl req -new \
        -key $SSL_KEY \
        -out $SSL_CSR \
        -config $SSL_CONFIG
    
    # Domain Zertifikat mit Root CA signieren
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
    
    echo "SSL-Zertifikate erstellt."
    
    # Aufräumen
    rm -f $SSL_CSR
else
    echo "SSL-Zertifikate existieren bereits."
fi

# Berechtigungen setzen
chmod 600 $SSL_KEY $ROOT_CA_KEY
chmod 644 $SSL_CERT $ROOT_CA_CERT