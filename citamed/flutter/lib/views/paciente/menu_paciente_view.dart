import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/citas_controller.dart';
import '../../controllers/notificaciones_controller.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../widgets/campana_notificaciones.dart';
import '../../widgets/opcion_menu.dart';
import '../../widgets/tarjeta_cita.dart';
import '../compartido/historial_view.dart';
import '../compartido/perfil_view.dart';
import 'especialidades_view.dart';
import 'mis_citas_view.dart';

class MenuPacienteView extends StatefulWidget {
  const MenuPacienteView({super.key});

  @override
  State<MenuPacienteView> createState() => _MenuPacienteViewState();
}

class _MenuPacienteViewState extends State<MenuPacienteView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Al abrir la app se vuelven a programar los recordatorios de las citas vigentes.
      context.read<CitasController>().cargar(vista: 'proximas', programarRecordatorios: true);
      context.read<NotificacionesController>().cargar();
    });
  }

  void _abrir(Widget pantalla) => Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthController>().usuario!;
    final proximas = context.watch<CitasController>().lista(vista: 'proximas');

    return Scaffold(
      appBar: AppBar(
        title: const Text('CitaMed'),
        actions: const [CampanaNotificaciones()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Hola, ${Formato.primerNombre(usuario.nombre)} 👋',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Paleta.texto)),
          const SizedBox(height: 4),
          const Text('¿Qué deseas hacer hoy?', style: TextStyle(color: Paleta.textoSuave, fontSize: 15)),
          if (proximas.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Tu próxima cita', style: TextStyle(fontWeight: FontWeight.w700, color: Paleta.texto)),
            const SizedBox(height: 8),
            TarjetaCita(cita: proximas.first, alTocar: () => _abrir(const MisCitasView())),
          ],
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.05,
            children: [
              OpcionMenu(
                icono: Icons.calendar_month_outlined,
                titulo: 'Reservar cita',
                subtitulo: 'Especialidad y horario',
                alTocar: () => _abrir(const EspecialidadesView(titulo: 'Reservar cita')),
              ),
              OpcionMenu(
                icono: Icons.event_note_outlined,
                titulo: 'Mis citas',
                subtitulo: 'Ver mis citas',
                alTocar: () => _abrir(const MisCitasView()),
              ),
              OpcionMenu(
                icono: Icons.medical_services_outlined,
                titulo: 'Especialidades',
                subtitulo: 'Ver especialidades',
                alTocar: () => _abrir(const EspecialidadesView()),
              ),
              OpcionMenu(
                icono: Icons.assignment_outlined,
                titulo: 'Mi historial',
                subtitulo: 'Diagnósticos y recetas',
                alTocar: () => _abrir(const HistorialView()),
              ),
              OpcionMenu(
                icono: Icons.person_outline,
                titulo: 'Mi perfil',
                subtitulo: 'Datos personales',
                alTocar: () => _abrir(const PerfilView()),
              ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.read<AuthController>().cerrarSesion(),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
