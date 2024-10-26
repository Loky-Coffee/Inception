FROM debian:stable-slim

# Install required packages
RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    netcat-traditional \
    gettext-base \  # Für envsubst
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create SSL directory and set permissions
RUN mkdir -p /etc/nginx/ssl && \
    chown -R www-data:www-data /etc/nginx/ssl && \
    chmod 755 /etc/nginx/ssl

# Copy configuration files
COPY conf/nginx.conf /etc/nginx/conf.d/default.conf.template
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# Create necessary directories
RUN mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html

EXPOSE ${NGINX_PORT}

# Use setup.sh as entrypoint
ENTRYPOINT ["/usr/local/bin/setup.sh"]