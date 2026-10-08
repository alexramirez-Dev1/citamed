<?php
// GET: lista (el paciente solo ve activas). POST/PUT/DELETE: solo administrador.
require '../config.php';
$u = usuarioActual();
$metodo = $_SERVER['REQUEST_METHOD'];

if ($metodo === 'GET') {
  $todas = (int)$u['rol_id'] === ROL_ADMIN;
  $filas = consulta('SELECT id, nombre, descripcion, icono, activo FROM especialidades' . ($todas ? '' : ' WHERE activo=1') . ' ORDER BY nombre');
  foreach ($filas as &$f) { $f['id'] = (int)$f['id']; $f['activo'] = (bool)$f['activo']; }
  responder($filas);
}

usuarioActual([ROL_ADMIN]);
$d = entrada();
$id = (int)($_GET['id'] ?? 0);

if ($metodo === 'POST' || $metodo === 'PUT') {
  $nombre = texto($d, 'nombre', 100);
  if ($nombre === '') responder(['error' => 'Nombre inválido'], 422);
  $desc = texto($d, 'descripcion', 255);
  if ($metodo === 'PUT' && !fila('SELECT id FROM especialidades WHERE id=?', [$id])) responder(['error' => 'Especialidad no encontrada'], 404);
  $icono = preg_match('/^[a-z_]{3,40}$/', (string)($d['icono'] ?? '')) ? $d['icono'] : 'medical_services';
  $activo = isset($d['activo']) ? (int)(bool)$d['activo'] : 1;
  try {
    if ($metodo === 'POST') {
      ejecutar('INSERT INTO especialidades (nombre,descripcion,icono,activo) VALUES (?,?,?,?)', [$nombre, $desc, $icono, $activo]);
      responder(['ok' => true], 201);
    }
    ejecutar('UPDATE especialidades SET nombre=?, descripcion=?, icono=?, activo=? WHERE id=?', [$nombre, $desc, $icono, $activo, $id]);
    responder(['ok' => true]);
  } catch (PDOException $e) {
    if ($e->getCode() !== '23000') throw $e;
    responder(['error' => 'Ya existe una especialidad con ese nombre'], 409);
  }
}

if ($metodo === 'DELETE') {
  if (fila('SELECT id FROM medicos WHERE especialidad_id=? LIMIT 1', [$id])) {
    responder(['error' => 'Hay médicos en esta especialidad; desactívala en lugar de borrarla'], 409);
  }
  ejecutar('DELETE FROM especialidades WHERE id=?', [$id]);
  responder(['ok' => true]);
}
responder(['error' => 'Método no permitido'], 405);
