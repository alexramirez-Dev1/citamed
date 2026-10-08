import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../widgets/opcion_menu.dart';
import 'citas_admin_view.dart';
import 'especialidades_admin_view.dart';
import 'medicos_admin_view.dart';
import 'usuarios_admin_view.dart';

/// Contenedor del perfil administrador: Inicio, Médicos, Especialidades y Citas.
class PanelAdminView extends StatefulWidget {
  const PanelAdminView({super.key});

  @override
  State<PanelAdminView> createState() => _PanelAdminViewState();
}

class _PanelAdminViewState extends State<PanelAdminView> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indice, children: [
        _InicioAdmin(alIr: (i) => setState(() => _indice = i)),
        const MedicosAdminView(),
        const EspecialidadesAdminView(),
        const CitasAdminView(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.medical_information_outlined), selectedIcon: Icon(Icons.medical_information), label: 'Médicos'),
          NavigationDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: 'Especialid.'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Citas'),
        ],
      ),
    );
  }
}

class _InicioAdmin extends StatelessWidget {
  const _InicioAdmin({required this.alIr});
  final ValueChanged<int> alIr;

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthController>().usuario!;
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Administrativo')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Bienvenido, ${Formato.primerNombre(usuario.nombre)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Paleta.texto)),
          const SizedBox(height: 18),
          FilaAcceso(icono: Icons.medical_information_outlined, titulo: 'Médicos', subtitulo: 'Agregar / editar', alTocar: () => alIr(1)),
          FilaAcceso(icono: Icons.category_outlined, titulo: 'Especialidades', subtitulo: 'Agregar / editar', alTocar: () => alIr(2)),
          FilaAcceso(icono: Icons.calendar_month_outlined, titulo: 'Citas', subtitulo: 'Administrar citas', alTocar: () => alIr(3)),
          FilaAcceso(
            icono: Icons.people_outline,
            titulo: 'Usuarios',
            subtitulo: 'Administrar usuarios',
            alTocar: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UsuariosAdminView())),
          ),
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
