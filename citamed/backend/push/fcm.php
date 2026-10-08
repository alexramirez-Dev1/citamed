<?php
// Envío de notificaciones push con Firebase Cloud Messaging (API HTTP v1).
// Requiere la clave de cuenta de servicio de Firebase (JSON). Ruta por variable de entorno
// FIREBASE_CREDENCIALES o, por defecto, backend/push/firebase-credenciales.json (NO subir a git).

function fcmCredenciales(): ?array {
  static $cred = false;
  if ($cred === false) {
    $ruta = getenv('FIREBASE_CREDENCIALES') ?: __DIR__ . '/firebase-credenciales.json';
    $cred = is_file($ruta) ? json_decode(file_get_contents($ruta), true) : null;
    if (!is_array($cred) || empty($cred['private_key']) || empty($cred['client_email'])) $cred = null;
  }
  return $cred;
}

function b64url(string $s): string { return rtrim(strtr(base64_encode($s), '+/', '-_'), '='); }

// Token OAuth de Google (dura 1 h). Se guarda en un archivo temporal para no pedirlo en cada envío.
function fcmAccessToken(array $cred): ?string {
  $cache = sys_get_temp_dir() . '/citamed_fcm_' . md5($cred['client_email']) . '.json';
  if (is_file($cache)) {
    $c = json_decode(file_get_contents($cache), true);
    if (is_array($c) && ($c['expira'] ?? 0) > time() + 60) return $c['token'];
  }
  $ahora = time();
  $cab = b64url(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
  $cuerpo = b64url(json_encode([
    'iss' => $cred['client_email'],
    'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
    'aud' => 'https://oauth2.googleapis.com/token',
    'iat' => $ahora, 'exp' => $ahora + 3600,
  ]));
  if (!openssl_sign("$cab.$cuerpo", $firma, $cred['private_key'], OPENSSL_ALGO_SHA256)) return null;
  $jwt = "$cab.$cuerpo." . b64url($firma);
  $r = fcmHttp('https://oauth2.googleapis.com/token', ['Content-Type: application/x-www-form-urlencoded'],
    http_build_query(['grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer', 'assertion' => $jwt]));
  $d = json_decode($r['cuerpo'], true);
  if ($r['codigo'] !== 200 || empty($d['access_token'])) { error_log('[CitaMed FCM] token: ' . $r['cuerpo']); return null; }
  @file_put_contents($cache, json_encode(['token' => $d['access_token'], 'expira' => $ahora + (int)$d['expires_in']]));
  return $d['access_token'];
}

function fcmHttp(string $url, array $cabeceras, string $cuerpo): array {
  $ch = curl_init($url);
  curl_setopt_array($ch, [CURLOPT_POST => true, CURLOPT_HTTPHEADER => $cabeceras, CURLOPT_POSTFIELDS => $cuerpo,
    CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 8]);
  $res = curl_exec($ch);
  $codigo = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
  curl_close($ch);
  return ['codigo' => $codigo, 'cuerpo' => $res === false ? '' : $res];
}

// Envía la push a todos los dispositivos del usuario. Nunca lanza error: si falla, la notificación
// igual queda guardada en la bandeja de la app.
function enviarPush(int $usuarioId, string $titulo, string $mensaje, array $datos = []): void {
  try {
    $cred = fcmCredenciales();
    if (!$cred || !function_exists('curl_init')) return;
    $tokens = consulta('SELECT token FROM dispositivos WHERE usuario_id=?', [$usuarioId]);
    if (!$tokens) return;
    $acceso = fcmAccessToken($cred);
    if (!$acceso) return;
    $url = 'https://fcm.googleapis.com/v1/projects/' . $cred['project_id'] . '/messages:send';
    $datos = array_map('strval', $datos + ['tipo' => 'notificacion']);
    foreach ($tokens as $t) {
      $r = fcmHttp($url, ['Authorization: Bearer ' . $acceso, 'Content-Type: application/json'], json_encode([
        'message' => [
          'token' => $t['token'],
          'notification' => ['title' => $titulo, 'body' => $mensaje],
          'data' => $datos,
          'android' => ['priority' => 'high', 'notification' => ['channel_id' => 'avisos_citamed', 'sound' => 'default']],
          'apns' => ['payload' => ['aps' => ['sound' => 'default']]],
        ],
      ], JSON_UNESCAPED_UNICODE));
      // Token vencido o de otra app: se borra para no reintentarlo.
      if ($r['codigo'] === 404 || ($r['codigo'] === 400 && str_contains($r['cuerpo'], 'INVALID_ARGUMENT'))) {
        ejecutar('DELETE FROM dispositivos WHERE token=?', [$t['token']]);
      } elseif ($r['codigo'] >= 400) {
        error_log('[CitaMed FCM] envío ' . $r['codigo'] . ': ' . $r['cuerpo']);
      }
    }
  } catch (Throwable $e) {
    error_log('[CitaMed FCM] ' . $e->getMessage());
  }
}
