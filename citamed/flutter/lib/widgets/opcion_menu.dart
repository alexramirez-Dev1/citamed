import 'package:flutter/material.dart';
import '../core/tema.dart';
import 'tarjeta_suave.dart';

/// Casilla de la cuadrícula del menú principal (ícono, título y subtítulo).
class OpcionMenu extends StatelessWidget {
  const OpcionMenu({super.key, required this.icono, required this.titulo, required this.subtitulo, required this.alTocar});
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return TarjetaSuave(
      onTap: alTocar,
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withAlpha(28), shape: BoxShape.circle),
          child: Icon(icono, size: 30, color: color),
        ),
        const SizedBox(height: 12),
        Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Paleta.texto)),
        const SizedBox(height: 2),
        Text(subtitulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Paleta.textoSuave)),
      ]),
    );
  }
}

/// Fila ancha con ícono para los paneles del médico y del administrador.
class FilaAcceso extends StatelessWidget {
  const FilaAcceso({super.key, required this.icono, required this.titulo, required this.subtitulo, required this.alTocar});
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return TarjetaSuave(
      onTap: alTocar,
      margen: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(color: color.withAlpha(28), borderRadius: BorderRadius.circular(12)),
          child: Icon(icono, color: color, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Paleta.texto)),
            Text(subtitulo, style: const TextStyle(color: Paleta.textoSuave, fontSize: 13)),
          ]),
        ),
        const Icon(Icons.chevron_right, color: Paleta.textoSuave),
      ]),
    );
  }
}
