<?php
// Recibe el id_token de Google Sign-In, lo valida con Google y entra (o crea el paciente).
require '../config.php';
$idToken = texto(entrada(), 'id_token', 4096);
if ($idToken === '') responder(['error' => 'Falta el token de Google'], 422);

$ctx = stream_context_create(['http' => ['timeout' => 10, 'ignore_errors' => true]]);
$resp = @file_get_contents('https://oauth2.googleapis.com/tokeninfo?id_token=' . urlencode($idToken), false, $ctx);
$g = $resp ? json_decode($resp, true) : null;
if (!$g || empty($g['sub']) || ($g['aud'] ?? '') !== GOOGLE_CLIENT_ID) {
  responder(['error' => 'No se pudo validar tu cuenta de Google'], 401);
}
if (!in_array($g['iss'] ?? '', ['accounts.google.com', 'https://accounts.google.com'], true) || (int)($g['exp'] ?? 0) < time()) {
  responder(['error' => 'El token de Google expiró, vuelve a intentarlo'], 401);
}
if (($g['email_verified'] ?? 'false') !== 'true') responder(['error' => 'El correo de Google no está verificado'], 401);

$email = strtolower($g['email']);
$u = fila('SELECT * FROM usuarios WHERE google_id=? OR email=?', [$g['sub'], $email]);
if ($u) {
  if (!$u['google_id']) ejecutar('UPDATE usuarios SET google_id=? WHERE id=?', [$g['sub'], $u['id']]);
} else {
  ejecutar('INSERT INTO usuarios (nombre,email,google_id,rol_id) VALUES (?,?,?,?)',
    [$g['name'] ?? $email, $email, $g['sub'], ROL_PACIENTE]);
  $u = fila('SELECT * FROM usuarios WHERE id=?', [db()->lastInsertId()]);
}
if ($u['estado'] !== 'Activo') responder(['error' => 'Cuenta desactivada'], 403);
abrirSesion($u);
