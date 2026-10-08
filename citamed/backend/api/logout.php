<?php
require '../config.php';
usuarioActual();
preg_match('/Bearer\s+([a-f0-9]{64})/', $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '', $m);
ejecutar('DELETE FROM sesiones WHERE token=?', [hashToken($m[1])]);
responder(['ok' => true]);
