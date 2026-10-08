import '../core/json_util.dart';

/// Ficha clínica que el médico llena al atender una cita.
class HistorialClinico {
  final int id;
  final int citaId;
  final int pacienteId;
  final String paciente;
  final int medicoId;
  final String medico;
  final String especialidad;
  final DateTime fecha;
  final String hora; // "HH:MM"
  final String motivo;
  final String diagnostico;
  final String tratamiento;
  final String notas;
  final DateTime fechaRegistro;

  const HistorialClinico({
    required this.id,
    required this.citaId,
    required this.pacienteId,
    required this.paciente,
    required this.medicoId,
    required this.medico,
    required this.especialidad,
    required this.fecha,
    required this.hora,
    required this.motivo,
    required this.diagnostico,
    required this.tratamiento,
    required this.notas,
    required this.fechaRegistro,
  });

  factory HistorialClinico.fromJson(Map<String, dynamic> j) => HistorialClinico(
        id: aInt(j['id']),
        citaId: aInt(j['cita_id']),
        pacienteId: aInt(j['paciente_id']),
        paciente: j['paciente'] ?? '',
        medicoId: aInt(j['medico_id']),
        medico: j['medico'] ?? '',
        especialidad: j['especialidad'] ?? '',
        fecha: DateTime.tryParse('${j['fecha']}') ?? DateTime(1970),
        hora: RegExp(r'^\d{2}:\d{2}').hasMatch('${j['hora']}') ? '${j['hora']}'.substring(0, 5) : '00:00',
        motivo: j['motivo'] ?? '',
        diagnostico: j['diagnostico'] ?? '',
        tratamiento: j['tratamiento'] ?? '',
        notas: j['notas'] ?? '',
        fechaRegistro:
            DateTime.tryParse((j['fecha_registro'] ?? '').toString().replaceFirst(' ', 'T')) ?? DateTime.now(),
      );
}
