import '../core/json_util.dart';

class Notificacion {
  final int id;
  final String titulo;
  final String mensaje;
  final DateTime fecha;
  final bool leida;

  const Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.fecha,
    required this.leida,
  });

  factory Notificacion.fromJson(Map<String, dynamic> j) => Notificacion(
        id: aInt(j['id']),
        titulo: j['titulo'] ?? '',
        mensaje: j['mensaje'] ?? '',
        fecha: DateTime.tryParse((j['fecha_envio'] ?? '').toString().replaceFirst(' ', 'T')) ?? DateTime.now(),
        leida: aBool(j['leido']),
      );
}
