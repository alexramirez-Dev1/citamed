import '../models/usuario_resumen.dart';
import 'controlador_base.dart';

/// Lista de usuarios del sistema (solo administrador).
class UsuariosController extends ControladorBase {
  List<UsuarioResumen> usuarios = [];
  bool cargando = false;
  String? error;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    avisar();
    error = await intentar(() async {
      usuarios = comoLista(await api.get('usuarios.php')).map(UsuarioResumen.fromJson).toList();
    });
    cargando = false;
    avisar();
  }

  Future<String?> alternar(UsuarioResumen u) async {
    final fallo = await intentar(() => api.put('usuarios.php', {'estado': u.activo ? 'Inactivo' : 'Activo'}, query: {'id': '${u.id}'}));
    if (fallo == null) await cargar();
    return fallo;
  }
}
