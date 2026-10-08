import '../core/json_util.dart';

/// Fila de la lista de usuarios del administrador.
class UsuarioResumen {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final bool activo;
  const UsuarioResumen({required this.id, required this.nombre, required this.email, required this.rol, required this.activo});

  factory UsuarioResumen.fromJson(Map<String, dynamic> j) => UsuarioResumen(
        id: aInt(j['id']),
        nombre: j['nombre'] ?? '',
        email: j['email'] ?? '',
        rol: j['rol'] ?? '',
        activo: (j['estado'] ?? 'Activo') == 'Activo',
      );
}
