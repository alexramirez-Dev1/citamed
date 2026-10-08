import '../models/notificacion.dart';
import 'controlador_base.dart';

/// Bandeja de avisos del servidor (nueva cita, cambios de estado...).
class NotificacionesController extends ControladorBase {
  List<Notificacion> items = [];
  bool cargando = false;
  String? error;

  int get sinLeer => items.where((n) => !n.leida).length;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    avisar();
    error = await intentar(() async {
      items = comoLista(await api.get('notificaciones.php')).map(Notificacion.fromJson).toList();
    });
    cargando = false;
    avisar();
  }

  Future<void> marcarTodasLeidas() async {
    final fallo = await intentar(() => api.put('notificaciones.php', {}));
    if (fallo == null) await cargar();
  }
}
