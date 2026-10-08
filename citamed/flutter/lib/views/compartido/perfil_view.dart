import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/tema.dart';
import '../../models/usuario.dart';
import '../../widgets/avatares.dart';
import '../../widgets/formulario.dart';
import '../../widgets/mensajes.dart';
import '../../widgets/tarjeta_suave.dart';

/// Perfil del usuario autenticado. Sirve a los tres roles; el médico además ve su colegiatura.
class PerfilView extends StatefulWidget {
  const PerfilView({super.key});

  @override
  State<PerfilView> createState() => _PerfilViewState();
}

class _PerfilViewState extends State<PerfilView> {
  @override
  void initState() {
    super.initState();
    // El login no trae CMP ni especialidad; se piden al abrir el perfil.
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AuthController>().refrescarPerfil());
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthController>().usuario;
    if (usuario == null) return const SizedBox.shrink();
    final esMedico = usuario.rol == Rol.medico;

    return Scaffold(
      appBar: AppBar(title: Text(esMedico ? 'Mi perfil - Médico' : 'Mi perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: AvatarIniciales(nombre: usuario.nombre, radio: 48)),
          const SizedBox(height: 14),
          Center(child: Text(usuario.nombre, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Paleta.texto))),
          Center(child: Text(esMedico ? (usuario.especialidad ?? 'Médico') : usuario.rol.etiqueta, style: const TextStyle(color: Paleta.textoSuave))),
          const SizedBox(height: 22),
          TarjetaSuave(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(children: [
              _Dato(etiqueta: 'DNI', valor: usuario.dni),
              _Dato(etiqueta: 'Correo', valor: usuario.email),
              _Dato(etiqueta: 'Teléfono', valor: usuario.telefono),
              if (esMedico) _Dato(etiqueta: 'Colegiatura', valor: usuario.cmp == null ? null : 'CMP ${usuario.cmp}'),
              _Dato(etiqueta: 'Estado', valor: usuario.activo ? 'Activo' : 'Inactivo', ultimo: true),
            ]),
          ),
          const SizedBox(height: 22),
          BotonPrincipal(texto: 'Editar', icono: Icons.edit_outlined, alPulsar: () => _editar(context, usuario)),
        ],
      ),
    );
  }

  void _editar(BuildContext context, Usuario usuario) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _FormularioPerfil(usuario: usuario),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor, this.ultimo = false});
  final String etiqueta;
  final String? valor;
  final bool ultimo;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: ultimo ? null : const Border(bottom: BorderSide(color: Paleta.borde, width: 0.8))),
        child: Row(children: [
          SizedBox(width: 104, child: Text(etiqueta, style: const TextStyle(color: Paleta.textoSuave))),
          Expanded(child: Text(valor == null || valor!.isEmpty ? 'Sin registrar' : valor!, style: const TextStyle(fontWeight: FontWeight.w600, color: Paleta.texto))),
        ]),
      );
}

class _FormularioPerfil extends StatefulWidget {
  const _FormularioPerfil({required this.usuario});
  final Usuario usuario;

  @override
  State<_FormularioPerfil> createState() => _FormularioPerfilState();
}

class _FormularioPerfilState extends State<_FormularioPerfil> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre = TextEditingController(text: widget.usuario.nombre);
  late final TextEditingController _dni = TextEditingController(text: widget.usuario.dni ?? '');
  late final TextEditingController _telefono = TextEditingController(text: widget.usuario.telefono ?? '');
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _dni.dispose();
    _telefono.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _guardando = true);
    final navegador = Navigator.of(context);
    final mensajero = ScaffoldMessenger.of(context);
    final fallo = await context.read<AuthController>().actualizarPerfil(
          nombre: _nombre.text.trim(),
          dni: _dni.text.trim(),
          telefono: _telefono.text.trim(),
        );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (fallo == null) {
      navegador.pop();
      mensajero.showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
    } else {
      mostrarMensaje(context, fallo, error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formulario,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CampoTexto(controlador: _nombre, etiqueta: 'Nombre completo', icono: Icons.person_outline, validador: (v) => Validar.obligatorio(v, 'El nombre')),
              const SizedBox(height: 12),
              CampoTexto(controlador: _dni, etiqueta: 'DNI', icono: Icons.badge_outlined, teclado: TextInputType.number, maxLongitud: 8, validador: Validar.dniOpcional),
              const SizedBox(height: 12),
              CampoTexto(controlador: _telefono, etiqueta: 'Teléfono', icono: Icons.phone_outlined, teclado: TextInputType.phone, maxLongitud: 15, accion: TextInputAction.done, alEnviar: _guardar),
              const SizedBox(height: 20),
              BotonPrincipal(texto: 'Guardar cambios', alPulsar: _guardar, cargando: _guardando),
            ]),
          ),
        ),
      );
}
