#!/bin/bash

echo "Starting setup script..."

# Ensure CERTS_PATH is set
CERTS_PATH=${CERTS_PATH:-/etc/nginx/ssl}

# Create SSL directory
mkdir -p "${CERTS_PATH}"
chmod 755 "${CERTS_PATH}"

echo "Setting up SSL certificates in ${CERTS_PATH}"

# 1. Root CA config
cat > "${CERTS_PATH}/root_ca.cnf" <<EOF
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
CN=${SSL_ROOT_CN}
EOF

# 2. Domain config
cat > "${CERTS_PATH}/openssl.cnf" <<EOF
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

# Generate certificates if they don't exist
if [ ! -f "${SSL_CERTIFICATE}" ] || [ ! -f "${SSL_CERTIFICATE_KEY}" ]; then
    echo "Creating SSL certificates for ${DOMAIN_NAME}..."

    # Generate Root CA if it doesn't exist
    if [ ! -f "${CERTS_PATH}/rootCA.crt" ] || [ ! -f "${CERTS_PATH}/rootCA.key" ]; then
        openssl genrsa -out "${CERTS_PATH}/rootCA.key" 4096
        openssl req -x509 -new -nodes \
            -key "${CERTS_PATH}/rootCA.key" \
            -sha256 \
            -days "${ROOT_CA_DAYS}" \
            -out "${CERTS_PATH}/rootCA.crt" \
            -config "${CERTS_PATH}/root_ca.cnf"
    fi

    # Generate server certificate
    openssl genrsa -out "${SSL_CERTIFICATE_KEY}" 2048
    openssl req -new \
        -key "${SSL_CERTIFICATE_KEY}" \
        -out "${CERTS_PATH}/nginx.csr" \
        -config "${CERTS_PATH}/openssl.cnf"

    openssl x509 -req \
        -in "${CERTS_PATH}/nginx.csr" \
        -CA "${CERTS_PATH}/rootCA.crt" \
        -CAkey "${CERTS_PATH}/rootCA.key" \
        -CAcreateserial \
        -out "${SSL_CERTIFICATE}" \
        -days "${SSL_DAYS}" \
        -sha256 \
        -extensions req_ext \
        -extfile "${CERTS_PATH}/openssl.cnf"

    rm -f "${CERTS_PATH}/nginx.csr"
    echo "SSL certificates created successfully."
fi

# Set proper permissions
chmod 600 "${SSL_CERTIFICATE_KEY}"
chmod 644 "${SSL_CERTIFICATE}"

echo "Current SSL directory contents:"
ls -la "${CERTS_PATH}"

# Configure Nginx
envsubst '${NGINX_PORT} ${DOMAIN_NAME} ${SSL_CERTIFICATE} ${SSL_CERTIFICATE_KEY} ${PHP_FPM_PORT} ${SSL_PROTOCOLS} ${SSL_CIPHERS}' \
    < /etc/nginx/conf.d/default.conf.template \
    > /etc/nginx/conf.d/default.conf

# Wait for WordPress
echo "Waiting for WordPress container..."
until nc -z wordpress ${PHP_FPM_PORT}; do
    echo "Waiting for WordPress to start on port ${PHP_FPM_PORT}..."
    sleep 2
done
echo "WordPress is ready!"

echo "Starting NGINX..."
exec nginx -g "daemon off;"