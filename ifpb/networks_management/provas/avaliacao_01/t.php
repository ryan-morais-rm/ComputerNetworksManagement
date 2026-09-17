<?php
function saoPrimos($n) {
    if ($n < 2) return false;
    for ($i = 2; $i <= sqrt($n); $i++) {
        if ($n % $i == 0) return false;
    }
    return true;
}

$contador = 0;
$numero = 2;
$primos = [];

while ($contador < 120) {
    if (saoPrimos($numero)) {
        $primos[] = $numero;
        $contador++;
    }
    $numero++;
}

echo "Os 120 primeiros números primos são:\n";
echo implode(", ", $primos) . "\n";