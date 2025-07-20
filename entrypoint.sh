#!/bin/bash
set -e

cd /var/www/html/krayin

# Função para verificar se o banco está pronto via Laravel
function wait_for_database() {
  echo "Aguardando o banco de dados ficar disponível em $DB_HOST..."
  until php artisan migrate:status --no-ansi > /dev/null 2>&1; do
    sleep 2
  done
  echo "Banco de dados disponível!"
}

wait_for_database

# Checa se já existem migrações aplicadas (evita sobrescrever produção)
MIGRATED=$(php artisan migrate:status --no-ansi 2>/dev/null | grep -c "| Y |")

if [ "$MIGRATED" -gt 0 ]; then
  echo "Banco já migrado ($MIGRATED migrações aplicadas). Rodando comandos de manutenção..."
  php artisan optimize:clear
  php artisan storage:link
  php artisan vendor:publish --provider='Webkul\Core\Providers\CoreServiceProvider' --force
  php artisan optimize:clear
else
  echo "Banco **NÃO** migrado ainda. Executando migrate:fresh --seed para setup inicial."
  php artisan optimize:clear
  php artisan migrate:fresh --seed
  php artisan storage:link
  php artisan vendor:publish --provider='Webkul\Core\Providers\CoreServiceProvider' --force
  php artisan optimize:clear
fi

# Sobe o Apache (CMD padrão do php:apache)
exec apache2-foreground
