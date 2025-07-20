FROM php:8.3-apache

# Instala dependências do sistema, PHP extensions, Composer, Node etc...
RUN apt-get update && apt-get install -y \
    git \
    ffmpeg \
    libfreetype6-dev \
    libicu-dev \
    libgmp-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libxpm-dev \
    libzip-dev \
    unzip \
    zlib1g-dev \
    default-mysql-client

# Configurando e instalando extensões PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-configure intl && \
    docker-php-ext-install bcmath calendar exif gd gmp intl mysqli pdo pdo_mysql zip

# Instalando extensões para utilizar o REDIS
RUN pecl install redis && docker-php-ext-enable redis

# Instalando Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/local/bin/composer

# Instalando Node.js
COPY --from=node:22.9 /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node:22.9 /usr/local/bin/node /usr/local/bin/node
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

# Instalando dependências globais Node.js
RUN npm install -g npx laravel-echo-server

# Habilitando o mod_rewrite do Apache
RUN a2enmod rewrite

# Clonando o Krayin CRM (pode ser ajustado para usar um volume também)
WORKDIR /var/www/html
RUN git clone https://github.com/jccl2/krayin-crm-docker krayin

WORKDIR /var/www/html/krayin

# Opcional: setar versão fixa
#RUN git reset --hard v2.0.1

# Instalando dependências do Composer
RUN composer install --no-interaction --optimize-autoloader

# Permissões corretas para o storage e cache
RUN chown -R www-data:www-data /var/www/html/krayin/storage /var/www/html/krayin/bootstrap/cache

# AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using IP. Set the 'ServerName' directive globally to suppress this message
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Copie os arquivos .env na build OU monte como volume depois
# COPY .configs/.env .env
# COPY .configs/.env.testing .env.testing

EXPOSE 80

# Copie o entrypoint que aguarda o banco, executa migrations e comandos finais
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
