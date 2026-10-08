import 'package:flutter/material.dart';
import '../../widgets/acciones_cita.dart';
import '../../widgets/lista_citas.dart';

class MisCitasView extends StatelessWidget {
  const MisCitasView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis citas'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: 'Próximas'), Tab(text: 'Historial')],
          ),
        ),
        body: TabBarView(children: [
          ListaCitas(
            vista: 'proximas',
            programarRecordatorios: true,
            tituloVacio: 'No tienes citas próximas',
            mensajeVacio: 'Reserva una desde el menú principal.',
            alTocar: (cita) => mostrarAccionesCita(context, cita, mostrarPaciente: false, acciones: transicionesPaciente(cita)),
          ),
          ListaCitas(
            vista: 'historial',
            tituloVacio: 'Aún no tienes historial',
            mensajeVacio: 'Tus citas atendidas y canceladas aparecerán aquí.',
            alTocar: (cita) => mostrarAccionesCita(context, cita, mostrarPaciente: false, acciones: const []),
          ),
        ]),
      ),
    );
  }
}
