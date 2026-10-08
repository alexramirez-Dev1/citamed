import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../models/usuario.dart';
import '../widgets/logo_citamed.dart';
import 'admin/panel_admin_view.dart';
import 'auth/login_view.dart';
import 'medico/panel_medico_view.dart';
import 'paciente/menu_paciente_view.dart';

/// Decide la pantalla inicial: carga de sesión, login o el panel que corresponde al rol.
class RaizApp extends StatelessWidget {
  const RaizApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (auth.restaurando) {
      return const Scaffold(body: Center(child: LogoCitaMed(tamano: 72)));
    }
    final usuario = auth.usuario;
    if (usuario == null) return const LoginView();
    return switch (usuario.rol) {
      Rol.paciente => const MenuPacienteView(),
      Rol.medico => const PanelMedicoView(),
      Rol.admin => const PanelAdminView(),
    };
  }
}
