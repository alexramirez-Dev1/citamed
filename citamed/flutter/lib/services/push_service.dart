import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_client.dart';

/// Se ejecuta con la app cerrada o en segundo plano. Android/iOS muestran la notificación solos.
@pragma('vm:entry-point')
Future<void> manejarPushEnSegundoPlano(RemoteMessage mensaje) async {
  await Firebase.initializeApp();
}

/// Notificaciones push con Firebase Cloud Messaging: registra el teléfono en el servidor
/// y muestra los avisos (cita reservada, confirmada, cancelada...) aunque la app esté cerrada.
class PushService {
  PushService._();
  static final PushService instancia = PushService._();

  final _local = FlutterLocalNotificationsPlugin();
  bool _listo = false;
  String? _token;

  /// Al tocar una push se avisa a la app (por ejemplo, para recargar la bandeja).
  void Function()? alAbrirNotificacion;
  /// Al llegar una push con la app abierta (para refrescar la campana).
  void Function()? alRecibir;

  static const _canal = AndroidNotificationChannel(
    'avisos_citamed',
    'Avisos de CitaMed',
    description: 'Reservas, confirmaciones y cancelaciones de citas',
    importance: Importance.high,
  );

  Future<void> iniciar() async {
    if (_listo || kIsWeb) return;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase no configurado, push desactivadas: $e');
      return;
    }
    FirebaseMessaging.onBackgroundMessage(manejarPushEnSegundoPlano);

    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_canal);
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

    // Con la app abierta Android no muestra la push solo: la mostramos como notificación local.
    FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      alRecibir?.call();
      if (n == null || !Platform.isAndroid) return;
      _local.show(
        m.hashCode,
        n.title,
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(_canal.id, _canal.name,
              channelDescription: _canal.description, importance: Importance.high, priority: Priority.high),
        ),
      );
    });
    FirebaseMessaging.onMessageOpenedApp.listen((_) => alAbrirNotificacion?.call());
    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      _token = t;
      _enviarAlServidor(t);
    });
    _listo = true;
  }

  /// Llamar después de iniciar sesión: pide permiso y registra el token en el servidor.
  Future<void> registrarDispositivo() async {
    if (!_listo) return;
    try {
      final permiso = await FirebaseMessaging.instance.requestPermission();
      if (permiso.authorizationStatus == AuthorizationStatus.denied) return;
      _token = await FirebaseMessaging.instance.getToken();
      if (_token != null) await _enviarAlServidor(_token!);
      final inicial = await FirebaseMessaging.instance.getInitialMessage();
      if (inicial != null) alAbrirNotificacion?.call();
    } catch (e) {
      debugPrint('No se pudo registrar para push: $e');
    }
  }

  /// Llamar antes de cerrar sesión (aún con token válido) para que este teléfono deje de recibir avisos.
  Future<void> quitarDispositivo() async {
    if (!_listo || _token == null) return;
    try {
      await ApiClient.instancia.delete('dispositivos.php', cuerpo: {'token': _token});
    } catch (_) {}
  }

  Future<void> _enviarAlServidor(String token) async {
    if (!ApiClient.instancia.hayToken) return;
    try {
      await ApiClient.instancia.post('dispositivos.php', {
        'token': token,
        'plataforma': Platform.isIOS ? 'ios' : 'android',
      });
    } catch (e) {
      debugPrint('No se pudo guardar el token push: $e');
    }
  }
}
