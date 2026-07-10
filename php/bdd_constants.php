<?php
$required = ['DB_SERVER', 'DB_NAME', 'DB_USER', 'DB_PASSWORD'];

foreach ($required as $var) {
    if (getenv($var) === false) {
        error_log("Missing required environment variable: $var");
        http_response_code(500);
        die(json_encode(['error' => 'Server misconfiguration']));
    }
}

define('DB_SERVER', getenv('DB_SERVER'));
define('DB_NAME', getenv('DB_NAME'));
define('DB_USER', getenv('DB_USER'));
define('DB_PASSWORD', getenv('DB_PASSWORD'));
define('APP_ENV', getenv('APP_ENV') ?: 'production');

?>
