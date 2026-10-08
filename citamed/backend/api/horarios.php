<?php
// Un solo horario (inicio/fin + almuerzo) aplicado a los días activos de la semana.
// GET ?medico_id=  |  PUT (el médico edita el suyo).
require '../config.php';
$u = usuarioActual();

function medicoDe(array $u): int {
  $m = fila('SELECT id FROM medicos WHERE usuario_id=?', [$u['id']]);
  if (!$m) responder(['error' => 'No eres médico'], 403);
  return (int)$m['id'];
}
function hhmm(?string $t): ?string { return $t ? substr($t, 0, 5) : null; }

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
  $medicoId = (int)($_GET['medico_id'] ?? 0) ?: medicoDe($u);
  $filas = consulta('SELECT * FROM horarios_atencion WHERE medico_id=? ORDER BY dia_semana', [$medicoId]);
  $base = $filas[0] ?? ['hora_inicio' => '08:00', 'hora_fin' => '17:00', 'almuerzo_inicio' => '12:00', 'almuerzo_fin' => '13:00'];
  responder([
    'hora_inicio' => hhmm($base['hora_inicio']), 'hora_fin' => hhmm($base['hora_fin']),
    'almuerzo_inicio' => hhmm($base['almuerzo_inicio']), 'almuerzo_fin' => hhmm($base['almuerzo_fin']),
    'dias' => array_values(array_map(fn($f) => (int)$f['dia_semana'], array_filter($filas, fn($f) => $f['activo']))),
  ]);
}

if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
  $medicoId = medicoDe($u);
  $d = entrada();
  $ini = texto($d, 'hora_inicio', 5); $fin = texto($d, 'hora_fin', 5);
  $ai = texto($d, 'almuerzo_inicio', 5); $af = texto($d, 'almuerzo_fin', 5);
  foreach ([$ini, $fin, $ai, $af] as $t) if (!preg_match('/^([01]\d|2[0-3]):[0-5]\d$/', $t)) responder(['error' => 'Hora inválida'], 422);
  if ($ini >= $fin) responder(['error' => 'La hora de inicio debe ser anterior al fin'], 422);
  if ($ai >= $af || $ai < $ini || $af > $fin) responder(['error' => 'El almuerzo debe estar dentro del horario de atención'], 422);
  $dias = array_values(array_unique(array_filter(array_map('intval', (array)($d['dias'] ?? [])), fn($x) => $x >= 1 && $x <= 7)));
  if (!$dias) responder(['error' => 'Elige al menos un día de atención'], 422);
  // Los 7 días se guardan juntos: si algo falla no queda un horario a medias.
  db()->beginTransaction();
  for ($dia = 1; $dia <= 7; $dia++) {
    ejecutar('INSERT INTO horarios_atencion (medico_id,dia_semana,hora_inicio,hora_fin,almuerzo_inicio,almuerzo_fin,activo)
              VALUES (?,?,?,?,?,?,?)
              ON DUPLICATE KEY UPDATE hora_inicio=VALUES(hora_inicio), hora_fin=VALUES(hora_fin),
              almuerzo_inicio=VALUES(almuerzo_inicio), almuerzo_fin=VALUES(almuerzo_fin), activo=VALUES(activo)',
      [$medicoId, $dia, $ini, $fin, $ai, $af, in_array($dia, $dias, true) ? 1 : 0]);
  }
  db()->commit();
  responder(['ok' => true]);
}
responder(['error' => 'Método no permitido'], 405);
