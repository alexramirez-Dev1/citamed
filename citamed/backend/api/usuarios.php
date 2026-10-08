<?php
// Solo administrador. GET: todos los usuarios. PUT ?id=: activar / desactivar.
require '../config.php';
$admin = usuarioActual([ROL_ADMIN]);
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
  $filas = consulta('SELECT u.id, u.nombre, u.email, u.estado, r.nombre AS rol FROM usuarios u JOIN roles r ON r.id=u.rol_id ORDER BY u.rol_id DESC, u.nombre');
  foreach ($filas as &$f) $f['id'] = (int)$f['id'];
  responder($filas);
}
if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
  $id = (int)($_GET['id'] ?? 0);
  $estado = texto(entrada(), 'estado', 10);
  if (!in_array($estado, ['Activo', 'Inactivo'], true)) responder(['error' => 'Estado inválido'], 422);
  if ($id === (int)$admin['id']) responder(['error' => 'No puedes desactivar tu propia cuenta'], 409);
  if (!fila('SELECT id FROM usuarios WHERE id=?', [$id])) responder(['error' => 'Usuario no encontrado'], 404);
  ejecutar('UPDATE usuarios SET estado=? WHERE id=?', [$estado, $id]);
  // Al desactivar se cierran sus sesiones abiertas de inmediato.
  if ($estado === 'Inactivo') cerrarSesionesDe($id);
  responder(['ok' => true]);
}
responder(['error' => 'Método no permitido'], 405);
