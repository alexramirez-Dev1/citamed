<?php
// Genera la grilla de 30 min de un médico para una fecha: libre / ocupado / almuerzo / pasado.
function slotsDelDia(int $medicoId, string $fecha): array {
  if (!fechaValida($fecha)) return [];
  $ts = strtotime($fecha);
  $h = fila('SELECT * FROM horarios_atencion WHERE medico_id=? AND dia_semana=? AND activo=1', [$medicoId, (int)date('N', $ts)]);
  if (!$h) return [];

  $tomadas = array_column(consulta(
    "SELECT TIME_FORMAT(hora_cita,'%H:%i') AS h FROM citas WHERE medico_id=? AND fecha_cita=? AND estado <> 'Cancelada'",
    [$medicoId, $fecha]), 'h');

  $min = fn(string $t) => (int)substr($t, 0, 2) * 60 + (int)substr($t, 3, 2);
  $inicio = $min($h['hora_inicio']);
  $fin = $min($h['hora_fin']);
  $almIni = $h['almuerzo_inicio'] ? $min($h['almuerzo_inicio']) : null;
  $almFin = $h['almuerzo_fin'] ? $min($h['almuerzo_fin']) : null;
  $ahora = time();

  $slots = [];
  for ($m = $inicio; $m + 30 <= $fin; $m += 30) {
    $hora = sprintf('%02d:%02d', intdiv($m, 60), $m % 60);
    $estado = 'libre';
    if ($almIni !== null && $m >= $almIni && $m < $almFin) $estado = 'almuerzo';
    elseif (in_array($hora, $tomadas, true)) $estado = 'ocupado';
    elseif (strtotime("$fecha $hora") <= $ahora) $estado = 'pasado';
    $slots[] = ['hora' => $hora, 'estado' => $estado];
  }
  return $slots;
}
