-- CitaMed v4 · Historial clínico (ejecutar en phpMyAdmin sobre la base citamed)
USE citamed;

-- Una entrada por cita: el médico la llena al atender al paciente.
CREATE TABLE IF NOT EXISTS historial_clinico (
  id INT AUTO_INCREMENT PRIMARY KEY,
  cita_id INT NOT NULL UNIQUE,               -- una sola ficha por cita
  paciente_id INT NOT NULL,
  medico_id INT NOT NULL,
  motivo VARCHAR(255) NOT NULL DEFAULT '',
  diagnostico TEXT NOT NULL,
  tratamiento TEXT NULL,
  notas TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (cita_id) REFERENCES citas(id) ON DELETE CASCADE,
  FOREIGN KEY (paciente_id) REFERENCES usuarios(id) ON DELETE CASCADE,
  FOREIGN KEY (medico_id) REFERENCES medicos(id) ON DELETE CASCADE,
  INDEX idx_historial_paciente (paciente_id),
  INDEX idx_historial_medico (medico_id)
);
