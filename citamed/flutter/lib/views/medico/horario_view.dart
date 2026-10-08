import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/horario_controller.dart';
import '../../core/tema.dart';
import '../../models/horario.dart';
import '../../widgets/formulario.dart';
import '../../widgets/mensajes.dart';
import '../../widgets/tarjeta_suave.dart';
import '../../widgets/vista_estado.dart';

/// El médico define un horario (inicio/fin + almuerzo) y marca en qué días lo aplica.
class HorarioView extends StatefulWidget {
  const HorarioView({super.key});

  @override
  State<HorarioView> createState() => _HorarioViewState();
}

class _HorarioViewState extends State<HorarioView> {
  static const _nombresDias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  String _inicio = '08:00';
  String _fin = '17:00';
  String _almuerzoInicio = '12:00';
  String _almuerzoFin = '13:00';
  Set<int> _dias = {1, 2, 3, 4, 5};
  bool _cargado = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() async {
    final controlador = context.read<HorarioController>();
    await controlador.cargar();
    final horario = controlador.horario;
    if (!mounted || horario == null) return;
    setState(() {
      _inicio = horario.horaInicio;
      _fin = horario.horaFin;
      _almuerzoInicio = horario.almuerzoInicio;
      _almuerzoFin = horario.almuerzoFin;
      _dias = {...horario.dias};
      _cargado = true;
    });
  }

  Future<String?> _pedirHora(String actual) async {
    final partes = actual.split(':');
    final elegida = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(partes[0]), minute: int.parse(partes[1])),
      builder: (ctx, hijo) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: hijo ?? const SizedBox.shrink(),
      ),
    );
    if (elegida == null) return null;
    return '${elegida.hour.toString().padLeft(2, '0')}:${elegida.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _guardar() async {
    // Las horas "HH:mm" con ceros a la izquierda se comparan bien como texto.
    if (_inicio.compareTo(_fin) >= 0) {
      mostrarMensaje(context, 'La hora de inicio debe ser anterior a la de fin', error: true);
      return;
    }
    if (_almuerzoInicio.compareTo(_almuerzoFin) >= 0 || _almuerzoInicio.compareTo(_inicio) < 0 || _almuerzoFin.compareTo(_fin) > 0) {
      mostrarMensaje(context, 'El almuerzo debe estar dentro del horario de atención', error: true);
      return;
    }
    if (_dias.isEmpty) {
      mostrarMensaje(context, 'Activa al menos un día de atención', error: true);
      return;
    }
    setState(() => _guardando = true);
    final fallo = await context.read<HorarioController>().guardar(HorarioAtencion(
          horaInicio: _inicio,
          horaFin: _fin,
          almuerzoInicio: _almuerzoInicio,
          almuerzoFin: _almuerzoFin,
          dias: _dias,
        ));
    if (!mounted) return;
    setState(() => _guardando = false);
    mostrarMensaje(context, fallo ?? 'Horario guardado', error: fallo != null);
  }

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<HorarioController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mi horario')),
      body: !_cargado
          ? CuerpoAsincrono(
              cargando: controlador.error == null, // mientras no haya error ni datos, se muestra el loader
              error: controlador.error,
              vacio: true,
              alReintentar: _cargar,
              construir: (_) => const SizedBox.shrink(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _Titulo('Horario de atención'),
                Row(children: [
                  Expanded(child: _CampoHora(etiqueta: 'Inicio', valor: _inicio, alCambiar: (v) => setState(() => _inicio = v), pedir: _pedirHora)),
                  const SizedBox(width: 12),
                  Expanded(child: _CampoHora(etiqueta: 'Fin', valor: _fin, alCambiar: (v) => setState(() => _fin = v), pedir: _pedirHora)),
                ]),
                const SizedBox(height: 20),
                const _Titulo('Almuerzo'),
                Row(children: [
                  Expanded(child: _CampoHora(etiqueta: 'Inicio', valor: _almuerzoInicio, alCambiar: (v) => setState(() => _almuerzoInicio = v), pedir: _pedirHora)),
                  const SizedBox(width: 12),
                  Expanded(child: _CampoHora(etiqueta: 'Fin', valor: _almuerzoFin, alCambiar: (v) => setState(() => _almuerzoFin = v), pedir: _pedirHora)),
                ]),
                const SizedBox(height: 20),
                const _Titulo('Días de atención'),
                TarjetaSuave(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(children: [
                    for (var i = 0; i < 7; i++)
                      SwitchListTile(
                        dense: true,
                        title: Text(_nombresDias[i]),
                        value: _dias.contains(i + 1),
                        onChanged: (activo) => setState(() => activo ? _dias.add(i + 1) : _dias.remove(i + 1)),
                      ),
                  ]),
                ),
                const SizedBox(height: 22),
                BotonPrincipal(texto: 'Guardar', alPulsar: _guardar, cargando: _guardando),
              ],
            ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(texto, style: const TextStyle(fontWeight: FontWeight.w700, color: Paleta.texto)),
      );
}

class _CampoHora extends StatelessWidget {
  const _CampoHora({required this.etiqueta, required this.valor, required this.alCambiar, required this.pedir});
  final String etiqueta;
  final String valor;
  final ValueChanged<String> alCambiar;
  final Future<String?> Function(String actual) pedir;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final nueva = await pedir(valor);
          if (nueva != null) alCambiar(nueva);
        },
        child: InputDecorator(
          decoration: InputDecoration(labelText: etiqueta, suffixIcon: const Icon(Icons.access_time)),
          child: Text(valor, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
      );
}
