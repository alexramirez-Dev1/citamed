<?php
// Solo registra pacientes; médicos y admins los crea el administrador.
require '../config.php';
$d = entrada();
$nombre = texto($d, 'nombre', 100);
$email = strtolower(texto($d, 'email', 150));
$clave = $d['password'] ?? '';
$telefono = texto($d, 'telefono', 20);
$dni = texto($d, 'dni', 12);
if ($nombre === '' || mb_strlen($nombre) > 100) responder(['error' => 'Nombre inválido'], 422);
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) responder(['error' => 'Correo inválido'], 422);
if (!is_string($clave)) $clave = '';
if ($e = claveSegura($clave)) responder(['error' => $e], 422);
if ($telefono !== '' && !preg_match('/^\+?[\d\s-]{6,20}$/', $telefono)) responder(['error' => 'Teléfono inválido'], 422);
if ($dni !== '' && !preg_match('/^\d{8}$/', $dni)) responder(['error' => 'El DNI debe tener 8 dígitos'], 422);
if (fila('SELECT id FROM usuarios WHERE email=?', [$email])) responder(['error' => 'Ese correo ya está registrado'], 409);
try {
  ejecutar('INSERT INTO usuarios (nombre,email,password_hash,telefono,dni,rol_id) VALUES (?,?,?,?,?,?)',
  [$nombre, $email, password_hash($clave, PASSWORD_DEFAULT), $telefono ?: null, $dni ?: null, ROL_PACIENTE]);
} catch (PDOException $e) {
  // Dos registros simultáneos con el mismo correo: el índice UNIQUE lo detiene.
  if ($e->getCode() === '23000') responder(['error' => 'Ese correo ya está registrado'], 409);
  throw $e;
}
$u = fila('SELECT * FROM usuarios WHERE id=?', [db()->lastInsertId()]);
abrirSesion($u);
