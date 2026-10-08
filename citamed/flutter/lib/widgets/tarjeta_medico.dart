import 'package:flutter/material.dart';
import '../core/tema.dart';
import '../models/medico.dart';
import 'avatares.dart';
import 'tarjeta_suave.dart';

class TarjetaMedico extends StatelessWidget {
  const TarjetaMedico({super.key, required this.medico, this.alTocar, this.compacta = false});
  final Medico medico;
  final VoidCallback? alTocar;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    return TarjetaSuave(
      onTap: alTocar,
      margen: compacta ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        AvatarIniciales(nombre: medico.nombre, radio: 30),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(medico.nombre, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Paleta.texto)),
            const SizedBox(height: 2),
            Text(medico.especialidad, style: const TextStyle(color: Paleta.textoSuave)),
            Text('CMP ${medico.cmp}', style: const TextStyle(color: Paleta.textoSuave, fontSize: 12.5)),
            if (!compacta && medico.totalResenas > 0) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF5B301)),
                const SizedBox(width: 3),
                Text('${medico.calificacion.toStringAsFixed(1)} (${medico.totalResenas})',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ],
          ]),
        ),
        if (alTocar != null) const Icon(Icons.chevron_right, color: Paleta.textoSuave),
      ]),
    );
  }
}
