import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

/// Base común: evita notificar después de que el controlador fue destruido (p. ej. al cerrar sesión
/// con una petición en vuelo) y traduce excepciones de la API a un mensaje.
abstract class ControladorBase extends ChangeNotifier {
  final ApiClient api = ApiClient.instancia;
  bool _vivo = true;

  @override
  void dispose() {
    _vivo = false;
    super.dispose();
  }

  void avisar() {
    if (_vivo) notifyListeners();
  }

  /// Ejecuta una acción y devuelve el mensaje de error, o null si salió bien.
  Future<String?> intentar(Future<void> Function() accion) async {
    try {
      await accion();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    } catch (_) {
      return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
    }
  }
}

List<Map<String, dynamic>> comoLista(dynamic datos) =>
    (datos as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
