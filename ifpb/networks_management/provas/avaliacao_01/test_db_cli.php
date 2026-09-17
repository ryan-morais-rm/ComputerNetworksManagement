<?php
$host = "localhost";
$dbname = "if_db";
$user = "postgres";
$password = "";

try {
    $pdo = new PDO("pgsql:host=$host;dbname=$dbname", $user, $password);
    echo "[CLI] Conectado com sucesso ao banco 'ifal_db' via linha de comando!\n";
} catch (PDOException $e) {
    echo "[CLI] Erro: " . $e->getMessage() . "\n";
}