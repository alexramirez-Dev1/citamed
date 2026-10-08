import '../models/especialidad.dart';
import '../models/medico.dart';
import 'controlador_base.dart';

/// Especialidades y médicos: lectura para pacientes y CRUD para el administrador.
class CatalogoController extends ControladorBase {
  List<Especialidad> especialidades = [];
  bool cargandoEspecialidades = false;
  String? errorEspecialidades;

  List<Medico> medicos = [];
  bool cargandoMedicos = false;
  String? errorMedicos;

  Future<void> cargarEspecialidades() async {
    cargandoEspecialidades = true;
    errorEspecialidades = null;
    avisar();
    errorEspecialidades = await intentar(() async {
      final r = await api.get('especialidades.php');
      especialidades = comoLista(r).map(Especialidad.fromJson).toList();
    });
    cargandoEspecialidades = false;
    avisar();
  }

  Future<void> cargarMedicos({int? especialidadId}) async {
    cargandoMedicos = true;
    errorMedicos = null;
    avisar();
    errorMedicos = await intentar(() async {
      final r = await api.get('medicos.php',
          query: especialidadId == null ? null : {'especialidad_id': '$especialidadId'});
      medicos = comoLista(r).map(Medico.fromJson).toList();
    });
    cargandoMedicos = false;
    avisar();
  }

  // ----- Administración de especialidades -----

  Future<String?> guardarEspecialidad({
    int? id,
    required String nombre,
    required String descripcion,
    required String icono,
    bool activo = true,
  }) async {
    final cuerpo = {'nombre': nombre, 'descripcion': descripcion, 'icono': icono, 'activo': activo};
    final fallo = await intentar(() async {
      if (id == null) {
        await api.post('especialidades.php', cuerpo);
      } else {
        await api.put('especialidades.php', cuerpo, query: {'id': '$id'});
      }
    });
    if (fallo == null) await cargarEspecialidades();
    return fallo;
  }

  Future<String?> alternarEspecialidad(Especialidad e) => guardarEspecialidad(
        id: e.id,
        nombre: e.nombre,
        descripcion: e.descripcion,
        icono: e.icono,
        activo: !e.activo,
      );

  Future<String?> borrarEspecialidad(Especialidad e) async {
    final fallo = await intentar(() => api.delete('especialidades.php', query: {'id': '${e.id}'}));
    if (fallo == null) await cargarEspecialidades();
    return fallo;
  }

  // ----- Administración de médicos -----

  Future<String?> crearMedico(Map<String, dynamic> datos) async {
    final fallo = await intentar(() => api.post('medicos.php', datos));
    if (fallo == null) await cargarMedicos();
    return fallo;
  }

  Future<String?> alternarMedico(Medico m) async {
    final fallo = await intentar(() => api.put('medicos.php', {'estado': m.activo ? 'Inactivo' : 'Activo'}, query: {'id': '${m.id}'}));
    if (fallo == null) await cargarMedicos();
    return fallo;
  }
}
