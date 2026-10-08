import 'package:flutter/material.dart';
import '../../models/cita.dart';
import '../../widgets/acciones_cita.dart';
import '../../widgets/lista_citas.dart';
import 'historial_form_view.dart';

/// Citas del médico en tres pestañas. Tocar una cita abre las acciones permitidas.
class CitasMedicoView extends StatelessWidget {
  const CitasMedicoView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis citas - Médico'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: 'Hoy'), Tab(text: 'Próximas'), Tab(text: 'Historial')],
          ),
        ),
        body: TabBarView(children: [
          _lista(context, vista: 'hoy', vacio: 'No tienes citas hoy', detalle: 'Disfruta el día libre o revisa las próximas.'),
          _lista(context, vista: 'proximas', vacio: 'Sin citas próximas', detalle: 'Cuando un paciente reserve, aparecerá aquí.'),
          _lista(context, vista: 'historial', vacio: 'Sin historial todavía', detalle: 'Las citas atendidas y canceladas se guardan aquí.'),
        ]),
      ),
    );
  }

  Widget _lista(BuildContext context, {required String vista, required String vacio, required String detalle}) => ListaCitas(
        vista: vista,
        mostrarPaciente: true,
        tituloVacio: vacio,
        mensajeVacio: detalle,
        alTocar: (cita) => mostrarAccionesCita(
              context,
              cita,
              mostrarPaciente: true,
              acciones: transicionesMedico(cita),
              // La ficha clínica se puede llenar en citas confirmadas o ya atendidas.
              alRegistrarHistorial:
                  cita.estado == EstadoCita.confirmada || cita.estado == EstadoCita.atendida
                      ? () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => HistorialFormView(cita: cita)))
                      : null,
            ),
      );
}
