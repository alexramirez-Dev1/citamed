import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/citas_controller.dart';
import '../../controllers/notificaciones_controller.dart';
import '../../core/tema.dart';
import '../../widgets/avatares.dart';
import '../../widgets/campana_notificaciones.dart';
import '../../widgets/opcion_menu.dart';
import '../../widgets/tarjeta_suave.dart';
import '../compartido/historial_view.dart';
import '../compartido/perfil_view.dart';
import 'citas_medico_view.dart';
import 'horario_view.dart';

/// Contenedor del perfil médico: barra inferior con Inicio, Citas, Horario y Perfil.
class PanelMedicoView extends StatefulWidget {
  const PanelMedicoView({super.key});

  @override
  State<PanelMedicoView> createState() => _PanelMedicoViewState();
}

class _PanelMedicoViewState extends State<PanelMedicoView> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indice, children: [
        _InicioMedico(alIr: (i) => setState(() => _indice = i)),
        const CitasMedicoView(),
        const HorarioView(),
        const PerfilView(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Citas'),
          NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule), label: 'Horario'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _InicioMedico extends StatefulWidget {
  const _InicioMedico({required this.alIr});
  final ValueChanged<int> alIr;

  @override
  State<_InicioMedico> createState() => _InicioMedicoState();
}

class _InicioMedicoState extends State<_InicioMedico> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CitasController>().cargar(estado: 'Pendiente');
      context.read<NotificacionesController>().cargar();
      context.read<AuthController>().refrescarPerfil(); // trae la especialidad para el saludo
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthController>().usuario!;
    final pendientes = context.watch<CitasController>().lista(estado: 'Pendiente').length;

    return Scaffold(
      appBar: AppBar(title: const Text('Panel Médico'), actions: const [CampanaNotificaciones()]),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TarjetaSuave(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              AvatarIniciales(nombre: usuario.nombre, radio: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hola, ${usuario.nombre}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Paleta.texto)),
                  Text(usuario.especialidad ?? 'Médico', style: const TextStyle(color: Paleta.textoSuave)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          FilaAcceso(
            icono: Icons.event_available_outlined,
            titulo: 'Mis citas',
            subtitulo: pendientes == 1 ? '1 cita pendiente' : '$pendientes citas pendientes',
            alTocar: () => widget.alIr(1),
          ),
          FilaAcceso(
            icono: Icons.assignment_outlined,
            titulo: 'Historial clínico',
            subtitulo: 'Diagnósticos de mis pacientes',
            alTocar: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistorialView())),
          ),
          FilaAcceso(icono: Icons.access_time, titulo: 'Mi horario', subtitulo: 'Configurar atención', alTocar: () => widget.alIr(2)),
          FilaAcceso(icono: Icons.badge_outlined, titulo: 'Mi perfil', subtitulo: 'Datos profesionales', alTocar: () => widget.alIr(3)),
          const SizedBox(height: 16),
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
