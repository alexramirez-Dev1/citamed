import 'package:flutter/material.dart';
import '../core/tema.dart';

/// Cruz médica verde con el nombre de la app.
class LogoCitaMed extends StatelessWidget {
  const LogoCitaMed({super.key, this.tamano = 64, this.mostrarLema = true});
  final double tamano;
  final bool mostrarLema;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: tamano,
          height: tamano,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tamano * 0.26),
            gradient: const LinearGradient(colors: [Paleta.menta, Paleta.paciente], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: const [BoxShadow(color: Color(0x3300B894), blurRadius: 18, offset: Offset(0, 8))],
          ),
          child: Icon(Icons.add_rounded, color: Colors.white, size: tamano * 0.82),
        ),
        const SizedBox(height: 12),
        Text('CitaMed', style: TextStyle(fontSize: tamano * 0.5, fontWeight: FontWeight.w800, color: Paleta.paciente, letterSpacing: -0.5)),
        if (mostrarLema)
          const Text('Tu salud, nuestra prioridad', style: TextStyle(color: Paleta.textoSuave, fontSize: 13)),
      ]);
}
