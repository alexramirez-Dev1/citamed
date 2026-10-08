import '../core/json_util.dart';

class Medico {
  final int id;
  final String nombre;
  final String email;
  final String? telefono;
  final String? dni;
  final bool activo;
  final int especialidadId;
  final String especialidad;
  final String cmp;
  final String? biografia;
  final double precioConsulta;
  final double calificacion;
  final int totalResenas;

  const Medico({
    required this.id,
    required this.nombre,
    required this.email,
    required this.activo,
    required this.especialidadId,
    required this.especialidad,
    required this.cmp,
    required this.precioConsulta,
    required this.calificacion,
    required this.totalResenas,
    this.telefono,
    this.dni,
    this.biografia,
  });

  factory Medico.fromJson(Map<String, dynamic> j) => Medico(
        id: aInt(j['id']),
        nombre: j['nombre'] ?? '',
        email: j['email'] ?? '',
        telefono: j['telefono'] as String?,
        dni: j['dni'] as String?,
        activo: (j['estado'] ?? 'Activo') == 'Activo',
        especialidadId: aInt(j['especialidad_id']),
        especialidad: j['especialidad'] ?? '',
        cmp: j['cmp'] ?? '',
        biografia: j['biografia'] as String?,
        precioConsulta: aDouble(j['precio_consulta']),
        calificacion: aDouble(j['calificacion']),
        totalResenas: aInt(j['total_resenas']),
      );
}
