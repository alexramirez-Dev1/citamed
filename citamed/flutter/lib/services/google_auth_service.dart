import 'package:google_sign_in/google_sign_in.dart';
import '../core/config.dart';
import 'api_client.dart';

/// Obtiene el id_token de Google; el backend lo valida y crea o recupera la cuenta.
class GoogleAuthService {
  final GoogleSignIn _google = GoogleSignIn(
    scopes: const ['email'],
    serverClientId: Config.googleServerClientId,
  );

  Future<String> obtenerIdToken() async {
    try {
      // Desconectamos para evitar sesiones previas bloqueadas
      await _google.signOut();

      final cuenta = await _google.signIn();
      if (cuenta == null)
        throw const ApiException('Cancelaste el inicio con Google.');

      final autenticacion = await cuenta.authentication;
      final token = autenticacion.idToken;
      if (token == null)
        throw const ApiException('Google no entregó un token válido.');

      return token;
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      // IMPRIMIR ERROR REAL EN LA CONSOLA DE VS CODE
      print('========================================');
      print('ERROR REAL DE GOOGLE SIGN-IN: $e');
      print('STACKTRACE: $stack');
      print('========================================');

      throw ApiException('Error detallado: $e');
    }
  }

  Future<void> cerrarSesion() async {
    try {
      await _google.signOut();
    } catch (_) {
      // Si Google ya estaba desconectado no hay nada que hacer.
    }
  }
}
