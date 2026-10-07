FROM wordpress:php8.3-apache

RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip less curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

ENV COMPOSER_ALLOW_SUPERUSER=1
