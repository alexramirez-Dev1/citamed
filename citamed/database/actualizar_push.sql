-- Ejecutar si ya tienes la base citamed: agrega la tabla para notificaciones push (Firebase).
USE citamed;
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
