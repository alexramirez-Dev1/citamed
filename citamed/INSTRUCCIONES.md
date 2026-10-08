# CitaMed · Instalación

Stack: **Flutter (Provider) + PHP + MySQL** (XAMPP), igual que tu proyecto `appcita_v2`.
Requiere Flutter 3.22 o superior (Dart 3.3+).

## 1. Base de datos
1. Enciende Apache y MySQL en XAMPP.
2. phpMyAdmin → **Importar** → `database/citamed.sql`.

## 2. Backend
1. Copia `backend/` a `C:\xampp\htdocs\citamed\` (incluye el archivo oculto `.htaccess`).
2. Abre **una sola vez** `http://localhost/citamed/crear_datos_demo.php` y luego **bórralo**.
   Crea estos usuarios (clave de todos: `Demo12345`):
   - Admin: `admin@citamed.com`
   - Médicos: `juan@demo.com`, `maria@demo.com`, `luis@demo.com`, `carlos@demo.com`, `ana@demo.com`
   - Paciente: `paciente@demo.com`

## 3. Google Sign-In
1. En Google Cloud Console crea un **ID de cliente OAuth tipo Web** y otro **tipo Android** (paquete + SHA-1 de tu keystore; en debug: `cd android && ./gradlew signingReport`).
2. Pega el ID **Web** en `backend/config.php` (`GOOGLE_CLIENT_ID`) y al ejecutar la app:
   `--dart-define=GOOGLE_CLIENT_ID=TU_ID_WEB.apps.googleusercontent.com`
3. iOS: agrega el ID de cliente iOS y el esquema inverso en `Info.plist` (guía de `google_sign_in`).

## 4. Flutter
1. Crea el proyecto: `flutter create --org com.tuorg citamed`
2. Copia por encima `flutter/lib/`, `flutter/assets/`, `flutter/pubspec.yaml` y `flutter/analysis_options.yaml`.
3. `flutter pub get`
4. Ícono de la app: `dart run flutter_launcher_icons` (usa `assets/icon/icon.png`; puedes reemplazarlo por tu logo).
5. **Android** (`android/app/src/main/AndroidManifest.xml`), dentro de `<manifest>`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
   ```
   y en `<application ...>` agrega `android:usesCleartextTraffic="true"` (XAMPP usa http) más, dentro de `<application>`:
   ```xml
   <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
   <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
     <intent-filter>
       <action android:name="android.intent.action.BOOT_COMPLETED"/>
       <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
     </intent-filter>
   </receiver>
   ```
6. **Android** (`android/app/build.gradle`): en `compileOptions` agrega `coreLibraryDesugaringEnabled true` y en `dependencies` agrega
   `coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'` (en `build.gradle.kts`: `isCoreLibraryDesugaringEnabled = true` y `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")`).
7. Ejecutar:
   - Emulador Android: `flutter run`
   - Celular real: `flutter run --dart-define=API_URL=http://IP_DE_TU_PC/citamed/api`

## 5. Notificaciones push (Firebase)
Cada aviso que hoy aparece en la campana (cita reservada, confirmada, cancelada, etc.) ahora llega también como notificación al celular, aunque la app esté cerrada.

**Base de datos:** si ya tenías la base, importa `database/actualizar_push.sql` (crea la tabla `dispositivos`). Si importas `citamed.sql` desde cero ya viene incluida.

**Firebase:**
1. Entra a https://console.firebase.google.com → crea un proyecto → agrega una app **Android** con el mismo paquete de tu app (ej. `com.tuorg.citamed`).
2. Más fácil: instala FlutterFire y en la carpeta del proyecto Flutter ejecuta
   `dart pub global activate flutterfire_cli` y `flutterfire configure`.
   (O manual: descarga `google-services.json` a `android/app/` y agrega el plugin `com.google.gms.google-services` en Gradle; en iOS `GoogleService-Info.plist` en `ios/Runner/` y activa *Push Notifications* y *Background Modes → Remote notifications* en Xcode, y sube tu clave APNs en Firebase.)
3. `flutter pub get`

