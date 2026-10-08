<?php
require '../config.php';
require '../slots.php';
usuarioActual();
$medicoId = (int)($_GET['medico_id'] ?? 0);
$fecha = is_string($_GET['fecha'] ?? null) ? $_GET['fecha'] : '';
if (!$medicoId || !fechaValida($fecha)) responder(['error' => 'Parámetros inválidos'], 422);
responder(slotsDelDia($medicoId, $fecha));
