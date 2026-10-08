<?php
// GET: bandeja del usuario. PUT ?id= (o sin id = todas): marcar como leídas.
require '../config.php';
$u = usuarioActual();
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
  $filas = consulta('SELECT id, titulo, mensaje, fecha_envio, leido FROM notificaciones WHERE usuario_id=? ORDER BY fecha_envio DESC LIMIT 50', [$u['id']]);
  foreach ($filas as &$f) { $f['id'] = (int)$f['id']; $f['leido'] = (bool)$f['leido']; }
  responder($filas);
}
if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
  $id = (int)($_GET['id'] ?? 0);
  if ($id) ejecutar('UPDATE notificaciones SET leido=1 WHERE id=? AND usuario_id=?', [$id, $u['id']]);
  else ejecutar('UPDATE notificaciones SET leido=1 WHERE usuario_id=?', [$u['id']]);
  responder(['ok' => true]);
}
responder(['error' => 'Método no permitido'], 405);
