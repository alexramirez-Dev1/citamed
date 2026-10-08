import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/catalogo_controller.dart';
import '../../core/formato.dart';
import '../../models/especialidad.dart';
import '../../widgets/tarjeta_medico.dart';
import '../../widgets/vista_estado.dart';
import 'reservar_cita_view.dart';

class MedicosView extends StatefulWidget {
  const MedicosView({super.key, required this.especialidad});
  final Especialidad especialidad;

  @override
  State<MedicosView> createState() => _MedicosViewState();
}

class _MedicosViewState extends State<MedicosView> {
  late final List<DateTime> _dias = () {
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    return List.generate(7, (i) => inicio.add(Duration(days: i)));
  }();
  int _elegido = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargar());
  }

  Future<void> _cargar() => context.read<CatalogoController>().cargarMedicos(especialidadId: widget.especialidad.id);

  @override
  Widget build(BuildContext context) {
    final catalogo = context.watch<CatalogoController>();
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text('Médicos - ${widget.especialidad.nombre}')),
      body: Column(children: [
        // Fechas rápidas: el día elegido viaja a la pantalla de reserva.
        Container(
          color: color,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _dias.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final dia = _dias[i];
              final activo = i == _elegido;
              return GestureDetector(
                onTap: () => setState(() => _elegido = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 56,
                  decoration: BoxDecoration(
                    color: activo ? Colors.white : Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(Formato.diaAbreviado(dia), style: TextStyle(fontSize: 12, color: activo ? color : Colors.white)),
                    const SizedBox(height: 2),
                    Text('${dia.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: activo ? color : Colors.white)),
                  ]),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargar,
            child: CuerpoAsincrono(
              cargando: catalogo.cargandoMedicos,
              error: catalogo.errorMedicos,
              vacio: catalogo.medicos.isEmpty,
              alReintentar: _cargar,
              iconoVacio: Icons.person_search_outlined,
              tituloVacio: 'Sin médicos disponibles',
              mensajeVacio: 'Aún no hay médicos activos en ${widget.especialidad.nombre}.',
              construir: (_) => ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: catalogo.medicos.length,
                itemBuilder: (_, i) {
                  final medico = catalogo.medicos[i];
                  return TarjetaMedico(
                    medico: medico,
                    alTocar: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ReservarCitaView(medico: medico, fechaInicial: _dias[_elegido])),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
