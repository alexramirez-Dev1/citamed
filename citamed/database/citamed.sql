-- CitaMed · esquema MySQL (importar en phpMyAdmin)
SET NAMES utf8mb4;
CREATE DATABASE IF NOT EXISTS citamed CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE citamed;

CREATE TABLE roles (
  id TINYINT UNSIGNED PRIMARY KEY,
  nombre VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NULL,            -- NULL cuando la cuenta nace con Google
  google_id VARCHAR(64) NULL UNIQUE,
  telefono VARCHAR(20) NULL,
  dni VARCHAR(12) NULL,
  rol_id TINYINT UNSIGNED NOT NULL DEFAULT 1,
  estado ENUM('Activo','Inactivo') NOT NULL DEFAULT 'Activo',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (rol_id) REFERENCES roles(id),
  INDEX idx_usuarios_rol (rol_id)
);

CREATE TABLE sesiones (
  token CHAR(64) PRIMARY KEY,                 -- hash SHA-256 del token, nunca el token real
  usuario_id INT NOT NULL,
  expira_en DATETIME NOT NULL,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

CREATE TABLE especialidades (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  descripcion VARCHAR(255) NULL,
  icono VARCHAR(40) NOT NULL DEFAULT 'medical_services',
  activo TINYINT(1) NOT NULL DEFAULT 1
);

CREATE TABLE medicos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL UNIQUE,
  especialidad_id INT NOT NULL,
  cmp VARCHAR(12) NOT NULL UNIQUE,
  biografia TEXT NULL,
  precio_consulta DECIMAL(8,2) NOT NULL DEFAULT 0,
  calificacion DECIMAL(2,1) NOT NULL DEFAULT 0,
  total_resenas INT NOT NULL DEFAULT 0,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  FOREIGN KEY (especialidad_id) REFERENCES especialidades(id),
  INDEX idx_medicos_especialidad (especialidad_id)
);

CREATE TABLE horarios_atencion (
  id INT AUTO_INCREMENT PRIMARY KEY,
  medico_id INT NOT NULL,
  dia_semana TINYINT NOT NULL,                -- 1 = lunes ... 7 = domingo
  hora_inicio TIME NOT NULL,
  hora_fin TIME NOT NULL,
  almuerzo_inicio TIME NULL,
  almuerzo_fin TIME NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  UNIQUE KEY uq_medico_dia (medico_id, dia_semana),
  FOREIGN KEY (medico_id) REFERENCES medicos(id) ON DELETE CASCADE
);

CREATE TABLE citas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  paciente_id INT NOT NULL,
  medico_id INT NOT NULL,
  fecha_cita DATE NOT NULL,
  hora_cita TIME NOT NULL,
  estado ENUM('Pendiente','Confirmada','Atendida','Cancelada') NOT NULL DEFAULT 'Pendiente',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (paciente_id) REFERENCES usuarios(id),
  FOREIGN KEY (medico_id) REFERENCES medicos(id),
  -- Evita doble reserva aunque dos pacientes reserven al mismo tiempo (las canceladas no cuentan).
  slot_activo VARCHAR(40) AS (IF(estado <> 'Cancelada', CONCAT(medico_id,'|',fecha_cita,'|',hora_cita), NULL)) STORED,
  UNIQUE KEY uq_slot_activo (slot_activo),
  INDEX idx_citas_medico_fecha (medico_id, fecha_cita),
  INDEX idx_citas_paciente (paciente_id, fecha_cita)
);

CREATE TABLE notificaciones (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  titulo VARCHAR(120) NOT NULL,
  mensaje VARCHAR(255) NOT NULL,
  fecha_envio DATETIME DEFAULT CURRENT_TIMESTAMP,
  leido TINYINT(1) NOT NULL DEFAULT 0,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  INDEX idx_notif_usuario (usuario_id, leido)
);

-- Intentos de inicio de sesión fallidos (bloqueo temporal contra ataques de fuerza bruta).
CREATE TABLE intentos_login (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(150) NOT NULL,
  ip VARCHAR(45) NOT NULL,
  fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_intentos_email (email, fecha),
  INDEX idx_intentos_ip (ip, fecha)
);

INSERT INTO roles (id, nombre) VALUES (1,'Paciente'),(2,'Médico'),(3,'Admin');

INSERT INTO especialidades (nombre, descripcion, icono) VALUES
('Medicina General','Atención médica general','medical_services'),
('Cardiología','Enfermedades del corazón','favorite'),
('Pediatría','Atención para niños','child_care'),
('Dermatología','Enfermedades de la piel','spa'),
('Traumatología','Lesiones y huesos','healing'),
('Odontología','Salud bucal','sentiment_satisfied');
-- Admin y médicos de prueba: ejecutar backend/crear_datos_demo.php una sola vez.

CREATE TABLE IF NOT EXISTS dispositivos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario_id INT NOT NULL,
  token VARCHAR(255) NOT NULL,
  plataforma VARCHAR(20) NOT NULL DEFAULT 'android',
  actualizado DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_dispositivo_token (token),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  INDEX idx_dispositivo_usuario (usuario_id)
);
