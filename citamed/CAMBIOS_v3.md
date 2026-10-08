# CitaMed v3 · Corrección de errores y riesgos

Todas las correcciones se probaron contra un servidor y una base de datos de prueba.

## Errores corregidos
| # | Problema | Riesgo | Corrección |
|---|----------|--------|------------|
| 1 | Una fecha imposible (2026-02-31) se aceptaba y se convertía en otro día | Citas en fechas equivocadas | Validación real de calendario (`fechaValida`) |
| 2 | Se podía reservar para cualquier año futuro | Agenda llena de reservas falsas | Máximo 60 días de anticipación |
| 3 | Un paciente podía tener dos citas a la misma hora o varias con el mismo médico el mismo día | Turnos bloqueados | Reglas nuevas al reservar + límite de 5 citas pendientes |
| 4 | El médico podía marcar "Atendida" una cita futura y el paciente cancelar una que ya pasó | Historial falso | Validación según la hora de la cita |
| 5 | Un nombre largo hacía fallar la notificación (error 500 al reservar) | La reserva se guardaba pero la app mostraba error | Mensajes recortados al tamaño de la columna |
| 6 | Un cuerpo que no era JSON válido causaba error interno | Error 500 | Responde 400 "Formato de datos inválido" |
| 7 | El horario del médico se guardaba día por día sin transacción y aceptaba "sin días" | Horario a medias | Transacción + al menos un día |
| 8 | Al editar un médico se guardaban cambios aunque otro dato fuera inválido | Datos a medias | Se valida todo antes de guardar |
| 9 | Error de código en `config.php` (asignación sobrante en `db()`) | Código confuso | Limpiado |
| 10 | Los acentos podían importarse mal desde el archivo SQL | Textos como "CardiologÃ­a" | `SET NAMES utf8mb4` al inicio |

## Riesgos de seguridad reducidos
- **Fuerza bruta en el login:** 5 intentos fallidos por correo (o 20 por IP) bloquean 15 minutos (tabla `intentos_login`).
- **Tokens cifrados:** la base guarda solo el hash SHA-256 del token; si alguien lee la tabla no puede entrar.
- **Cuentas desactivadas:** al desactivar a un usuario o médico se cierran sus sesiones al instante.
- **Contraseñas:** 8 a 72 caracteres con letras y números (servidor y app usan la misma regla).
- **Google:** además del destinatario se verifican el emisor y la expiración del token.
- **Límites de longitud** en todos los textos, teléfono validado y cabeceras `nosniff` / `no-store`.
- **Errores internos** se registran en el log del servidor y nunca se muestran al usuario.

## App Flutter
- Validación de contraseña y teléfono igual a la del servidor.
- Nueva prueba unitaria `test/validar_test.dart` (4 pruebas).

## Cómo actualizar
- Base nueva: importar `database/citamed.sql`.
- Base existente: ejecutar `database/actualizar_v3.sql` (todos deben volver a iniciar sesión).
- Copiar `backend/` y `flutter/lib`, `flutter/test` encima de la versión anterior.
