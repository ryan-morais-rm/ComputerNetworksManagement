#!/bin/bash
set -e

sudo dnf install -y php-cli 

echo "==> Versão do PHP (Major.Minor):"
php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION . PHP_EOL;'

echo -e "\n==> Versão do PHP (Detalhada):"
php -v

echo -e "\n==> Executando o script de teste..."
if [ -f "t.php" ]; then
    php t.php
else
    echo "Erro: O arquivo 't.php' não foi encontrado nesta pasta."
fi