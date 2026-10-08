import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../core/formato.dart';
import '../models/cita.dart';

/// Recordatorios locales de citas: 24 horas y 1 hora antes de la consulta.
class RecordatorioService {
  RecordatorioService._();
  static final RecordatorioService instancia = RecordatorioService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _listo = false;

  static const _detalles = NotificationDetails(
    android: AndroidNotificationDetails(
      'recordatorios_citas',
      'Recordatorios de citas',
      channelDescription: 'Avisos antes de tu consulta médica',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> iniciar() async {
    if (_listo) return;
    tzdata.initializeTimeZones();
    const ajustes = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(ajustes);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _listo = true;
  }

  // Dos ids por cita: [id * 10 + 1] para 24 h y [id * 10 + 2] para 1 h.
  int _idDia(int citaId) => citaId * 10 + 1;
  int _idHora(int citaId) => citaId * 10 + 2;

  Future<void> programar(Cita cita) async {
    if (!_listo || !cita.esActiva) return;
    final recordatorios = <(int, DateTime, String)>[
      (_idDia(cita.id), cita.inicio.subtract(const Duration(hours: 24)), 'Mañana tienes una cita médica'),
      (_idHora(cita.id), cita.inicio.subtract(const Duration(hours: 1)), 'Tu cita es en 1 hora'),
    ];
    final ahora = DateTime.now();
    for (final (id, momento, titulo) in recordatorios) {
      if (!momento.isAfter(ahora)) continue;
      await _plugin.zonedSchedule(
        id,
        titulo,
        '${cita.medico} · ${cita.especialidad} · ${Formato.fechaCorta(cita.fecha)} a las ${cita.hora}',
        tz.TZDateTime.from(momento, tz.local),
        _detalles,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> cancelar(int citaId) async {
    if (!_listo) return;
    await _plugin.cancel(_idDia(citaId));
    await _plugin.cancel(_idHora(citaId));
  }

  /// Deja programados solo los recordatorios de las citas activas que recibe.
  Future<void> sincronizar(List<Cita> citas) async {
    if (!_listo) return;
    await _plugin.cancelAll();
    for (final cita in citas) {
      await programar(cita);
    }
  }

  Future<void> cancelarTodos() async {
    if (_listo) await _plugin.cancelAll();
  }
}
