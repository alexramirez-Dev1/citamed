<?php
// GET ?vista=hoy|proximas|historial&estado=  |  POST (paciente reserva)  |  PUT ?id= (cambia estado)
require '../config.php';
require '../slots.php';
$u = usuarioActual();
$rol = (int)$u['rol_id'];
$metodo = $_SERVER['REQUEST_METHOD'];
const DIAS_MAX_RESERVA = 60;
const MAX_CITAS_ACTIVAS = 5;

const SQL_CITAS = "SELECT c.id, c.paciente_id, up.nombre AS paciente, c.medico_id, um.nombre AS medico,
    e.nombre AS especialidad, e.icono, m.cmp, c.fecha_cita AS fecha,
    TIME_FORMAT(c.hora_cita,'%H:%i') AS hora, c.estado
  FROM citas c
  JOIN usuarios up ON up.id = c.paciente_id
  JOIN medicos m ON m.id = c.medico_id
  JOIN usuarios um ON um.id = m.usuario_id
  JOIN especialidades e ON e.id = m.especialidad_id";

function miMedicoId(array $u): ?int {
  $m = fila('SELECT id FROM medicos WHERE usuario_id=?', [$u['id']]);
  return $m ? (int)$m['id'] : null;
}

if ($metodo === 'GET') {
  $where = []; $params = [];
  if ($rol === ROL_PACIENTE) { $where[] = 'c.paciente_id=?'; $params[] = $u['id']; }
  if ($rol === ROL_MEDICO) { $where[] = 'c.medico_id=?'; $params[] = miMedicoId($u) ?? 0; }

  $inicioCita = "TIMESTAMP(c.fecha_cita, c.hora_cita)";
  switch ($_GET['vista'] ?? '') {
    case 'hoy':
      $where[] = 'c.fecha_cita = CURDATE()'; break;
    case 'proximas':
      // El médico ya tiene su pestaña "Hoy"; el paciente ve todo lo que aún no ocurrió.
      $where[] = "c.estado IN ('Pendiente','Confirmada')";
      $where[] = $rol === ROL_MEDICO ? 'c.fecha_cita > CURDATE()' : "$inicioCita >= NOW()"; break;
    case 'historial':
      $where[] = "(c.estado IN ('Atendida','Cancelada') OR $inicioCita < NOW())"; break;
  }
  if (in_array($_GET['estado'] ?? '', ['Pendiente', 'Confirmada', 'Atendida', 'Cancelada'], true)) {
    $where[] = 'c.estado=?'; $params[] = $_GET['estado'];
  }
  $sql = SQL_CITAS . ($where ? ' WHERE ' . implode(' AND ', $where) : '') . ' ORDER BY c.fecha_cita, c.hora_cita';
  $filas = consulta($sql, $params);
  foreach ($filas as &$f) { $f['id'] = (int)$f['id']; $f['paciente_id'] = (int)$f['paciente_id']; $f['medico_id'] = (int)$f['medico_id']; }
  responder($filas);
}

