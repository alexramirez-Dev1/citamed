<?php
// POST {token, plataforma}: registra el teléfono para recibir push. DELETE {token}: lo quita (al cerrar sesión).
require '../config.php';
$u = usuarioActual();
$d = entrada();
$token = texto($d, 'token', 255);
if ($token === '') responder(['error' => 'Falta el token del dispositivo'], 422);
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $plataforma = texto($d, 'plataforma', 20, 'android');
  // Un token pertenece a un solo usuario: si otro inició sesión en ese teléfono, se reasigna.
  ejecutar('INSERT INTO dispositivos (usuario_id, token, plataforma) VALUES (?,?,?)
            ON DUPLICATE KEY UPDATE usuario_id=VALUES(usuario_id), plataforma=VALUES(plataforma), actualizado=NOW()',
    [$u['id'], $token, $plataforma]);
  responder(['ok' => true]);
}
if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
  ejecutar('DELETE FROM dispositivos WHERE token=? AND usuario_id=?', [$token, $u['id']]);
  responder(['ok' => true]);
}
responder(['error' => 'Método no permitido'], 405);
