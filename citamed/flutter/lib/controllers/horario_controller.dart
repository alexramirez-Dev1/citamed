import '../models/horario.dart';
import 'controlador_base.dart';

/// Horario de atención del médico autenticado.
class HorarioController extends ControladorBase {
  HorarioAtencion? horario;
  bool cargando = false;
  String? error;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    avisar();
    error = await intentar(() async {
      final r = await api.get('horarios.php');
      horario = HorarioAtencion.fromJson(Map<String, dynamic>.from(r as Map));
    });
    cargando = false;
    avisar();
  }

  Future<String?> guardar(HorarioAtencion nuevo) async {
    final fallo = await intentar(() => api.put('horarios.php', nuevo.toJson()));
    if (fallo == null) {
      horario = nuevo;
      avisar();
    }
    return fallo;
  }
}
