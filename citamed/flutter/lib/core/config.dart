/// Valores de entorno. Se pueden cambiar al compilar:
/// flutter run --dart-define=API_URL=http://192.168.1.10/citamed/api
class Config {
  /// Emulador Android: 10.0.2.2 · Celular real: IP de tu PC · Web/Windows: localhost
  static const String urlApi = String.fromEnvironment('API_URL',
      defaultValue: 'http://10.0.2.2/citamed/api');

  /// Client ID tipo "Web" de Google Cloud (el mismo de backend/config.php).
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '997980280803-fcgg2dqg1v85a0ifnrisotoseljig33h.apps.googleusercontent.com',
  );
}
