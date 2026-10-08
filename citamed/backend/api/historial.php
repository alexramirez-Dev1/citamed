<?php
// GET: historial del usuario (paciente o médico; ?cita_id= una ficha, ?paciente_id= filtra).
// POST: el médico crea o actualiza la ficha de una de sus citas.
require '../config.php';
$u = usuarioActual();
$rol = (int)$u['rol_id'];

const SQL_HISTORIAL = "SELECT h.id, h.cita_id, h.paciente_id, up.nombre AS paciente, h.medico_id,
    um.nombre AS medico, e.nombre AS especialidad, c.fecha_cita AS fecha,
    TIME_FORMAT(c.hora_cita,'%H:%i') AS hora, h.motivo, h.diagnostico, h.tratamiento, h.notas,
    h.updated_at AS fecha_registro
  FROM historial_clinico h
  JOIN citas c ON c.id = h.cita_id
  JOIN usuarios up ON up.id = h.paciente_id
  JOIN medicos m ON m.id = h.medico_id
  JOIN usuarios um ON um.id = m.usuario_id
  JOIN especialidades e ON e.id = m.especialidad_id";

function miMedicoIdHist(array $u): ?int {
  $m = fila('SELECT id FROM medicos WHERE usuario_id=?', [$u['id']]);
  return $m ? (int)$m['id'] : null;
}

function enteros(array $filas): array {
  foreach ($filas as &$f) {
    $f['id'] = (int)$f['id'];
    $f['cita_id'] = (int)$f['cita_id'];
    $f['paciente_id'] = (int)$f['paciente_id'];
    $f['medico_id'] = (int)$f['medico_id'];
  }
  return $filas;
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
  $where = []; $params = [];
  if ($rol === ROL_PACIENTE) { $where[] = 'h.paciente_id=?'; $params[] = $u['id']; }
  if ($rol === ROL_MEDICO) { $where[] = 'h.medico_id=?'; $params[] = miMedicoIdHist($u) ?? 0; }

  $citaId = (int)($_GET['cita_id'] ?? 0);
  if ($citaId) {
    $where[] = 'h.cita_id=?'; $params[] = $citaId;
    $f = fila(SQL_HISTORIAL . ($where ? ' WHERE ' . implode(' AND ', $where) : ''), $params);
    if (!$f) responder(['error' => 'Ficha no encontrada'], 404);
    responder(enteros([$f])[0]);
  }
  $pacienteId = (int)($_GET['paciente_id'] ?? 0);
  if ($pacienteId && $rol !== ROL_PACIENTE) { $where[] = 'h.paciente_id=?'; $params[] = $pacienteId; }

  $sql = SQL_HISTORIAL . ($where ? ' WHERE ' . implode(' AND ', $where) : '') . ' ORDER BY c.fecha_cita DESC, c.hora_cita DESC';
  responder(enteros(consulta($sql, $params)));
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  if ($rol !== ROL_MEDICO) responder(['error' => 'Solo el médico registra el historial clínico'], 403);
  $medicoId = miMedicoIdHist($u);
  if (!$medicoId) responder(['error' => 'Tu cuenta no tiene ficha de médico'], 403);

  $d = entrada();
  $citaId = (int)($d['cita_id'] ?? 0);
  $motivo = texto($d, 'motivo', 255);
  $diagnostico = texto($d, 'diagnostico', 5000);
  $tratamiento = texto($d, 'tratamiento', 5000);
  $notas = texto($d, 'notas', 5000);
  if (!$citaId || $diagnostico === '') responder(['error' => 'La cita y el diagnóstico son obligatorios'], 422);

  $cita = fila('SELECT paciente_id, medico_id, estado, fecha_cita, hora_cita FROM citas WHERE id=?', [$citaId]);
  if (!$cita || (int)$cita['medico_id'] !== $medicoId) responder(['error' => 'Cita no encontrada'], 404);
  if (!in_array($cita['estado'], ['Confirmada', 'Atendida'], true)) {
    responder(['error' => 'Solo puedes registrar el historial de citas confirmadas o atendidas'], 409);
  }

  ejecutar(
    'INSERT INTO historial_clinico (cita_id, paciente_id, medico_id, motivo, diagnostico, tratamiento, notas)
     VALUES (?,?,?,?,?,?,?)
     ON DUPLICATE KEY UPDATE motivo=VALUES(motivo), diagnostico=VALUES(diagnostico),
       tratamiento=VALUES(tratamiento), notas=VALUES(notas)',
    [$citaId, (int)$cita['paciente_id'], $medicoId, $motivo, $diagnostico, $tratamiento ?: null, $notas ?: null]
  );
  // Si la cita seguía confirmada, registrar la ficha también la marca como atendida.
  if ($cita['estado'] === 'Confirmada') ejecutar("UPDATE citas SET estado='Atendida' WHERE id=?", [$citaId]);

  notificar((int)$cita['paciente_id'], 'Historial actualizado',
    "{$u['nombre']} registró el diagnóstico de tu cita del {$cita['fecha_cita']}.");
  responder(['ok' => true], 201);
}
responder(['error' => 'Método no permitido'], 405);
