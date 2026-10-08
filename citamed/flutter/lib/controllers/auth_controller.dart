import '../models/usuario.dart';
import '../services/api_client.dart';
import '../services/google_auth_service.dart';
import '../services/push_service.dart';
import '../services/recordatorio_service.dart';
import 'controlador_base.dart';

class AuthController extends ControladorBase {
  AuthController({GoogleAuthService? google}) : _google = google ?? GoogleAuthService() {
    // Si el servidor dice "sesión expirada" en cualquier pantalla, volvemos al login.
    api.alExpirarSesion = () {
      usuario = null;
      avisar();
    };
  }

  final GoogleAuthService _google;

  Usuario? usuario;
  bool restaurando = true;
  bool cargando = false;
  String? error;

  bool get autenticado => usuario != null;

  Future<void> restaurarSesion() async {
    await api.cargarToken();
    if (api.hayToken) {
      try {
        await _cargarPerfil();
        PushService.instancia.registrarDispositivo();
      } on ApiException {
        usuario = null;
      }
    }
    restaurando = false;
    avisar();
  }

  Future<bool> iniciarSesion(String email, String password) => _conCarga(() async {
        final r = await api.post('login.php', {'email': email, 'password': password}, auth: false);
        await _abrir(r);
      });

  Future<bool> registrar({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
    String? dni,
  }) =>
      _conCarga(() async {
        final r = await api.post(
          'registro.php',
          {'nombre': nombre, 'email': email, 'password': password, 'telefono': telefono ?? '', 'dni': dni ?? ''},
          auth: false,
        );
        await _abrir(r);
      });

  Future<bool> entrarConGoogle() => _conCarga(() async {
        final idToken = await _google.obtenerIdToken();
        final r = await api.post('google.php', {'id_token': idToken}, auth: false);
        await _abrir(r);
      });

  Future<void> cerrarSesion() async {
    await PushService.instancia.quitarDispositivo();
    try {
      await api.post('logout.php', {});
    } on ApiException {
      // Aunque el servidor no responda, cerramos la sesión en el teléfono.
    }
    await api.guardarToken(null);
    await _google.cerrarSesion();
    await RecordatorioService.instancia.cancelarTodos();
    usuario = null;
    error = null;
    avisar();
  }

  Future<String?> actualizarPerfil({required String nombre, String? telefono, String? dni}) => intentar(() async {
        final r = await api.put('perfil.php', {'nombre': nombre, 'telefono': telefono ?? '', 'dni': dni ?? ''});
        usuario = Usuario.fromJson(Map<String, dynamic>.from(r['usuario'] as Map));
        avisar();
      });

  /// Recarga datos que el login no trae (CMP y especialidad del médico).
  Future<void> refrescarPerfil() async {
    try {
      await _cargarPerfil();
      avisar();
    } on ApiException {
      // Se conserva lo que ya teníamos en pantalla.
    }
  }

  void limpiarError() {
    error = null;
    avisar();
  }

  Future<void> _abrir(dynamic respuesta) async {
    await api.guardarToken(respuesta['token'] as String);
    usuario = Usuario.fromJson(Map<String, dynamic>.from(respuesta['usuario'] as Map));
    PushService.instancia.registrarDispositivo();
  }

  Future<void> _cargarPerfil() async {
    final r = await api.get('perfil.php');
    usuario = Usuario.fromJson(Map<String, dynamic>.from(r['usuario'] as Map));
  }

  Future<bool> _conCarga(Future<void> Function() accion) async {
    cargando = true;
    error = null;
    avisar();
    final fallo = await intentar(accion);
    cargando = false;
    error = fallo;
    avisar();
    return fallo == null;
  }
}
