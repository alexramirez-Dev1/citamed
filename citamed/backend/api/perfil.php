<?php
// GET: datos del usuario autenticado. PUT: edita nombre, teléfono y DNI.
require '../config.php';
$u = usuarioActual();
if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
  $d = entrada();
  $nombre = texto($d, 'nombre', 100, $u['nombre']);
  $telefono = texto($d, 'telefono', 20);
  $dni = texto($d, 'dni', 12);
  if ($telefono !== '' && !preg_match('/^\+?[\d\s-]{6,20}$/', $telefono)) responder(['error' => 'Teléfono inválido'], 422);
  if ($nombre === '') responder(['error' => 'El nombre es obligatorio'], 422);
  if ($dni !== '' && !preg_match('/^\d{8}$/', $dni)) responder(['error' => 'El DNI debe tener 8 dígitos'], 422);
  ejecutar('UPDATE usuarios SET nombre=?, telefono=?, dni=? WHERE id=?', [$nombre, $telefono ?: null, $dni ?: null, $u['id']]);
  $u = fila('SELECT * FROM usuarios WHERE id=?', [$u['id']]);
}
$salida = usuarioPublico($u);
if ($u['rol_id'] == ROL_MEDICO) {
  $m = fila('SELECT m.cmp, m.biografia, e.nombre AS especialidad FROM medicos m JOIN especialidades e ON e.id=m.especialidad_id WHERE m.usuario_id=?', [$u['id']]);
  $salida = array_merge($salida, $m ?? []);
}
responder(['usuario' => $salida]);
