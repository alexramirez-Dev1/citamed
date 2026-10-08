import '../core/json_util.dart';

/// Un horario de atención aplicado a los días marcados (1 = lunes ... 7 = domingo).
class HorarioAtencion {
  final String horaInicio;
  final String horaFin;
  final String almuerzoInicio;
  final String almuerzoFin;
  final Set<int> dias;

  const HorarioAtencion({
    required this.horaInicio,
    required this.horaFin,
    required this.almuerzoInicio,
    required this.almuerzoFin,
    required this.dias,
  });

  factory HorarioAtencion.fromJson(Map<String, dynamic> j) => HorarioAtencion(
        horaInicio: j['hora_inicio'] ?? '08:00',
        horaFin: j['hora_fin'] ?? '17:00',
        almuerzoInicio: j['almuerzo_inicio'] ?? '12:00',
        almuerzoFin: j['almuerzo_fin'] ?? '13:00',
        dias: ((j['dias'] ?? []) as List).map(aInt).toSet(),
      );

  Map<String, dynamic> toJson() => {
        'hora_inicio': horaInicio,
        'hora_fin': horaFin,
        'almuerzo_inicio': almuerzoInicio,
        'almuerzo_fin': almuerzoFin,
        'dias': dias.toList()..sort(),
      };
}

enum EstadoSlot { libre, ocupado, almuerzo, pasado }

class SlotHorario {
  final String hora;
  final EstadoSlot estado;
  const SlotHorario(this.hora, this.estado);

  factory SlotHorario.fromJson(Map<String, dynamic> j) => SlotHorario(
        j['hora'] ?? '00:00',
        EstadoSlot.values.firstWhere((e) => e.name == j['estado'], orElse: () => EstadoSlot.ocupado),
      );
}
