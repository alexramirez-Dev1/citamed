import '../models/cita.dart';
import '../models/horario.dart';
import '../services/recordatorio_service.dart';
import 'controlador_base.dart';

/// Citas de cualquier rol (el servidor filtra según quién pregunta) y reserva del paciente.
class CitasController extends ControladorBase {
  // Cada combinación vista+estado se guarda aparte para que las pestañas no se pisen.
  final Map<String, List<Cita>> _listas = {};
  final Map<String, ({String? vista, String? estado})> _consultas = {};
  final Set<String> _cargando = {};
  final Map<String, String> _errores = {};

  static String claveDe(String? vista, String? estado) => '${vista ?? 'todas'}|${estado ?? 'todos'}';

  List<Cita> lista({String? vista, String? estado}) => _listas[claveDe(vista, estado)] ?? const [];
  bool cargando({String? vista, String? estado}) => _cargando.contains(claveDe(vista, estado));
  String? error({String? vista, String? estado}) => _errores[claveDe(vista, estado)];

  Future<void> cargar({String? vista, String? estado, bool programarRecordatorios = false}) async {
    final clave = claveDe(vista, estado);
    _consultas[clave] = (vista: vista, estado: estado);
    _cargando.add(clave);
    _errores.remove(clave);
    avisar();

    final fallo = await intentar(() async {
      final query = {if (vista != null) 'vista': vista, if (estado != null) 'estado': estado};
      final r = await api.get('citas.php', query: query.isEmpty ? null : query);
      _listas[clave] = comoLista(r).map(Cita.fromJson).toList();
    });
    if (fallo != null) _errores[clave] = fallo;
    _cargando.remove(clave);
    avisar();

    if (programarRecordatorios && fallo == null) {
      await RecordatorioService.instancia.sincronizar(_listas[clave] ?? const []);
    }
  }

  Future<void> _recargarTodo() async {
    for (final consulta in _consultas.values.toList()) {
      await cargar(vista: consulta.vista, estado: consulta.estado);
    }
  }

  // ----- Reserva -----

  List<SlotHorario> slots = [];
  bool cargandoSlots = false;
  String? errorSlots;
  Cita? ultimaReserva;

  Future<void> cargarSlots(int medicoId, String fechaSql) async {
    cargandoSlots = true;
    errorSlots = null;
    slots = [];
    avisar();
    errorSlots = await intentar(() async {
      final r = await api.get('disponibilidad.php', query: {'medico_id': '$medicoId', 'fecha': fechaSql});
      slots = comoLista(r).map(SlotHorario.fromJson).toList();
    });
    cargandoSlots = false;
    avisar();
  }

  Future<String?> reservar({required int medicoId, required String fechaSql, required String hora}) async {
    final fallo = await intentar(() async {
      final r = await api.post('citas.php', {'medico_id': medicoId, 'fecha': fechaSql, 'hora': hora});
      ultimaReserva = Cita.fromJson(Map<String, dynamic>.from(r as Map));
    });
    if (fallo == null && ultimaReserva != null) {
      await RecordatorioService.instancia.programar(ultimaReserva!);
      await _recargarTodo();
    }
    return fallo;
  }

  Future<String?> cambiarEstado(Cita cita, EstadoCita nuevo) async {
    final fallo = await intentar(() => api.put('citas.php', {'estado': nuevo.etiqueta}, query: {'id': '${cita.id}'}));
    if (fallo == null) {
      if (nuevo == EstadoCita.cancelada || nuevo == EstadoCita.atendida) {
        await RecordatorioService.instancia.cancelar(cita.id);
      }
      await _recargarTodo();
    }
    return fallo;
  }
}
