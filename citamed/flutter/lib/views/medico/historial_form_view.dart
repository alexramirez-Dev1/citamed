import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/citas_controller.dart';
import '../../controllers/historial_controller.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../models/cita.dart';
import '../../models/historial_clinico.dart';
import '../../widgets/formulario.dart';

/// Formulario del médico para registrar o editar la ficha clínica de una cita.
/// Si la cita estaba confirmada, al guardar el servidor la marca como atendida.
class HistorialFormView extends StatefulWidget {
  const HistorialFormView({super.key, required this.cita});

  final Cita cita;

  @override
  State<HistorialFormView> createState() => _HistorialFormViewState();
}

class _HistorialFormViewState extends State<HistorialFormView> {
  final _motivo = TextEditingController();
  final _diagnostico = TextEditingController();
  final _tratamiento = TextEditingController();
  final _notas = TextEditingController();
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _precargar();
  }

  Future<void> _precargar() async {
    final HistorialClinico? ficha = await context.read<HistorialController>().deCita(widget.cita.id);
    if (!mounted) return;
    if (ficha != null) {
      _motivo.text = ficha.motivo;
      _diagnostico.text = ficha.diagnostico;
      _tratamiento.text = ficha.tratamiento;
      _notas.text = ficha.notas;
    }
    setState(() => _cargando = false);
  }

  @override
  void dispose() {
    _motivo.dispose();
    _diagnostico.dispose();
    _tratamiento.dispose();
    _notas.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_diagnostico.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('El diagnóstico es obligatorio'),
        backgroundColor: Paleta.cancelada,
      ));
      return;
    }
    setState(() => _guardando = true);
    final fallo = await context.read<HistorialController>().guardar(
          citaId: widget.cita.id,
          motivo: _motivo.text.trim(),
          diagnostico: _diagnostico.text.trim(),
          tratamiento: _tratamiento.text.trim(),
          notas: _notas.text.trim(),
        );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (fallo == null) {
      // La cita pudo pasar a "Atendida": refresca las listas del médico.
      await context.read<CitasController>().cargar(vista: 'hoy');
      await context.read<CitasController>().cargar(vista: 'proximas');
      await context.read<CitasController>().cargar(vista: 'historial');
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ficha clínica guardada'),
        backgroundColor: Paleta.texto,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(fallo), backgroundColor: Paleta.cancelada));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cita = widget.cita;
    return Scaffold(
      appBar: AppBar(title: const Text('Ficha clínica')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(cita.paciente, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Paleta.texto)),
                const SizedBox(height: 4),
                Text('${Formato.fechaLarga(cita.fecha)} · ${cita.hora}',
                    style: const TextStyle(color: Paleta.textoSuave)),
                const SizedBox(height: 20),
                CampoTexto(etiqueta: 'Motivo de consulta', controlador: _motivo, icono: Icons.help_outline, teclado: TextInputType.multiline),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _diagnostico,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Diagnóstico *',
                    prefixIcon: Icon(Icons.assignment_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _tratamiento,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Tratamiento / receta',
                    prefixIcon: Icon(Icons.medication_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notas,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notas adicionales',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(_guardando ? 'Guardando…' : 'Guardar ficha'),
                ),
              ],
            ),
    );
  }
}
