FROM debian:stable-slim
RUN apt-get update && apt-get install -y \
    locales \
    php8.2 \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-gd \
    php8.2-xml \
    php8.2-mbstring \
    php8.2-curl \
    wget \
    unzip && rm -rf /var/lib/apt/lists/*
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG=en_US.utf8

RUN mkdir -p /var/www/html

RUN wget https://wordpress.org/latest.tar.gz && \
    tar -xvzf latest.tar.gz && \
    mv wordpress/ /var/www/html/ && \
    rm -rf wordpress latest.tar.gz

RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

EXPOSE 9000

CMD ["php-fpm8.2", "-F"]
