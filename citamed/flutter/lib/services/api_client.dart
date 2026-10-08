import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config.dart';

class ApiException implements Exception {
  final String mensaje;
  final int codigo;
  const ApiException(this.mensaje, [this.codigo = 0]);
  @override
  String toString() => mensaje;
}

/// Cliente HTTP único: agrega el token Bearer, decodifica JSON y traduce errores a ApiException.
class ApiClient {
  ApiClient._();
  static final ApiClient instancia = ApiClient._();

  static const _claveToken = 'citamed_token';
  String? _token;

  /// La app se suscribe para volver al login cuando el servidor responde 401.
  void Function()? alExpirarSesion;

  bool get hayToken => _token != null;

  Future<void> cargarToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_claveToken);
  }

  Future<void> guardarToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_claveToken);
    } else {
      await prefs.setString(_claveToken, token);
    }
  }

  Future<dynamic> get(String ruta, {Map<String, String>? query}) => _enviar('GET', ruta, query: query);
  Future<dynamic> post(String ruta, Map<String, dynamic> cuerpo, {bool auth = true}) =>
      _enviar('POST', ruta, cuerpo: cuerpo, auth: auth);
  Future<dynamic> put(String ruta, Map<String, dynamic> cuerpo, {Map<String, String>? query}) =>
      _enviar('PUT', ruta, cuerpo: cuerpo, query: query);
  Future<dynamic> delete(String ruta, {Map<String, String>? query, Map<String, dynamic>? cuerpo}) =>
      _enviar('DELETE', ruta, query: query, cuerpo: cuerpo);

  Future<dynamic> _enviar(
    String metodo,
    String ruta, {
    Map<String, dynamic>? cuerpo,
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final uri = Uri.parse('${Config.urlApi}/$ruta').replace(queryParameters: query);
    final cabeceras = {
      'Content-Type': 'application/json',
      if (auth && _token != null) 'Authorization': 'Bearer $_token',
    };
    final texto = cuerpo == null ? null : jsonEncode(cuerpo);

    late http.Response respuesta;
    try {
      final peticion = switch (metodo) {
        'POST' => http.post(uri, headers: cabeceras, body: texto),
        'PUT' => http.put(uri, headers: cabeceras, body: texto),
        'DELETE' => http.delete(uri, headers: cabeceras, body: texto),
        _ => http.get(uri, headers: cabeceras),
      };
      respuesta = await peticion.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw ApiException('El servidor tardó demasiado en responder (${Config.urlApi}).');
    } catch (_) {
      // Mostrar la dirección ayuda a detectar si la app apunta a 10.0.2.2 en un celular real.
      throw ApiException('No se pudo conectar con el servidor (${Config.urlApi}). Verifica que estés en la misma red WiFi y que XAMPP esté encendido.');
    }

    dynamic datos;
    if (respuesta.body.isNotEmpty) {
      try {
        datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      } catch (_) {
        throw ApiException('El servidor respondió algo inesperado (${respuesta.statusCode}).', respuesta.statusCode);
      }
    }

    if (respuesta.statusCode >= 400) {
      if (respuesta.statusCode == 401 && auth) {
        await guardarToken(null);
        alExpirarSesion?.call();
      }
      final mensaje = datos is Map && datos['error'] != null ? '${datos['error']}' : 'Error ${respuesta.statusCode}';
      throw ApiException(mensaje, respuesta.statusCode);
    }
    return datos;
  }
}
