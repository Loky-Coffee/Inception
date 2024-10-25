FROM debian:stable-slim

# Kombinieren Sie alle apt-get Befehle in einem RUN, um die Image-Größe zu reduzieren
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
    # Aufräumen um das Image kleiner zu halten
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Erstelle SSL-Verzeichnis
RUN mkdir -p /etc/nginx/ssl

# Kopiere Konfigurationsdateien
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY tools.sh /usr/local/bin/tools.sh
RUN chmod +x /usr/local/bin/tools.sh

# SSL-Port exponieren
EXPOSE 443

# Healthcheck hinzufügen (optional, aber empfohlen)
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f https://localhost:443/ || exit 1

# Starte Nginx
CMD ["/bin/bash", "-c", "/usr/local/bin/tools.sh && nginx -g 'daemon off;'"]