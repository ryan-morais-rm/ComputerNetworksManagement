<?php
$host = "localhost";
$dbname = "abcdefgh";
$user = "postgres";
$password = "postgres";

try {
    $pdo = new PDO("pgsql:host=$host;dbname=$dbname", $user, $password);
    echo "[CLI] Conectado com sucesso ao banco 'abcdefgh' via linha de comando!\n";
} catch (PDOException $e) {
    echo "[CLI] Erro: " . $e->getMessage() . "\n";
}