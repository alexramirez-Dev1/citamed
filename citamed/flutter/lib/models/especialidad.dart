import '../core/json_util.dart';

class Especialidad {
  final int id;
  final String nombre;
  final String descripcion;
  final String icono;
  final bool activo;

  const Especialidad({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.activo,
  });

  factory Especialidad.fromJson(Map<String, dynamic> j) => Especialidad(
        id: aInt(j['id']),
        nombre: j['nombre'] ?? '',
        descripcion: j['descripcion'] ?? '',
        icono: j['icono'] ?? 'medical_services',
        activo: aBool(j['activo']),
      );
}
