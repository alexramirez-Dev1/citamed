import '../core/json_util.dart';

enum EstadoCita {
  pendiente('Pendiente'),
  confirmada('Confirmada'),
  atendida('Atendida'),
  cancelada('Cancelada');

  final String etiqueta;
  const EstadoCita(this.etiqueta);

  static EstadoCita desde(String texto) =>
      EstadoCita.values.firstWhere((e) => e.etiqueta == texto, orElse: () => EstadoCita.pendiente);
}

class Cita {
  final int id;
  final int pacienteId;
  final String paciente;
  final int medicoId;
  final String medico;
  final String especialidad;
  final String icono;
  final String cmp;
  final DateTime fecha;
  final String hora; // "HH:MM"
  final EstadoCita estado;

  const Cita({
    required this.id,
    required this.pacienteId,
    required this.paciente,
    required this.medicoId,
    required this.medico,
    required this.especialidad,
    required this.icono,
    required this.cmp,
    required this.fecha,
    required this.hora,
    required this.estado,
  });

  factory Cita.fromJson(Map<String, dynamic> j) => Cita(
        id: aInt(j['id']),
        pacienteId: aInt(j['paciente_id']),
        paciente: j['paciente'] ?? '',
        medicoId: aInt(j['medico_id']),
        medico: j['medico'] ?? '',
        especialidad: j['especialidad'] ?? '',
        icono: j['icono'] ?? 'medical_services',
        cmp: j['cmp'] ?? '',
        fecha: DateTime.tryParse('${j['fecha']}') ?? DateTime(1970),
        hora: RegExp(r'^\d{2}:\d{2}').hasMatch('${j['hora']}') ? '${j['hora']}'.substring(0, 5) : '00:00',
        estado: EstadoCita.desde(j['estado'] ?? ''),
      );

  /// Fecha y hora de inicio como DateTime local, útil para programar recordatorios.
  DateTime get inicio {
    final partes = hora.split(':');
    return DateTime(fecha.year, fecha.month, fecha.day, int.parse(partes[0]), int.parse(partes[1]));
  }

  bool get esActiva => estado == EstadoCita.pendiente || estado == EstadoCita.confirmada;
}
