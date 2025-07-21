#!/bin/bash
set -e

cd /var/www/html/krayin

# Função para esperar o banco MySQL ficar disponível
function wait_for_database() {
  echo "Aguardando o banco de dados ficar disponível em $DB_HOST..."
  until mysql -h"$DB_HOST" -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "SELECT 1" > /dev/null 2>&1; do
    sleep 2
  done
  echo "Banco de dados disponível!"
}

wait_for_database

# Checa se o banco existe
DB_EXISTS=$(mysql -h"$DB_HOST" -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "SHOW DATABASES LIKE '$DB_DATABASE';" 2>/dev/null | grep "$DB_DATABASE" || true)

if [ -z "$DB_EXISTS" ]; then
  echo "Criando banco $DB_DATABASE..."
  mysql -h"$DB_HOST" -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "CREATE DATABASE \`$DB_DATABASE\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
else
  echo "Banco $DB_DATABASE já existe."
fi

# Checa se já existem migrações aplicadas (não roda migrate:fresh se já houver dados)
MIGRATED=$(php artisan migrate:status --no-ansi 2>/dev/null | grep -c "| Y |" || true)

if [ "$MIGRATED" -gt 0 ]; then
  echo "Banco já migrado ($MIGRATED migrações aplicadas). Rodando comandos de manutenção..."
  php artisan optimize:clear
  php artisan storage:link
  php artisan vendor:publish --provider='Webkul\Core\Providers\CoreServiceProvider' --force
  php artisan optimize:clear
  php artisan config:clear
  php artisan config:cache
else
  echo "Banco ainda não migrado. Executando migrate --seed para setup inicial."
  php artisan optimize:clear
  php artisan migrate --seed --force
  php artisan storage:link
  php artisan vendor:publish --provider='Webkul\Core\Providers\CoreServiceProvider' --force
  php artisan optimize:clear
  php artisan config:clear
  php artisan config:cache
fi

exec apache2-foreground
