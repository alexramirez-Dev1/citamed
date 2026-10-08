<?php
// Bloqueo de seguridad: solo corre en local o con APP_DEBUG activo.
if (!getenv('APP_DEBUG') && !in_array($_SERVER['REMOTE_ADDR'] ?? '', ['127.0.0.1', '::1'], true)) { http_response_code(403); exit('Deshabilitado'); }
// Ejecutar UNA vez en el navegador (http://localhost/citamed/crear_datos_demo.php) y luego BORRAR este archivo.
require 'config.php';
$yaHayAdmin = fila('SELECT id FROM usuarios WHERE rol_id=?', [ROL_ADMIN]);
if ($yaHayAdmin) responder(['error' => 'Los datos demo ya fueron creados'], 409);

$clave = password_hash('Demo12345', PASSWORD_DEFAULT);
ejecutar('INSERT INTO usuarios (nombre,email,password_hash,rol_id) VALUES (?,?,?,?)', ['Administrador', 'admin@citamed.com', $clave, ROL_ADMIN]);

$medicos = [
  ['Dr. Juan Pérez', 'juan@demo.com', 2, '12345', 4.8, 120],
  ['Dra. María López', 'maria@demo.com', 2, '67090', 4.7, 98],
  ['Dr. Luis García', 'luis@demo.com', 2, '54321', 4.5, 76],
  ['Dr. Carlos Ruiz', 'carlos@demo.com', 4, '33410', 4.6, 54],
  ['Dra. Ana Torres', 'ana@demo.com', 1, '22871', 4.9, 143],
];
foreach ($medicos as [$nombre, $email, $espId, $cmp, $nota, $resenas]) {
  ejecutar('INSERT INTO usuarios (nombre,email,password_hash,rol_id,telefono,dni) VALUES (?,?,?,?,?,?)',
    [$nombre, $email, $clave, ROL_MEDICO, '999999999', '1234' . rand(1000, 9999)]);
  $uid = (int)db()->lastInsertId();
  ejecutar('INSERT INTO medicos (usuario_id,especialidad_id,cmp,precio_consulta,calificacion,total_resenas) VALUES (?,?,?,?,?,?)',
    [$uid, $espId, $cmp, 80, $nota, $resenas]);
  $mid = (int)db()->lastInsertId();
  for ($dia = 1; $dia <= 7; $dia++) {
    ejecutar('INSERT INTO horarios_atencion (medico_id,dia_semana,hora_inicio,hora_fin,almuerzo_inicio,almuerzo_fin,activo) VALUES (?,?,?,?,?,?,?)',
      [$mid, $dia, '08:00', '16:00', '12:00', '13:00', $dia <= 5 ? 1 : 0]);
  }
}
ejecutar('INSERT INTO usuarios (nombre,email,password_hash,rol_id) VALUES (?,?,?,?)', ['Carlos López', 'paciente@demo.com', $clave, ROL_PACIENTE]);
responder(['ok' => true, 'mensaje' => 'Listo. Admin: admin@citamed.com · Médicos: juan@demo.com, maria@demo.com... · Paciente: paciente@demo.com · Clave de todos: Demo12345. Borra este archivo.']);
