# CitaMed v4 · Historial clínico

## Qué se agregó

- **Base de datos** (`database/actualizar_v4.sql`): tabla `historial_clinico`, una ficha por cita
  (motivo, diagnóstico, tratamiento y notas).
- **Servidor** (`backend/api/historial.php`):
  - `GET` devuelve el historial según el rol: el paciente ve el suyo y el médico el de sus pacientes.
    Con `?cita_id=` devuelve la ficha de una cita; con `?paciente_id=` el médico filtra por paciente.
  - `POST` (solo médico): crea o actualiza la ficha de una cita suya confirmada o atendida.
    Si la cita estaba confirmada, pasa automáticamente a **Atendida** y el paciente recibe una
    notificación (campana y push).
- **App Flutter**:
  - `models/historial_clinico.dart` y `controllers/historial_controller.dart` (registrado en `main.dart`).
  - `views/medico/historial_form_view.dart`: formulario del médico. Se abre desde el detalle de una
    cita confirmada o atendida (botón "Ficha clínica" en la hoja de acciones). Si la cita ya tiene
    ficha, se precarga para editarla.
  - `views/compartido/historial_view.dart`: lista y detalle de fichas. Sirve para ambos roles.
  - Entradas nuevas: "Mi historial" en el menú del paciente y "Historial clínico" en el panel del médico.

## Instalación

1. En phpMyAdmin, sobre la base `citamed`, ejecuta `database/actualizar_v4.sql`.
2. Sube `backend/api/historial.php` junto a los demás archivos de `api/`.
3. Compila la app Flutter como siempre.

No se tocaron tablas ni archivos anteriores; si no ejecutas el SQL, la app funciona igual que antes
pero las pantallas de historial mostrarán un error al cargar.
