FROM php:8.3-cli-alpine3.20

# Install system dependencies
RUN apk add --no-cache \
    git \
    mysql-client \
    gnupg \
    gpgme-dev \
    libssh2-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libwebp-dev \
    libxml2-dev \
    icu-dev \
    oniguruma-dev \
    libzip-dev \
    linux-headers \
    imagemagick \
    imagemagick-dev \
    $PHPIZE_DEPS

# Configure and install PHP extensions
RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
    && docker-php-ext-install -j$(nproc) \
        gd \
        intl \
        soap \
        ftp \
        pdo \
        pdo_mysql \
        mbstring \
        zip \
        bcmath \
        opcache

# Install PECL extensions (redis + imagick added)
RUN pecl install gnupg ssh2-1.4.1 pcov redis imagick \
    && docker-php-ext-enable gnupg ssh2 pcov redis imagick

# Configure PHP for CI
# NOTE: opcache.enable_cli=0 is required - enabling it causes Mockery demeter mocks
# to leak between tests, breaking typed property assignments (e.g., LoggerInterface)
RUN echo "memory_limit=512M" > /usr/local/etc/php/conf.d/ci.ini \
    && echo "opcache.enable_cli=0" >> /usr/local/etc/php/conf.d/ci.ini \
    && echo "pcov.enabled=1" >> /usr/local/etc/php/conf.d/ci.ini

# Verify extensions
RUN php -m | grep -i gnupg \
    && php -m | grep -i ssh2 \
    && php -m | grep -i pcov \
    && php -m | grep -i gd \
    && php -m | grep -i redis \
    && php -m | grep -i imagick \
    && echo "All required extensions installed"

# Set working directory
WORKDIR /workspace
