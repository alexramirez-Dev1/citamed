import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/citas_controller.dart';
import '../../core/formato.dart';
import '../../core/tema.dart';
import '../../models/horario.dart';
import '../../models/medico.dart';
import '../../widgets/formulario.dart';
import '../../widgets/mensajes.dart';
import '../../widgets/tarjeta_medico.dart';
import '../../widgets/vista_estado.dart';
import 'mis_citas_view.dart';

class ReservarCitaView extends StatefulWidget {
  const ReservarCitaView({super.key, required this.medico, required this.fechaInicial});
  final Medico medico;
  final DateTime fechaInicial;

  @override
  State<ReservarCitaView> createState() => _ReservarCitaViewState();
}

class _ReservarCitaViewState extends State<ReservarCitaView> {
  late DateTime _fecha = widget.fechaInicial;
  String? _horaElegida;
  bool _guardando = false;

  DateTime get _hoy {
    final ahora = DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarHorarios());
  }

  Future<void> _cargarHorarios() {
    setState(() => _horaElegida = null);
    return context.read<CitasController>().cargarSlots(widget.medico.id, Formato.fechaSql(_fecha));
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: _hoy,
      lastDate: _hoy.add(const Duration(days: 60)),
      helpText: 'Elige la fecha de tu cita',
    );
    if (elegida == null || !mounted) return;
    setState(() => _fecha = elegida);
    _cargarHorarios();
  }

  Future<void> _confirmar() async {
    final hora = _horaElegida;
    if (hora == null) return;
    setState(() => _guardando = true);
    final navegador = Navigator.of(context);
    final fallo = await context.read<CitasController>().reservar(
          medicoId: widget.medico.id,
          fechaSql: Formato.fechaSql(_fecha),
          hora: hora,
        );
    if (!mounted) return;
    setState(() => _guardando = false);

    if (fallo != null) {
      mostrarMensaje(context, fallo, error: true);
      _cargarHorarios(); // Quizás alguien tomó la hora; se refresca la grilla.
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check_circle_rounded, color: Paleta.confirmada, size: 52),
        title: const Text('¡Cita reservada!'),
        content: Text(
          '${widget.medico.nombre}\n${Formato.fechaLarga(_fecha)} a las $hora.\n\nTe avisaremos 24 horas y 1 hora antes.',
          textAlign: TextAlign.center,
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ver mis citas'))],
      ),
    );
    navegador.popUntil((ruta) => ruta.isFirst);
    navegador.push(MaterialPageRoute(builder: (_) => const MisCitasView()));
  }

  @override
  Widget build(BuildContext context) {
    final citas = context.watch<CitasController>();
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Reservar cita')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TarjetaMedico(medico: widget.medico, compacta: true),
          const SizedBox(height: 22),
          const Text('Fecha seleccionada', style: TextStyle(fontWeight: FontWeight.w700, color: Paleta.texto)),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _elegirFecha,
            child: InputDecorator(
              decoration: InputDecoration(prefixIcon: Icon(Icons.calendar_today_outlined, color: color), suffixIcon: const Icon(Icons.expand_more)),
              child: Text(Formato.fechaLarga(_fecha), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 22),
          const Text('Horarios disponibles', style: TextStyle(fontWeight: FontWeight.w700, color: Paleta.texto)),
          const SizedBox(height: 10),
          _Horarios(
            slots: citas.slots,
            cargando: citas.cargandoSlots,
            error: citas.errorSlots,
            elegida: _horaElegida,
            alElegir: (hora) => setState(() => _horaElegida = hora),
            alReintentar: _cargarHorarios,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: BotonPrincipal(
            texto: _horaElegida == null ? 'Elige un horario' : 'Confirmar cita · $_horaElegida',
            cargando: _guardando,
            alPulsar: _horaElegida == null ? null : _confirmar,
          ),
        ),
      ),
    );
  }
}

class _Horarios extends StatelessWidget {
  const _Horarios({
    required this.slots,
    required this.cargando,
    required this.error,
    required this.elegida,
    required this.alElegir,
    required this.alReintentar,
  });

  final List<SlotHorario> slots;
  final bool cargando;
  final String? error;
  final String? elegida;
  final ValueChanged<String> alElegir;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    if (cargando) return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CargandoVista());
    if (error != null) return ErrorVista(mensaje: error!, alReintentar: alReintentar);
    if (slots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: VacioVista(icono: Icons.event_busy_outlined, titulo: 'Sin atención este día', mensaje: 'Prueba con otra fecha.'),
      );
    }
    return Column(children: [
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.4,
        children: [
          for (final slot in slots)
            _CasillaHora(slot: slot, seleccionada: slot.hora == elegida, alPulsar: () => alElegir(slot.hora)),
        ],
      ),
      const SizedBox(height: 14),
      const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.restaurant, size: 14, color: Paleta.textoSuave),
        SizedBox(width: 6),
        Text('Almuerzo del médico  ·  Horas tachadas: ya reservadas', style: TextStyle(fontSize: 12, color: Paleta.textoSuave)),
      ]),
    ]);
  }
}

class _CasillaHora extends StatelessWidget {
  const _CasillaHora({required this.slot, required this.seleccionada, required this.alPulsar});
  final SlotHorario slot;
  final bool seleccionada;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final libre = slot.estado == EstadoSlot.libre;
    final fondo = seleccionada ? color : (libre ? Colors.white : const Color(0xFFE8EEEC));
    final textoColor = seleccionada ? Colors.white : (libre ? Paleta.texto : Paleta.textoSuave);

    return Material(
      color: fondo,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: libre ? alPulsar : null,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: libre && !seleccionada ? Paleta.borde : Colors.transparent),
          ),
          child: slot.estado == EstadoSlot.almuerzo
              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.restaurant, size: 14, color: Paleta.cancelada),
                  const SizedBox(width: 4),
                  Text(slot.hora, style: const TextStyle(fontSize: 13, color: Paleta.textoSuave)),
                ])
              : Text(
                  slot.hora,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textoColor,
                    decoration: slot.estado == EstadoSlot.ocupado ? TextDecoration.lineThrough : null,
                  ),
                ),
        ),
      ),
    );
  }
}
