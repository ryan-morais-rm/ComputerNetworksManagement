<?php
echo "<h1>Informações do Sistema Linux</h1>";
echo "<p><strong>Sistema Operacional:</strong> " . php_uname() . "</p>";
echo "<p><strong>Versão do PHP:</strong> " . phpversion() . "</p>";

// Exibe todas as informações de configuração do PHP
// phpinfo();
?>