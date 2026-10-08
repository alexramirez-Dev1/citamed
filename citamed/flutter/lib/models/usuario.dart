import '../core/json_util.dart';

enum Rol {
  paciente, medico, admin;

  static Rol desdeId(int id) => switch (id) { 2 => Rol.medico, 3 => Rol.admin, _ => Rol.paciente };
  String get etiqueta => switch (this) { Rol.paciente => 'Paciente', Rol.medico => 'Médico', Rol.admin => 'Admin' };
}

class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String? telefono;
  final String? dni;
  final Rol rol;
  final bool activo;
  final int? medicoId;
  final String? cmp;
  final String? especialidad;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.telefono,
    this.dni,
    this.activo = true,
    this.medicoId,
    this.cmp,
    this.especialidad,
  });

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        id: aInt(j['id']),
        nombre: j['nombre'] ?? '',
        email: j['email'] ?? '',
        telefono: j['telefono'] as String?,
        dni: j['dni'] as String?,
        rol: Rol.desdeId(aInt(j['rol_id'])),
        activo: (j['estado'] ?? 'Activo') == 'Activo',
        medicoId: j['medico_id'] == null ? null : aInt(j['medico_id']),
        cmp: j['cmp'] as String?,
        especialidad: j['especialidad'] as String?,
      );
}
