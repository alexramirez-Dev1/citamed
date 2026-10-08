import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/citas_controller.dart';
import '../models/cita.dart';
import 'tarjeta_cita.dart';
import 'vista_estado.dart';

/// Lista de citas con carga, error, estado vacío y "tirar para refrescar".
/// El servidor decide qué citas ve cada rol; aquí solo se elige la vista y el estado.
class ListaCitas extends StatefulWidget {
  const ListaCitas({
    super.key,
    this.vista,
    this.estado,
    this.mostrarPaciente = false,
    this.alTocar,
    this.programarRecordatorios = false,
    this.tituloVacio = 'No hay citas',
    this.mensajeVacio,
  });

  final String? vista;
  final String? estado;
  final bool mostrarPaciente;
  final void Function(Cita cita)? alTocar;
  final bool programarRecordatorios;
  final String tituloVacio;
  final String? mensajeVacio;

  @override
  State<ListaCitas> createState() => _ListaCitasState();
}

class _ListaCitasState extends State<ListaCitas> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() {
    if (!mounted) return Future.value();
    return context.read<CitasController>().cargar(
          vista: widget.vista,
          estado: widget.estado,
          programarRecordatorios: widget.programarRecordatorios,
        );
  }

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<CitasController>();
    final citas = controlador.lista(vista: widget.vista, estado: widget.estado);
    return RefreshIndicator(
      onRefresh: _cargar,
      child: CuerpoAsincrono(
        cargando: controlador.cargando(vista: widget.vista, estado: widget.estado),
        error: controlador.error(vista: widget.vista, estado: widget.estado),
        vacio: citas.isEmpty,
        alReintentar: _cargar,
        iconoVacio: Icons.event_busy_outlined,
        tituloVacio: widget.tituloVacio,
        mensajeVacio: widget.mensajeVacio,
        construir: (_) => ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: citas.length,
          itemBuilder: (_, i) => TarjetaCita(
            cita: citas[i],
            mostrarPaciente: widget.mostrarPaciente,
            alTocar: widget.alTocar == null ? null : () => widget.alTocar!(citas[i]),
          ),
        ),
      ),
    );
  }
}
