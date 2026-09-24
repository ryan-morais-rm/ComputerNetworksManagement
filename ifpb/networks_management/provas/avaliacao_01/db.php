<?php
$host = "localhost";
$port = "5432";
$dbname = "abcdefgh";
$user = "postgres";
$password = "postgres"; 

try {
    $dsn = "pgsql:host=$host;port=$port;dbname=$dbname;";
    $pdo = new PDO($dsn, $user, $password, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
    
    echo "<h2>Conexão com o PostgreSQL realizada com sucesso!</h2>";
    
    $query = "SELECT datname FROM pg_database WHERE datistemplate = false;";
    $stmt = $pdo->query($query);
    $databases = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    echo "<h3>Bancos de dados gerenciados no SGBD:</h3><ul>";
    foreach ($databases as $db) {
        echo "<li>" . htmlspecialchars($db) . "</li>";
    }
    echo "</ul>";

} catch (PDOException $e) {
    echo "<p style='color:red;'>Erro na conexão: " . $e->getMessage() . "</p>";
}
?>