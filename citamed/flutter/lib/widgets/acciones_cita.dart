import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/citas_controller.dart';
import '../core/formato.dart';
import '../core/tema.dart';
import '../models/cita.dart';
import 'estado_chip.dart';
import 'mensajes.dart';

/// Estados a los que cada rol puede mover una cita desde su estado actual.
List<EstadoCita> transicionesPaciente(Cita c) => c.esActiva ? [EstadoCita.cancelada] : [];

List<EstadoCita> transicionesMedico(Cita c) => switch (c.estado) {
      EstadoCita.pendiente => [EstadoCita.confirmada, EstadoCita.cancelada],
      EstadoCita.confirmada => [EstadoCita.atendida, EstadoCita.cancelada],
      _ => [],
    };

List<EstadoCita> transicionesAdmin(Cita c) => EstadoCita.values.where((e) => e != c.estado).toList();

String _textoAccion(EstadoCita e) => switch (e) {
      EstadoCita.confirmada => 'Confirmar cita',
      EstadoCita.atendida => 'Marcar como atendida',
      EstadoCita.cancelada => 'Cancelar cita',
      EstadoCita.pendiente => 'Volver a pendiente',
    };

/// Hoja inferior con el detalle de la cita y los botones de las acciones permitidas.
Future<void> mostrarAccionesCita(
  BuildContext context,
  Cita cita, {
  required bool mostrarPaciente,
  required List<EstadoCita> acciones,
  VoidCallback? alRegistrarHistorial,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(mostrarPaciente ? cita.paciente : cita.medico,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Paleta.texto)),
          ),
          EstadoChip(estado: cita.estado),
        ]),
        const SizedBox(height: 6),
        Text(mostrarPaciente ? '${cita.medico} · ${cita.especialidad}' : '${cita.especialidad} · CMP ${cita.cmp}',
            style: const TextStyle(color: Paleta.textoSuave)),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.event, size: 18, color: Paleta.textoSuave),
          const SizedBox(width: 8),
          Expanded(child: Text('${Formato.fechaLarga(cita.fecha)} · ${cita.hora}')),
        ]),
        if (alRegistrarHistorial != null) ...[
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.pop(ctx);
              alRegistrarHistorial();
            },
            icon: const Icon(Icons.assignment_outlined),
            label: const Text('Ficha clínica'),
          ),
        ],
        if (acciones.isNotEmpty) const SizedBox(height: 20),
        for (final accion in acciones)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: accion == EstadoCita.cancelada
                ? OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Paleta.cancelada, side: const BorderSide(color: Paleta.cancelada)),
                    onPressed: () => _aplicar(ctx, context, cita, accion),
                    child: Text(_textoAccion(accion)),
                  )
                : FilledButton(
                    onPressed: () => _aplicar(ctx, context, cita, accion),
                    child: Text(_textoAccion(accion)),
                  ),
          ),
      ]),
    ),
  );
}

Future<void> _aplicar(BuildContext hoja, BuildContext origen, Cita cita, EstadoCita nuevo) async {
  final controlador = hoja.read<CitasController>();
  final mensajero = ScaffoldMessenger.of(origen);
  final navegador = Navigator.of(hoja);

  if (nuevo == EstadoCita.cancelada) {
    final seguro = await confirmar(hoja,
        titulo: 'Cancelar cita', mensaje: 'Esta acción no se puede deshacer.', accion: 'Sí, cancelar');
    if (!seguro) return;
  }
  final fallo = await controlador.cambiarEstado(cita, nuevo);
  navegador.pop();
  mensajero
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(fallo ?? 'La cita quedó como ${nuevo.etiqueta.toLowerCase()}'),
      backgroundColor: fallo == null ? Paleta.texto : Paleta.cancelada,
    ));
}