**Servidor (PHP):**
1. Firebase → ⚙ Configuración del proyecto → **Cuentas de servicio** → *Generar nueva clave privada*.
2. Guarda ese archivo como `backend/push/firebase-credenciales.json` (o define la variable de entorno `FIREBASE_CREDENCIALES` con su ruta). **No lo compartas ni lo subas a git.** La carpeta `push/` ya bloquea el acceso desde el navegador.
3. PHP necesita las extensiones `curl` y `openssl` activas (en XAMPP vienen activas).

Si falta el archivo de credenciales o Firebase no está configurado, la app sigue funcionando igual y solo se omiten las push.
Nota: el emulador de Android necesita una imagen **con Google Play** para recibir push.

## Cómo está organizado
- `lib/models` · `lib/services` (API, Google, recordatorios) · `lib/controllers` (Provider) · `lib/views` (auth, paciente, medico, admin, compartido) · `lib/widgets` · `lib/core` (tema, formatos, íconos).
- Cada rol tiene su color: paciente verde/menta, médico azul, admin púrpura (el tema cambia solo según el rol).
- Recordatorios: al reservar y al abrir la app se reprograman avisos locales **24 h y 1 h antes** de cada cita Pendiente/Confirmada; al cancelar o atender se eliminan.
- Seguridad: contraseñas con `password_hash`, token Bearer de 7 días, consultas preparadas (PDO) y permisos por rol en cada endpoint.

## Ajustes respecto a tu especificación
- `medicos` suma `calificacion` y `total_resenas` (la pantalla de médicos muestra estrellas) y `horarios_atencion` suma `almuerzo_inicio/almuerzo_fin` (para bloquear el almuerzo en la grilla). Hay además una tabla `sesiones` para los tokens.
- Sin foto de perfil: no hay columna para ella, así que se muestran avatares con iniciales.
- Citas en bloques de 30 min; el servidor valida que la hora siga libre antes de reservar (evita doble reserva).
- Las notificaciones push remotas (FCM) no están incluidas: los recordatorios son locales; la tabla `notificaciones` alimenta la bandeja interna (campana).

## 5. Despliegue en producción (mejoras aplicadas)
1. **Hosting PHP + MySQL** (Hostinger, cPanel, etc.): sube `backend/` a `public_html/citamed/` e importa `database/citamed.sql`.
2. Define variables de entorno (o edita los valores por defecto en `config.php`): `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`, `GOOGLE_CLIENT_ID`, `CORS_ORIGIN`.
3. Usa **HTTPS** y compila: `flutter build apk --release --dart-define=API_URL=https://tudominio.com/citamed/api --dart-define=GOOGLE_CLIENT_ID=...` (con HTTPS ya no necesitas `usesCleartextTraffic`).
4. Agrega el SHA-1 de tu **keystore de release** en Google Cloud, si no Google Sign-In falla en la APK final.
5. Borra `crear_datos_demo.php` en el servidor (además ahora está bloqueado fuera de localhost) y cambia la clave `Demo12345`.

Mejoras: credenciales fuera del código, errores internos ocultos, bloqueo de doble reserva simultánea en la base de datos, archivos internos protegidos y script demo bloqueado.

## 6. Pruebas unitarias e iOS
- Pruebas: `flutter test` (carpeta `test/`: modelos, conversión de datos, roles y formatos). Toma la captura del resultado para el informe (punto 4.7.5.1).
- iOS: `flutter create --platforms=ios .` genera la carpeta `ios/`. Para compilar (`flutter build ios`) se necesita una Mac con Xcode.
- Mejoras de esta versión: el mensaje de error de conexión ahora muestra la dirección del servidor (detecta rápido si la APK apunta mal), se distingue "servidor lento" de "sin conexión", y una cita con fecha u hora dañadas ya no cierra la app.

## 7. Versión 3
Ver `CAMBIOS_v3.md`. Si ya tenías la base creada, ejecuta `database/actualizar_v3.sql`.

## 8. Versión 4 · Historial clínico
Ver `CAMBIOS_v4.md`. Si ya tenías la base creada, ejecuta `database/actualizar_v4.sql` y sube `backend/api/historial.php`.
