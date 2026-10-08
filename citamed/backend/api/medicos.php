<?php
// GET: lista (paciente ve solo activos). POST: admin crea médico + usuario. PUT: admin cambia estado/datos.
require '../config.php';
$u = usuarioActual();
$metodo = $_SERVER['REQUEST_METHOD'];

const SQL_MEDICOS = "SELECT m.id, m.usuario_id, u.nombre, u.email, u.telefono, u.dni, u.estado,
    m.especialidad_id, e.nombre AS especialidad, m.cmp, m.biografia, m.precio_consulta,
    m.calificacion, m.total_resenas
  FROM medicos m
  JOIN usuarios u ON u.id = m.usuario_id
  JOIN especialidades e ON e.id = m.especialidad_id";

function normalizarMedico(array $m): array {
  foreach (['id', 'usuario_id', 'especialidad_id', 'total_resenas'] as $k) $m[$k] = (int)$m[$k];
  $m['precio_consulta'] = (float)$m['precio_consulta'];
  $m['calificacion'] = (float)$m['calificacion'];
  return $m;
}

if ($metodo === 'GET') {
  $where = []; $params = [];
  if ((int)$u['rol_id'] !== ROL_ADMIN) $where[] = "u.estado='Activo'";
  if (!empty($_GET['especialidad_id'])) { $where[] = 'm.especialidad_id=?'; $params[] = (int)$_GET['especialidad_id']; }
  $sql = SQL_MEDICOS . ($where ? ' WHERE ' . implode(' AND ', $where) : '') . ' ORDER BY u.nombre';
  responder(array_map('normalizarMedico', consulta($sql, $params)));
}

usuarioActual([ROL_ADMIN]);
$d = entrada();

if ($metodo === 'POST') {
  $nombre = texto($d, 'nombre', 100);
  $email = strtolower(texto($d, 'email', 150));
  $clave = is_string($d['password'] ?? null) ? $d['password'] : '';
  $cmp = texto($d, 'cmp', 12);
  $telefono = texto($d, 'telefono', 20);
  $dni = texto($d, 'dni', 12);
  $bio = texto($d, 'biografia', 2000);
  $precio = (float)($d['precio_consulta'] ?? 0);
  $espId = (int)($d['especialidad_id'] ?? 0);
  if ($nombre === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) responder(['error' => 'Nombre o correo inválido'], 422);
  if ($e = claveSegura($clave)) responder(['error' => $e], 422);
  if ($dni !== '' && !preg_match('/^\d{8}$/', $dni)) responder(['error' => 'El DNI debe tener 8 dígitos'], 422);
  if ($precio < 0 || $precio > 9999) responder(['error' => 'Precio de consulta inválido'], 422);
  if (!preg_match('/^\d{4,8}$/', $cmp)) responder(['error' => 'CMP inválido (4 a 8 dígitos)'], 422);
  if (!fila('SELECT id FROM especialidades WHERE id=?', [$espId])) responder(['error' => 'Especialidad inválida'], 422);
  if (fila('SELECT id FROM usuarios WHERE email=?', [$email])) responder(['error' => 'Ese correo ya está registrado'], 409);
  if (fila('SELECT id FROM medicos WHERE cmp=?', [$cmp])) responder(['error' => 'Ese CMP ya existe'], 409);

  $pdo = db();
  $pdo->beginTransaction();
  try {
    ejecutar('INSERT INTO usuarios (nombre,email,password_hash,telefono,dni,rol_id) VALUES (?,?,?,?,?,?)',
      [$nombre, $email, password_hash($clave, PASSWORD_DEFAULT), $telefono ?: null, $dni ?: null, ROL_MEDICO]);
    $usuarioId = (int)$pdo->lastInsertId();
    ejecutar('INSERT INTO medicos (usuario_id,especialidad_id,cmp,biografia,precio_consulta) VALUES (?,?,?,?,?)',
      [$usuarioId, $espId, $cmp, $bio ?: null, $precio]);
    $medicoId = (int)$pdo->lastInsertId();
    for ($dia = 1; $dia <= 7; $dia++) {
      ejecutar('INSERT INTO horarios_atencion (medico_id,dia_semana,hora_inicio,hora_fin,almuerzo_inicio,almuerzo_fin,activo) VALUES (?,?,?,?,?,?,?)',
        [$medicoId, $dia, '08:00', '17:00', '12:00', '13:00', $dia <= 5 ? 1 : 0]);
    }
    $pdo->commit();
  } catch (Throwable $e) {
    $pdo->rollBack();
    error_log('[CitaMed] ' . $e->getMessage());
    responder(['error' => 'No se pudo registrar al médico'], 500);
  }
  responder(['ok' => true], 201);
}

if ($metodo === 'PUT') {
  $id = (int)($_GET['id'] ?? 0);
  $m = fila('SELECT * FROM medicos WHERE id=?', [$id]);
  if (!$m) responder(['error' => 'Médico no encontrado'], 404);
  // Se valida todo antes de guardar para no dejar cambios a medias.
  $estado = $d['estado'] ?? null;
  if ($estado !== null && !in_array($estado, ['Activo', 'Inactivo'], true)) responder(['error' => 'Estado inválido'], 422);
  $espId = (int)($d['especialidad_id'] ?? 0);
  if ($espId && !fila('SELECT id FROM especialidades WHERE id=?', [$espId])) responder(['error' => 'Especialidad inválida'], 422);
  if (isset($d['precio_consulta']) && (!is_numeric($d['precio_consulta']) || $d['precio_consulta'] < 0 || $d['precio_consulta'] > 9999)) {
    responder(['error' => 'Precio de consulta inválido'], 422);
  }
  if ($estado !== null) {
    ejecutar('UPDATE usuarios SET estado=? WHERE id=?', [$estado, $m['usuario_id']]);
    if ($estado === 'Inactivo') cerrarSesionesDe((int)$m['usuario_id']);
  }
  if ($espId) ejecutar('UPDATE medicos SET especialidad_id=? WHERE id=?', [$espId, $id]);
  if (isset($d['precio_consulta'])) ejecutar('UPDATE medicos SET precio_consulta=? WHERE id=?', [(float)$d['precio_consulta'], $id]);
  responder(['ok' => true]);
}
responder(['error' => 'Método no permitido'], 405);
