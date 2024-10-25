#dockerfile Nginx
FROM debian:stable-slim

RUN apt-get update && apt-get install -y \
    curl \
    gnupg2 \
    ca-certificates \
    lsb-release \
    apt-transport-https \
    openssl

RUN curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
RUN echo "deb https://nginx.org/packages/debian `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list

RUN apt-get update && apt-get install -y nginx

COPY tools.sh /usr/local/bin/tools.sh
RUN chmod +x /usr/local/bin/tools.sh

EXPOSE 443

CMD ["/bin/bash", "-c", "/usr/local/bin/tools.sh && nginx -g 'daemon off;'"]
