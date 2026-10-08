import 'package:flutter/material.dart';
import '../core/formato.dart';
import '../core/tema.dart';
import '../models/cita.dart';
import 'avatares.dart';
import 'estado_chip.dart';
import 'tarjeta_suave.dart';

/// Tarjeta de una cita. El paciente ve al médico; el médico y el admin ven también al paciente.
class TarjetaCita extends StatelessWidget {
  const TarjetaCita({super.key, required this.cita, this.mostrarPaciente = false, this.alTocar});
  final Cita cita;
  final bool mostrarPaciente;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final titulo = mostrarPaciente ? cita.paciente : cita.especialidad;
    final detalle = mostrarPaciente ? '${cita.medico} · ${cita.especialidad}' : cita.medico;
    return TarjetaSuave(
      onTap: alTocar,
      margen: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        mostrarPaciente
            ? AvatarIniciales(nombre: cita.paciente, radio: 23)
            : IconoEspecialidad(clave: cita.icono),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: Paleta.texto)),
            const SizedBox(height: 2),
            Text(detalle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Paleta.textoSuave, fontSize: 13)),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.schedule, size: 14, color: Paleta.textoSuave),
              const SizedBox(width: 4),
              Flexible(
                child: Text('${Formato.fechaCorta(cita.fecha)} · ${cita.hora}',
                    style: const TextStyle(color: Paleta.textoSuave, fontSize: 12.5)),
              ),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        EstadoChip(estado: cita.estado),
      ]),
    );
  }
}
