import 'package:flutter/material.dart';
import '../core/tema.dart';

/// Contenedor blanco con borde redondeado y sombra suave; si recibe onTap muestra ripple.
class TarjetaSuave extends StatelessWidget {
  const TarjetaSuave({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.margen = EdgeInsets.zero,
    this.colorBorde,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margen;
  final Color? colorBorde;

  @override
  Widget build(BuildContext context) {
    final forma = BorderRadius.circular(16);
    return Container(
      margin: margen,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: forma,
        border: Border.all(color: colorBorde ?? Paleta.borde.withAlpha(120)),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: forma,
        child: InkWell(
          borderRadius: forma,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
