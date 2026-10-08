import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/catalogo_controller.dart';
import '../../core/tema.dart';
import '../../models/medico.dart';
import '../../widgets/avatares.dart';
import '../../widgets/estado_chip.dart';
import '../../widgets/formulario.dart';
import '../../widgets/mensajes.dart';
import '../../widgets/tarjeta_suave.dart';
import '../../widgets/vista_estado.dart';

class MedicosAdminView extends StatefulWidget {
  const MedicosAdminView({super.key});

  @override
  State<MedicosAdminView> createState() => _MedicosAdminViewState();
}

class _MedicosAdminViewState extends State<MedicosAdminView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catalogo = context.read<CatalogoController>();
      catalogo.cargarMedicos();
      catalogo.cargarEspecialidades(); // el formulario de alta las necesita
    });
  }

  Future<void> _alternar(Medico m) async {
    final fallo = await context.read<CatalogoController>().alternarMedico(m);
    if (fallo != null && mounted) mostrarMensaje(context, fallo, error: true);
  }

  void _nuevo() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => const _FormularioMedico(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = context.watch<CatalogoController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Médicos - Admin'),
        actions: [
          TextButton.icon(
            onPressed: _nuevo,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Nuevo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: catalogo.cargarMedicos,
        child: CuerpoAsincrono(
          cargando: catalogo.cargandoMedicos,
          error: catalogo.errorMedicos,
          vacio: catalogo.medicos.isEmpty,
          alReintentar: catalogo.cargarMedicos,
          iconoVacio: Icons.medical_information_outlined,
          tituloVacio: 'Aún no hay médicos',
          mensajeVacio: 'Registra al primero con el botón "Nuevo".',
          construir: (_) => ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: catalogo.medicos.length,
            itemBuilder: (_, i) {
              final m = catalogo.medicos[i];
              return TarjetaSuave(
                margen: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                child: Row(children: [
                  AvatarIniciales(nombre: m.nombre, radio: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: Paleta.texto)),
                      Text('${m.especialidad} · CMP ${m.cmp}', style: const TextStyle(color: Paleta.textoSuave, fontSize: 12.5)),
                      const SizedBox(height: 4),
                      EtiquetaColor(texto: m.activo ? 'Activo' : 'Inactivo', color: m.activo ? Paleta.confirmada : Paleta.textoSuave),
                    ]),
                  ),
                  Switch(value: m.activo, onChanged: (_) => _alternar(m)),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FormularioMedico extends StatefulWidget {
  const _FormularioMedico();

  @override
  State<_FormularioMedico> createState() => _FormularioMedicoState();
}

class _FormularioMedicoState extends State<_FormularioMedico> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _dni = TextEditingController();
  final _telefono = TextEditingController();
  final _cmp = TextEditingController();
  final _precio = TextEditingController(text: '80');
  int? _especialidadId;
  bool _guardando = false;

  @override
  void dispose() {
    for (final c in [_nombre, _correo, _clave, _dni, _telefono, _cmp, _precio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _guardando = true);
    final navegador = Navigator.of(context);
    final mensajero = ScaffoldMessenger.of(context);
    final fallo = await context.read<CatalogoController>().crearMedico({
      'nombre': _nombre.text.trim(),
      'email': _correo.text.trim(),
      'password': _clave.text,
      'dni': _dni.text.trim(),
      'telefono': _telefono.text.trim(),
      'cmp': _cmp.text.trim(),
      'especialidad_id': _especialidadId,
      'precio_consulta': double.tryParse(_precio.text.replaceAll(',', '.')) ?? 0,
    });
    if (!mounted) return;
    setState(() => _guardando = false);
    if (fallo == null) {
      navegador.pop();
      mensajero.showSnackBar(const SnackBar(content: Text('Médico registrado con horario Lun-Vie 08:00 a 17:00')));
    } else {
      mostrarMensaje(context, fallo, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activas = context.watch<CatalogoController>().especialidades.where((e) => e.activo).toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Form(
          key: _formulario,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Nuevo médico', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            CampoTexto(controlador: _nombre, etiqueta: 'Nombre (ej. Dr. Juan Pérez)', icono: Icons.person_outline, validador: (v) => Validar.obligatorio(v, 'El nombre')),
            const SizedBox(height: 12),
            CampoTexto(controlador: _correo, etiqueta: 'Correo', icono: Icons.mail_outline, teclado: TextInputType.emailAddress, validador: Validar.correo),
            const SizedBox(height: 12),
            CampoClave(controlador: _clave, etiqueta: 'Contraseña temporal', validador: Validar.clave, accion: TextInputAction.next),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _especialidadId,
              decoration: const InputDecoration(labelText: 'Especialidad', prefixIcon: Icon(Icons.category_outlined)),
              items: [for (final e in activas) DropdownMenuItem(value: e.id, child: Text(e.nombre))],
              onChanged: (v) => setState(() => _especialidadId = v),
              validator: (v) => v == null ? 'Elige una especialidad' : null,
            ),
            const SizedBox(height: 12),
            CampoTexto(controlador: _cmp, etiqueta: 'CMP (colegiatura)', icono: Icons.verified_outlined, teclado: TextInputType.number, maxLongitud: 8,
                validador: (v) => v == null || !RegExp(r'^\d{4,8}$').hasMatch(v) ? 'Entre 4 y 8 dígitos' : null),
            const SizedBox(height: 12),
            CampoTexto(controlador: _dni, etiqueta: 'DNI', icono: Icons.badge_outlined, teclado: TextInputType.number, maxLongitud: 8, validador: Validar.dniOpcional),
            const SizedBox(height: 12),
            CampoTexto(controlador: _telefono, etiqueta: 'Teléfono', icono: Icons.phone_outlined, teclado: TextInputType.phone, maxLongitud: 15),
            const SizedBox(height: 12),
            CampoTexto(controlador: _precio, etiqueta: 'Precio de consulta (S/)', icono: Icons.payments_outlined,
                teclado: const TextInputType.numberWithOptions(decimal: true), accion: TextInputAction.done),
            const SizedBox(height: 20),
            BotonPrincipal(texto: 'Registrar médico', alPulsar: _guardar, cargando: _guardando),
          ]),
        ),
      ),
    );
  }
}
