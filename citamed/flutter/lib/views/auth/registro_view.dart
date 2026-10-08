import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/formulario.dart';
import '../../widgets/mensajes.dart';

class RegistroView extends StatefulWidget {
  const RegistroView({super.key});

  @override
  State<RegistroView> createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _dni = TextEditingController();
  final _telefono = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _repetir = TextEditingController();

  @override
  void dispose() {
    for (final c in [_nombre, _dni, _telefono, _correo, _clave, _repetir]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthController>();
    final ok = await auth.registrar(
      nombre: _nombre.text.trim(),
      email: _correo.text.trim(),
      password: _clave.text,
      telefono: _telefono.text.trim(),
      dni: _dni.text.trim(),
    );
    // Si salió bien, la app cambia sola al menú del paciente.
    if (!ok && mounted) mostrarMensaje(context, auth.error ?? 'No se pudo crear la cuenta', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final cargando = context.select<AuthController, bool>((a) => a.cargando);
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formulario,
            child: Column(children: [
              CampoTexto(controlador: _nombre, etiqueta: 'Nombre completo', icono: Icons.person_outline, validador: (v) => Validar.obligatorio(v, 'El nombre')),
              const SizedBox(height: 14),
              CampoTexto(controlador: _dni, etiqueta: 'DNI (opcional)', icono: Icons.badge_outlined, teclado: TextInputType.number, maxLongitud: 8, validador: Validar.dniOpcional),
              const SizedBox(height: 14),
              CampoTexto(controlador: _telefono, etiqueta: 'Teléfono (opcional)', icono: Icons.phone_outlined, teclado: TextInputType.phone, maxLongitud: 15, validador: Validar.telefonoOpcional),
              const SizedBox(height: 14),
              CampoTexto(controlador: _correo, etiqueta: 'Correo electrónico', icono: Icons.mail_outline, teclado: TextInputType.emailAddress, validador: Validar.correo),
              const SizedBox(height: 14),
              CampoClave(controlador: _clave, validador: Validar.clave, accion: TextInputAction.next),
              const SizedBox(height: 14),
              CampoClave(
                controlador: _repetir,
                etiqueta: 'Repite la contraseña',
                validador: (v) => v != _clave.text ? 'Las contraseñas no coinciden' : null,
                alEnviar: _registrar,
              ),
              const SizedBox(height: 24),
              BotonPrincipal(texto: 'Crear cuenta', alPulsar: _registrar, cargando: cargando),
            ]),
          ),
        ),
      ),
    );
  }
}