if ($metodo === 'POST') {
  if ($rol !== ROL_PACIENTE) responder(['error' => 'Solo los pacientes reservan citas'], 403);
  $d = entrada();
  $medicoId = (int)($d['medico_id'] ?? 0);
  $fecha = texto($d, 'fecha', 10);
  $hora = texto($d, 'hora', 5);
  if (!$medicoId || !fechaValida($fecha) || !preg_match('/^([01]\d|2[0-3]):[0-5]\d$/', $hora)) {
    responder(['error' => 'Datos de la cita inválidos'], 422);
  }
  if ($fecha > date('Y-m-d', strtotime('+' . DIAS_MAX_RESERVA . ' days'))) {
    responder(['error' => 'Solo se puede reservar hasta ' . DIAS_MAX_RESERVA . ' días de anticipación'], 422);
  }
  // Reglas del negocio: no tener dos citas a la misma hora ni dos con el mismo médico el mismo día.
  if (fila("SELECT id FROM citas WHERE paciente_id=? AND fecha_cita=? AND hora_cita=? AND estado<>'Cancelada'", [$u['id'], $fecha, $hora])) {
    responder(['error' => 'Ya tienes otra cita a esa misma hora'], 409);
  }
  if (fila("SELECT id FROM citas WHERE paciente_id=? AND medico_id=? AND fecha_cita=? AND estado<>'Cancelada'", [$u['id'], $medicoId, $fecha])) {
    responder(['error' => 'Ya tienes una cita con este médico ese día'], 409);
  }
  $activas = fila("SELECT COUNT(*) AS n FROM citas WHERE paciente_id=? AND estado IN ('Pendiente','Confirmada') AND TIMESTAMP(fecha_cita,hora_cita) >= NOW()", [$u['id']]);
  if ((int)$activas['n'] >= MAX_CITAS_ACTIVAS) {
    responder(['error' => 'Tienes ' . MAX_CITAS_ACTIVAS . ' citas pendientes; cancela o asiste a una antes de reservar otra'], 409);
  }
  $m = fila("SELECT m.usuario_id FROM medicos m JOIN usuarios u ON u.id=m.usuario_id WHERE m.id=? AND u.estado='Activo'", [$medicoId]);
  if (!$m) responder(['error' => 'El médico no está disponible'], 404);

  $libre = array_filter(slotsDelDia($medicoId, $fecha), fn($s) => $s['hora'] === $hora && $s['estado'] === 'libre');
  if (!$libre) responder(['error' => 'Ese horario ya no está disponible'], 409);

  try {
    ejecutar('INSERT INTO citas (paciente_id, medico_id, fecha_cita, hora_cita) VALUES (?,?,?,?)', [$u['id'], $medicoId, $fecha, $hora]);
  } catch (PDOException $e) {
    if ($e->getCode() === '23000') responder(['error' => 'Ese horario acaba de ser reservado por otra persona'], 409);
    error_log('[CitaMed] ' . $e->getMessage());
    responder(['error' => 'No se pudo registrar la cita'], 500);
  }
  $id = (int)db()->lastInsertId();
  notificar((int)$m['usuario_id'], 'Nueva cita', "{$u['nombre']} reservó para el $fecha a las $hora.");
  responder(fila(SQL_CITAS . ' WHERE c.id=?', [$id]), 201);
}

if ($metodo === 'PUT') {
  $id = (int)($_GET['id'] ?? 0);
  $nuevo = texto(entrada(), 'estado', 12);
  $cita = fila(SQL_CITAS . ' WHERE c.id=?', [$id]);
  if (!$cita) responder(['error' => 'Cita no encontrada'], 404);

  $permitidos = match ($rol) {
    ROL_PACIENTE => (int)$cita['paciente_id'] === (int)$u['id'] ? ['Cancelada'] : [],
    ROL_MEDICO => (int)$cita['medico_id'] === miMedicoId($u) ? ['Confirmada', 'Atendida', 'Cancelada'] : [],
    default => ['Pendiente', 'Confirmada', 'Atendida', 'Cancelada'],
  };
  if (!in_array($nuevo, $permitidos, true)) responder(['error' => 'No puedes cambiar la cita a ese estado'], 403);
  if (in_array($cita['estado'], ['Atendida', 'Cancelada'], true) && $rol !== ROL_ADMIN) {
    responder(['error' => 'Esta cita ya está cerrada'], 409);
  }
  if ($nuevo === $cita['estado']) responder(['error' => "La cita ya figura como $nuevo"], 409);
  $inicio = strtotime("{$cita['fecha']} {$cita['hora']}");
  // No se puede marcar como atendida una cita que todavía no empieza.
  if ($nuevo === 'Atendida' && $inicio > time()) responder(['error' => 'Solo puedes marcarla como atendida desde la hora de la cita'], 409);
  // El paciente no puede cancelar una cita que ya pasó (queda en el historial tal cual).
  if ($rol === ROL_PACIENTE && $inicio <= time()) responder(['error' => 'Esta cita ya pasó y no se puede cancelar'], 409);
  if ($nuevo === 'Confirmada' && $inicio <= time() && $rol !== ROL_ADMIN) responder(['error' => 'No se puede confirmar una cita pasada'], 409);
  try {
    ejecutar('UPDATE citas SET estado=? WHERE id=?', [$nuevo, $id]);
  } catch (PDOException $e) {
    // Reactivar una cita cancelada cuyo horario ya tomó otro paciente.
    if ($e->getCode() === '23000') responder(['error' => 'Ese horario ya está ocupado por otra cita'], 409);
    throw $e;
  }

  if ($rol === ROL_PACIENTE) {
    $med = fila('SELECT usuario_id FROM medicos WHERE id=?', [$cita['medico_id']]);
    notificar((int)$med['usuario_id'], 'Cita cancelada', "{$cita['paciente']} canceló su cita del {$cita['fecha']} a las {$cita['hora']}.");
  } else {
    notificar((int)$cita['paciente_id'], "Cita $nuevo", "Tu cita con {$cita['medico']} del {$cita['fecha']} a las {$cita['hora']} figura como $nuevo.");
  }
  responder(['ok' => true]);
}
responder(['error' => 'Método no permitido'], 405);
