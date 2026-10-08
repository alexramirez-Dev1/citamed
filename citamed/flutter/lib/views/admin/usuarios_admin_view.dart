import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/usuarios_controller.dart';
import '../../core/tema.dart';
import '../../widgets/avatares.dart';
import '../../widgets/estado_chip.dart';
import '../../widgets/mensajes.dart';
import '../../widgets/tarjeta_suave.dart';
import '../../widgets/vista_estado.dart';

class UsuariosAdminView extends StatefulWidget {
  const UsuariosAdminView({super.key});

  @override
  State<UsuariosAdminView> createState() => _UsuariosAdminViewState();
}

class _UsuariosAdminViewState extends State<UsuariosAdminView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<UsuariosController>().cargar());
  }

  Future<void> _alternar(UsuariosController controlador, int indice) async {
    final fallo = await controlador.alternar(controlador.usuarios[indice]);
    if (fallo != null && mounted) mostrarMensaje(context, fallo, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<UsuariosController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      body: RefreshIndicator(
        onRefresh: controlador.cargar,
        child: CuerpoAsincrono(
          cargando: controlador.cargando,
          error: controlador.error,
          vacio: controlador.usuarios.isEmpty,
          alReintentar: controlador.cargar,
          iconoVacio: Icons.people_outline,
          tituloVacio: 'Sin usuarios',
          construir: (_) => ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: controlador.usuarios.length,
            itemBuilder: (_, i) {
              final u = controlador.usuarios[i];
              return TarjetaSuave(
                margen: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                child: Row(children: [
                  AvatarIniciales(nombre: u.nombre, radio: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(u.nombre, style: const TextStyle(fontWeight: FontWeight.w700, color: Paleta.texto)),
                      Text(u.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Paleta.textoSuave, fontSize: 12.5)),
                      const SizedBox(height: 4),
                      EtiquetaColor(texto: u.rol, color: Theme.of(context).colorScheme.primary),
                    ]),
                  ),
                  Switch(value: u.activo, onChanged: (_) => _alternar(controlador, i)),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }
}
