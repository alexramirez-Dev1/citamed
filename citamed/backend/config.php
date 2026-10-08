<?php
// Configuración común: conexión PDO, respuestas JSON y validación del token Bearer.
header('Content-Type: application/json; charset=utf-8');
// En producción define CORS_ORIGIN (ej. https://tudominio.com). Las apps móviles no usan CORS.
header('Access-Control-Allow-Origin: ' . (getenv('CORS_ORIGIN') ?: '*'));
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('X-Content-Type-Options: nosniff');
header('Cache-Control: no-store');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

date_default_timezone_set('America/Lima');
require_once __DIR__ . '/push/fcm.php';

// No mostrar errores internos al usuario en producción; todo error responde JSON.
ini_set('display_errors', getenv('APP_DEBUG') ? '1' : '0');
set_exception_handler(function (Throwable $e) {
  error_log('[CitaMed] ' . $e->getMessage());
  http_response_code(500);
  echo json_encode(['error' => 'Error interno del servidor'], JSON_UNESCAPED_UNICODE);
  exit;
});

// Client ID de tipo "Web" creado en Google Cloud Console (el mismo que usa la app como serverClientId).
// Client ID de tipo "Web" creado en Google Cloud Console (el mismo que usa la app como serverClientId).
define('GOOGLE_CLIENT_ID', getenv('GOOGLE_CLIENT_ID') ?: '997980280803-fcgg2dqg1v85a0ifnrisotoseljig33h.apps.googleusercontent.com');

function db(): PDO {
  static $pdo = null;
  if ($pdo === null) {
    // Credenciales por variables de entorno en el hosting; valores por defecto = XAMPP local.
    $host = getenv('DB_HOST') ?: 'localhost';
    $name = getenv('DB_NAME') ?: 'citamed';
    $pdo = new PDO("mysql:host=$host;dbname=$name;charset=utf8mb4", getenv('DB_USER') ?: 'root', getenv('DB_PASS') ?: '', [
      PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
      PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
    $pdo->exec("SET time_zone = '-05:00'");
  }
  return $pdo;
}

function responder($datos, int $codigo = 200): void {
  http_response_code($codigo);
  echo json_encode($datos, JSON_UNESCAPED_UNICODE);
  exit;
}

// Cuerpo JSON de la petición. Si no es un objeto JSON válido responde 400 en lugar de fallar más adelante.
function entrada(): array {
  $crudo = file_get_contents('php://input');
  if ($crudo === '' || $crudo === false) return [];
  if (strlen($crudo) > 65536) responder(['error' => 'Petición demasiado grande'], 413);
  $d = json_decode($crudo, true);
  if (!is_array($d)) responder(['error' => 'Formato de datos inválido'], 400);
  return $d;
}

// Lee un texto del cuerpo, recortado, y valida su longitud máxima.
function texto(array $d, string $clave, int $max, string $porDefecto = ''): string {
  $v = $d[$clave] ?? $porDefecto;
  if (!is_string($v) && !is_numeric($v)) responder(['error' => "Campo $clave inválido"], 422);
  $v = trim((string)$v);
  if (mb_strlen($v) > $max) responder(['error' => "El campo $clave es demasiado largo (máx. $max)"], 422);
  return $v;
}

// Fecha real (rechaza 2026-02-31, que strtotime aceptaría como 3 de marzo).
function fechaValida(string $f): bool {
  return preg_match('/^(\d{4})-(\d{2})-(\d{2})$/', $f, $m) === 1 && checkdate((int)$m[2], (int)$m[3], (int)$m[1]);
}

function claveSegura(string $c): ?string {
  if (strlen($c) < 8) return 'La contraseña debe tener al menos 8 caracteres';
  if (strlen($c) > 72) return 'La contraseña no puede superar 72 caracteres';
  if (!preg_match('/[A-Za-z]/', $c) || !preg_match('/\d/', $c)) return 'La contraseña debe tener letras y números';
  return null;
}

// En la base solo se guarda el hash del token: si alguien lee la tabla no puede usar las sesiones.
function hashToken(string $t): string { return hash('sha256', $t); }

function cerrarSesionesDe(int $usuarioId): void {
  ejecutar('DELETE FROM sesiones WHERE usuario_id=?', [$usuarioId]);
}

function consulta(string $sql, array $params = []): array {
  $st = db()->prepare($sql);
  $st->execute($params);
  return $st->fetchAll();
}

function fila(string $sql, array $params = []): ?array {
  $st = db()->prepare($sql);
  $st->execute($params);
  $r = $st->fetch();
  return $r === false ? null : $r;
}

function ejecutar(string $sql, array $params = []): void {
  db()->prepare($sql)->execute($params);
}

// Crea la sesión de 7 días y arma la respuesta que consume la app tras login/registro/Google.
function abrirSesion(array $u): void {
  ejecutar('DELETE FROM sesiones WHERE expira_en < NOW()');
  $token = bin2hex(random_bytes(32));
  ejecutar('INSERT INTO sesiones (token, usuario_id, expira_en) VALUES (?,?,DATE_ADD(NOW(), INTERVAL 7 DAY))', [hashToken($token), $u['id']]);
  responder(['token' => $token, 'usuario' => usuarioPublico($u)]);
}

function usuarioPublico(array $u): array {
  $medico = $u['rol_id'] == ROL_MEDICO ? fila('SELECT id FROM medicos WHERE usuario_id=?', [$u['id']]) : null;
  return [
    'id' => (int)$u['id'],
    'nombre' => $u['nombre'],
    'email' => $u['email'],
    'telefono' => $u['telefono'] ?? null,
    'dni' => $u['dni'] ?? null,
    'rol_id' => (int)$u['rol_id'],
    'estado' => $u['estado'],
    'medico_id' => $medico ? (int)$medico['id'] : null,
  ];
}

// Valida "Authorization: Bearer xxx". Si se indica $roles, solo esos roles pasan.
function usuarioActual(array $roles = []): array {
  $h = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
  if (!preg_match('/Bearer\s+([a-f0-9]{64})/', $h, $m)) responder(['error' => 'No autenticado'], 401);
  $u = fila('SELECT u.* FROM sesiones s JOIN usuarios u ON u.id = s.usuario_id WHERE s.token=? AND s.expira_en > NOW()', [hashToken($m[1])]);
  if (!$u) responder(['error' => 'Sesión expirada'], 401);
  if ($u['estado'] !== 'Activo') responder(['error' => 'Cuenta desactivada'], 403);
  if ($roles && !in_array((int)$u['rol_id'], $roles, true)) responder(['error' => 'No tienes permiso para esta acción'], 403);
  return $u;
}

function notificar(int $usuarioId, string $titulo, string $mensaje): void {
  // Se recorta al tamaño de las columnas: un nombre largo ya no provoca error 500 al reservar.
  ejecutar('INSERT INTO notificaciones (usuario_id, titulo, mensaje) VALUES (?,?,?)',
    [$usuarioId, mb_substr($titulo, 0, 120), mb_substr($mensaje, 0, 255)]);
  // Además de la bandeja, avisa al teléfono con una notificación push (Firebase).
  enviarPush($usuarioId, mb_substr($titulo, 0, 120), mb_substr($mensaje, 0, 255));
}
