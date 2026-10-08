import 'package:flutter/material.dart';

/// Campo de texto con ícono y etiqueta; reduce el ruido de repetir InputDecoration en cada formulario.
class CampoTexto extends StatelessWidget {
  const CampoTexto({
    super.key,
    required this.controlador,
    required this.etiqueta,
    required this.icono,
    this.validador,
    this.teclado,
    this.alEnviar,
    this.maxLongitud,
    this.accion = TextInputAction.next,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final IconData icono;
  final String? Function(String?)? validador;
  final TextInputType? teclado;
  final VoidCallback? alEnviar;
  final int? maxLongitud;
  final TextInputAction accion;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controlador,
        keyboardType: teclado,
        textInputAction: accion,
        maxLength: maxLongitud,
        validator: validador,
        onFieldSubmitted: (_) => alEnviar?.call(),
        decoration: InputDecoration(labelText: etiqueta, prefixIcon: Icon(icono), counterText: ''),
      );
}

/// Campo de contraseña con botón para mostrar u ocultar.
class CampoClave extends StatefulWidget {
  const CampoClave({
    super.key,
    required this.controlador,
    this.etiqueta = 'Contraseña',
    this.validador,
    this.alEnviar,
    this.accion = TextInputAction.done,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final String? Function(String?)? validador;
  final VoidCallback? alEnviar;
  final TextInputAction accion;

  @override
  State<CampoClave> createState() => _CampoClaveState();
}

class _CampoClaveState extends State<CampoClave> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: widget.controlador,
        obscureText: !_visible,
        textInputAction: widget.accion,
        validator: widget.validador,
        onFieldSubmitted: (_) => widget.alEnviar?.call(),
        decoration: InputDecoration(
          labelText: widget.etiqueta,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() => _visible = !_visible),
          ),
        ),
      );
}

/// Botón principal que muestra un loader mientras la acción está en curso.
class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({super.key, required this.texto, required this.alPulsar, this.cargando = false, this.icono});
  final String texto;
  final VoidCallback? alPulsar;
  final bool cargando;
  final IconData? icono;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: cargando ? null : alPulsar,
        child: cargando
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                if (icono != null) ...[Icon(icono, size: 20), const SizedBox(width: 8)],
                Text(texto),
              ]),
      );
}

/// Validadores reutilizables.
class Validar {
  static String? obligatorio(String? v, [String campo = 'Este campo']) =>
      v == null || v.trim().isEmpty ? '$campo es obligatorio' : null;

  static String? correo(String? v) =>
      v == null || !RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim()) ? 'Ingresa un correo válido' : null;

  /// Mismas reglas que el servidor: 8 a 72 caracteres, con letras y números.
  static String? clave(String? v) {
    if (v == null || v.length < 8) return 'Mínimo 8 caracteres';
    if (v.length > 72) return 'Máximo 72 caracteres';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) return 'Usa letras y números';
    return null;
  }

  static String? telefonoOpcional(String? v) =>
      v == null || v.trim().isEmpty || RegExp(r'^\+?[\d\s-]{6,20}$').hasMatch(v.trim()) ? null : 'Teléfono inválido';

  static String? dniOpcional(String? v) =>
      v == null || v.isEmpty || RegExp(r'^\d{8}$').hasMatch(v) ? null : 'El DNI tiene 8 dígitos';
}
