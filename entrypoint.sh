#!/bin/bash
set -e

# Esperando o banco de dados via PHP (Laravel tenta conectar)
until php artisan migrate:status --no-ansi > /dev/null 2>&1; do
  echo "Aguardando o banco de dados ficar disponível em $DB_HOST..."
  sleep 2
done

# Espera o banco de dados ficar disponível
#echo "Aguardando o banco de dados ficar disponível em $DB_HOST..."
#until mysql -h"$DB_HOST" -u"$DB_USERNAME" -p"$DB_PASSWORD" -e "select 1" &> /dev/null; do
#  sleep 2
#done

cd /var/www/html/krayin

# Checa se a tabela 'migrations' já existe e contém migrações aplicadas
MIGRATED=$(php artisan migrate:status --no-ansi 2>/dev/null | grep -c "| Y |")

if [ "$MIGRATED" -gt 0 ]; then
  echo "Banco já migrado ($MIGRATED migrações aplicadas). Rodando apenas comandos seguros..."
  php artisan optimize:clear
  php artisan storage:link
  php artisan vendor:publish --provider='Webkul\Core\Providers\CoreServiceProvider' --force
  php artisan optimize:clear
else
  echo "Banco **NÃO** migrado ainda. Rodando migrate:fresh --seed (APENAS EM DEV/TESTE!)"
  php artisan optimize:clear
  php artisan migrate:fresh --seed
  php artisan storage:link
  php artisan vendor:publish --provider='Webkul\Core\Providers\CoreServiceProvider' --force
  php artisan optimize:clear
fi

# Sobe o Apache (CMD padrão do php:apache)
exec apache2-foreground
