import '../models/historial_clinico.dart';
import 'controlador_base.dart';

/// Historial clínico: el servidor filtra según el rol (paciente ve el suyo, médico el de sus pacientes).
class HistorialController extends ControladorBase {
  List<HistorialClinico> items = [];
  bool cargando = false;
  String? error;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    avisar();
    error = await intentar(() async {
      items = comoLista(await api.get('historial.php')).map(HistorialClinico.fromJson).toList();
    });
    cargando = false;
    avisar();
  }

  /// Ficha de una cita concreta, o null si aún no se registró.
  Future<HistorialClinico?> deCita(int citaId) async {
    HistorialClinico? ficha;
    final fallo = await intentar(() async {
      final r = await api.get('historial.php', query: {'cita_id': '$citaId'});
      ficha = HistorialClinico.fromJson(Map<String, dynamic>.from(r as Map));
    });
    return fallo == null ? ficha : null;
  }

  /// El médico crea o actualiza la ficha de una cita suya.
  Future<String?> guardar({
    required int citaId,
    required String motivo,
    required String diagnostico,
    String tratamiento = '',
    String notas = '',
  }) async {
    final fallo = await intentar(() => api.post('historial.php', {
          'cita_id': citaId,
          'motivo': motivo,
          'diagnostico': diagnostico,
          'tratamiento': tratamiento,
          'notas': notas,
        }));
    if (fallo == null) await cargar();
    return fallo;
  }
}
