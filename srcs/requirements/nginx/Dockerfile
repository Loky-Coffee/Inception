FROM debian:stable-slim

# Installiere notwendige Pakete
RUN apt-get update && apt-get install -y \
    curl \
    gnupg2 \
    ca-certificates \
    lsb-release \
    apt-transport-https \
    openssl \
    && curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add - \
    && echo "deb https://nginx.org/packages/debian `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list \
    && apt-get update \
    && apt-get install -y nginx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Erstelle notwendige Verzeichnisse
RUN mkdir -p /etc/nginx/ssl /var/run/nginx

# Kopiere Konfigurationsdateien
COPY conf/nginx.conf /etc/nginx/conf.d/default.conf
COPY tools/setup.sh /usr/local/bin/setup.sh
COPY tools/ssl.sh /usr/local/bin/ssl.sh

# Setze Ausführungsrechte
RUN chmod +x /usr/local/bin/setup.sh /usr/local/bin/ssl.sh

# Setze Berechtigungen
RUN chown -R nginx:nginx /etc/nginx/ssl /var/run/nginx /var/cache/nginx

EXPOSE 443

# Verwende setup.sh als Entrypoint
ENTRYPOINT ["/usr/local/bin/setup.sh"]
CMD ["nginx", "-g", "daemon off;"]