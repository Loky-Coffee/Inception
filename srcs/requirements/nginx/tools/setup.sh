#!/bin/bash

# Warte auf WordPress
while ! nc -z wordpress 9000; do
    sleep 1
done

# Starte NGINX
exec nginx -g "daemon off;"