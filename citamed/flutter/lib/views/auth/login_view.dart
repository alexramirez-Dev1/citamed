import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/tema.dart';
import '../../widgets/formulario.dart';
import '../../widgets/logo_citamed.dart';
import '../../widgets/mensajes.dart';
import 'registro_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthController>();
    final ok = await auth.iniciarSesion(_correo.text.trim(), _clave.text);
    if (!ok && mounted) mostrarMensaje(context, auth.error ?? 'No se pudo iniciar sesión', error: true);
  }

  Future<void> _entrarConGoogle() async {
    final auth = context.read<AuthController>();
    final ok = await auth.entrarConGoogle();
    if (!ok && mounted) mostrarMensaje(context, auth.error ?? 'No se pudo entrar con Google', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final cargando = context.select<AuthController, bool>((a) => a.cargando);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formulario,
                child: Column(children: [
                  const LogoCitaMed(),
                  const SizedBox(height: 34),
                  CampoTexto(
                    controlador: _correo,
                    etiqueta: 'Correo electrónico',
                    icono: Icons.mail_outline,
                    teclado: TextInputType.emailAddress,
                    validador: Validar.correo,
                  ),
                  const SizedBox(height: 14),
                  CampoClave(
                    controlador: _clave,
                    validador: (v) => Validar.obligatorio(v, 'La contraseña'),
                    alEnviar: _entrar,
                  ),
                  const SizedBox(height: 22),
                  BotonPrincipal(texto: 'Ingresar', alPulsar: _entrar, cargando: cargando),
                  const SizedBox(height: 18),
                  const Row(children: [
                    Expanded(child: Divider()),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('o', style: TextStyle(color: Paleta.textoSuave))),
                    Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: cargando ? null : _entrarConGoogle,
                    icon: const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4285F4))),
                    label: const Text('Continuar con Google', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: cargando ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistroView())),
                    child: const Text('¿No tienes cuenta? Regístrate'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
