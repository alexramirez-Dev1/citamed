import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/catalogo_controller.dart';
import '../../core/iconos.dart';
import '../../core/tema.dart';
import '../../models/especialidad.dart';
import '../../widgets/avatares.dart';
import '../../widgets/estado_chip.dart';
import '../../widgets/formulario.dart';
import '../../widgets/mensajes.dart';
import '../../widgets/tarjeta_suave.dart';
import '../../widgets/vista_estado.dart';

/// CRUD de especialidades: crear, editar, activar/desactivar y borrar.
class EspecialidadesAdminView extends StatefulWidget {
  const EspecialidadesAdminView({super.key});

  @override
  State<EspecialidadesAdminView> createState() => _EspecialidadesAdminViewState();
}

class _EspecialidadesAdminViewState extends State<EspecialidadesAdminView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CatalogoController>().cargarEspecialidades());
  }

  void _abrirFormulario([Especialidad? existente]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _FormularioEspecialidad(existente: existente),
    );
  }

  Future<void> _alternar(Especialidad e) async {
    final fallo = await context.read<CatalogoController>().alternarEspecialidad(e);
    if (fallo != null && mounted) mostrarMensaje(context, fallo, error: true);
  }

  Future<void> _borrar(Especialidad e) async {
    final seguro = await confirmar(context, titulo: 'Eliminar especialidad', mensaje: '¿Eliminar "${e.nombre}"? Si tiene médicos, desactívala en su lugar.', accion: 'Eliminar');
    if (!seguro || !mounted) return;
    final fallo = await context.read<CatalogoController>().borrarEspecialidad(e);
    if (mounted) mostrarMensaje(context, fallo ?? 'Especialidad eliminada', error: fallo != null);
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = context.watch<CatalogoController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Especialidades - Admin'),
        actions: [
          TextButton.icon(
            onPressed: _abrirFormulario,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Nueva', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: catalogo.cargarEspecialidades,
        child: CuerpoAsincrono(
          cargando: catalogo.cargandoEspecialidades,
          error: catalogo.errorEspecialidades,
          vacio: catalogo.especialidades.isEmpty,
          alReintentar: catalogo.cargarEspecialidades,
          iconoVacio: Icons.category_outlined,
          tituloVacio: 'Sin especialidades',
          mensajeVacio: 'Crea la primera con el botón "Nueva".',
          construir: (_) => ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: catalogo.especialidades.length,
            itemBuilder: (_, i) {
              final e = catalogo.especialidades[i];
              return TarjetaSuave(
                margen: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                child: Row(children: [
                  IconoEspecialidad(clave: e.icono, apagado: !e.activo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.nombre, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: e.activo ? Paleta.texto : Paleta.textoSuave)),
                      const SizedBox(height: 4),
                      EtiquetaColor(texto: e.activo ? 'Activa' : 'Inactiva', color: e.activo ? Paleta.confirmada : Paleta.textoSuave),
                    ]),
                  ),
                  Switch(value: e.activo, onChanged: (_) => _alternar(e)),
                  IconButton(onPressed: () => _abrirFormulario(e), icon: const Icon(Icons.edit_outlined, size: 20)),
                  IconButton(onPressed: () => _borrar(e), icon: const Icon(Icons.delete_outline, size: 20, color: Paleta.cancelada)),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FormularioEspecialidad extends StatefulWidget {
  const _FormularioEspecialidad({this.existente});
  final Especialidad? existente;

  @override
  State<_FormularioEspecialidad> createState() => _FormularioEspecialidadState();
}

class _FormularioEspecialidadState extends State<_FormularioEspecialidad> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre = TextEditingController(text: widget.existente?.nombre ?? '');
  late final TextEditingController _descripcion = TextEditingController(text: widget.existente?.descripcion ?? '');
  late String _icono = widget.existente?.icono ?? 'medical_services';
  late bool _activo = widget.existente?.activo ?? true;
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _guardando = true);
    final navegador = Navigator.of(context);
    final fallo = await context.read<CatalogoController>().guardarEspecialidad(
          id: widget.existente?.id,
          nombre: _nombre.text.trim(),
          descripcion: _descripcion.text.trim(),
          icono: _icono,
          activo: _activo,
        );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (fallo == null) {
      navegador.pop();
    } else {
      mostrarMensaje(context, fallo, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formulario,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.existente == null ? 'Nueva especialidad' : 'Editar especialidad',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            CampoTexto(controlador: _nombre, etiqueta: 'Nombre', icono: Icons.label_outline, validador: (v) => Validar.obligatorio(v, 'El nombre')),
            const SizedBox(height: 12),
            CampoTexto(controlador: _descripcion, etiqueta: 'Descripción', icono: Icons.notes, accion: TextInputAction.done),
            const SizedBox(height: 16),
            const Text('Ícono', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final clave in Iconos.disponibles.keys)
                GestureDetector(
                  onTap: () => setState(() => _icono = clave),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: clave == _icono ? color : Colors.transparent, width: 2)),
                    child: IconoEspecialidad(clave: clave, tamano: 42),
                  ),
                ),
            ]),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Especialidad activa'), value: _activo, onChanged: (v) => setState(() => _activo = v)),
            const SizedBox(height: 8),
            BotonPrincipal(texto: 'Guardar', alPulsar: _guardar, cargando: _guardando),
          ]),
        ),
      ),
    );
  }
}
