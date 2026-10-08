<?php
require '../config.php';
$d = entrada();
$email = strtolower(texto($d, 'email', 150));
$clave = is_string($d['password'] ?? null) ? $d['password'] : '';
$ip = $_SERVER['REMOTE_ADDR'] ?? '';

// Bloqueo temporal: 5 intentos fallidos en 15 minutos por correo o 20 por IP.
$fallos = fila('SELECT
    SUM(email=?) AS por_email, COUNT(*) AS por_ip
  FROM intentos_login WHERE (email=? OR ip=?) AND fecha > DATE_SUB(NOW(), INTERVAL 15 MINUTE)', [$email, $email, $ip]);
if ((int)($fallos['por_email'] ?? 0) >= 5 || (int)($fallos['por_ip'] ?? 0) >= 20) {
  responder(['error' => 'Demasiados intentos fallidos. Espera 15 minutos e inténtalo de nuevo.'], 429);
}

$u = $email === '' ? null : fila('SELECT * FROM usuarios WHERE email=?', [$email]);
if (!$u || !$u['password_hash'] || !password_verify($clave, $u['password_hash'])) {
  ejecutar('INSERT INTO intentos_login (email, ip) VALUES (?,?)', [$email, $ip]);
  responder(['error' => 'Correo o contraseña incorrectos'], 401);
}
if ($u['estado'] !== 'Activo') responder(['error' => 'Cuenta desactivada'], 403);
ejecutar('DELETE FROM intentos_login WHERE email=? OR fecha < DATE_SUB(NOW(), INTERVAL 1 DAY)', [$email]);
abrirSesion($u);
