import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/historial_controller.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../models/historial_clinico.dart';
import '../../models/usuario.dart';
import '../../widgets/tarjeta_suave.dart';
import '../../widgets/vista_estado.dart';

/// Lista del historial clínico. El servidor devuelve el del paciente o el de los pacientes del médico.
class HistorialView extends StatefulWidget {
  const HistorialView({super.key});

  @override
  State<HistorialView> createState() => _HistorialViewState();
}

class _HistorialViewState extends State<HistorialView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<HistorialController>().cargar());
  }

  @override
  Widget build(BuildContext context) {
    final esMedico = context.watch<AuthController>().usuario?.rol == Rol.medico;
    final controlador = context.watch<HistorialController>();

    return Scaffold(
      appBar: AppBar(title: Text(esMedico ? 'Historial de pacientes' : 'Mi historial clínico')),
      body: RefreshIndicator(
        onRefresh: controlador.cargar,
        child: CuerpoAsincrono(
          cargando: controlador.cargando,
          error: controlador.error,
          vacio: controlador.items.isEmpty,
          alReintentar: controlador.cargar,
          iconoVacio: Icons.assignment_outlined,
          tituloVacio: 'Sin historial todavía',
          mensajeVacio: esMedico
              ? 'Cuando registres el diagnóstico de una cita, aparecerá aquí.'
              : 'Cuando tu médico registre un diagnóstico, aparecerá aquí.',
          construir: (_) => ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: controlador.items.length,
            itemBuilder: (_, i) => _TarjetaHistorial(ficha: controlador.items[i], mostrarPaciente: esMedico),
          ),
        ),
      ),
    );
  }
}

class _TarjetaHistorial extends StatelessWidget {
  const _TarjetaHistorial({required this.ficha, required this.mostrarPaciente});

  final HistorialClinico ficha;
  final bool mostrarPaciente;

  @override
  Widget build(BuildContext context) {
    return TarjetaSuave(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HistorialDetalleView(ficha: ficha)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(mostrarPaciente ? ficha.paciente : '${ficha.medico} · ${ficha.especialidad}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Paleta.texto)),
          ),
          Text(Formato.fechaCorta(ficha.fecha), style: const TextStyle(color: Paleta.textoSuave, fontSize: 13)),
        ]),
        if (ficha.motivo.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(ficha.motivo, style: const TextStyle(color: Paleta.textoSuave)),
        ],
        const SizedBox(height: 6),
        Text(ficha.diagnostico, maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

/// Detalle completo de una ficha clínica.
class HistorialDetalleView extends StatelessWidget {
  const HistorialDetalleView({super.key, required this.ficha});

  final HistorialClinico ficha;

  @override
  Widget build(BuildContext context) {
    final esMedico = context.watch<AuthController>().usuario?.rol == Rol.medico;
    return Scaffold(
      appBar: AppBar(title: const Text('Ficha clínica')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(esMedico ? ficha.paciente : ficha.medico,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Paleta.texto)),
          const SizedBox(height: 4),
          Text('${ficha.especialidad} · ${Formato.fechaLarga(ficha.fecha)} · ${ficha.hora}',
              style: const TextStyle(color: Paleta.textoSuave)),
          const SizedBox(height: 20),
          if (ficha.motivo.isNotEmpty) _Seccion(titulo: 'Motivo de consulta', texto: ficha.motivo),
          _Seccion(titulo: 'Diagnóstico', texto: ficha.diagnostico),
          if (ficha.tratamiento.isNotEmpty) _Seccion(titulo: 'Tratamiento', texto: ficha.tratamiento),
          if (ficha.notas.isNotEmpty) _Seccion(titulo: 'Notas', texto: ficha.notas),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.texto});

  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, color: Paleta.texto)),
        const SizedBox(height: 6),
        TarjetaSuave(child: Text(texto, style: const TextStyle(height: 1.4))),
      ]),
    );
  }
}
