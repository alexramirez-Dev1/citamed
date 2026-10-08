import 'package:flutter/material.dart';
import '../core/tema.dart';
import '../models/cita.dart';

Color colorDeEstado(EstadoCita estado) => switch (estado) {
      EstadoCita.confirmada => Paleta.confirmada,
      EstadoCita.pendiente => Paleta.pendiente,
      EstadoCita.atendida => Paleta.atendida,
      EstadoCita.cancelada => Paleta.cancelada,
    };

/// Etiqueta de color para el estado de una cita (verde confirmada, naranja pendiente...).
class EstadoChip extends StatelessWidget {
  const EstadoChip({super.key, required this.estado});
  final EstadoCita estado;

  @override
  Widget build(BuildContext context) => EtiquetaColor(texto: estado.etiqueta, color: colorDeEstado(estado));
}

class EtiquetaColor extends StatelessWidget {
  const EtiquetaColor({super.key, required this.texto, required this.color});
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(20)),
        child: Text(texto, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}
