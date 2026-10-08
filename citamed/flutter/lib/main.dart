import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'controllers/auth_controller.dart';
import 'controllers/catalogo_controller.dart';
import 'controllers/citas_controller.dart';
import 'controllers/historial_controller.dart';
import 'controllers/horario_controller.dart';
import 'controllers/notificaciones_controller.dart';
import 'controllers/usuarios_controller.dart';

import 'core/tema.dart';
import 'models/usuario.dart';
import 'services/push_service.dart';
import 'services/recordatorio_service.dart';
import 'views/raiz_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();

  // Inicializar idioma/calendario
  await initializeDateFormatting('es');

  // Inicializar recordatorios
  await RecordatorioService.instancia.iniciar();

  // Inicializar notificaciones Firebase
  await PushService.instancia.iniciar();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthController()..restaurarSesion(),
      child: const CitaMedApp(),
    ),
  );
}

class CitaMedApp extends StatelessWidget {
  const CitaMedApp({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthController>().usuario;

    final color = switch (usuario?.rol) {
      Rol.medico => Paleta.medico,
      Rol.admin => Paleta.admin,
      _ => Paleta.paciente,
    };

    return MaterialApp(
      title: 'CitaMed',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.construir(color),
      locale: const Locale('es'),
      supportedLocales: const [
        Locale('es'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MultiProvider(
        key: ValueKey(usuario?.id ?? 0),
        providers: [
          ChangeNotifierProvider(
            create: (_) => CatalogoController(),
          ),
          ChangeNotifierProvider(
            create: (_) => CitasController(),
          ),
          ChangeNotifierProvider(
            create: (_) => HistorialController(),
          ),
          ChangeNotifierProvider(
            create: (_) => HorarioController(),
          ),
          ChangeNotifierProvider(
            create: (_) {
              final c = NotificacionesController();

              PushService.instancia.alRecibir = c.cargar;

              PushService.instancia.alAbrirNotificacion = c.cargar;

              return c;
            },
          ),
          ChangeNotifierProvider(
            create: (_) => UsuariosController(),
          ),
        ],
        child: child ?? const SizedBox.shrink(),
      ),
      home: const RaizApp(),
    );
  }
}
