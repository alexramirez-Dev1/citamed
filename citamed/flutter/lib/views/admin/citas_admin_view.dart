import 'package:flutter/material.dart';
import '../../widgets/acciones_cita.dart';
import '../../widgets/lista_citas.dart';

/// Monitor global de citas con filtro por estado.
class CitasAdminView extends StatefulWidget {
  const CitasAdminView({super.key});

  @override
  State<CitasAdminView> createState() => _CitasAdminViewState();
}

class _CitasAdminViewState extends State<CitasAdminView> {
  static const _filtros = <(String etiqueta, String? estado)>[
    ('Todas', null),
    ('Pendientes', 'Pendiente'),
    ('Confirmadas', 'Confirmada'),
    ('Atendidas', 'Atendida'),
  ];
  String? _estado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Citas - Admin')),
      body: Column(children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              for (final (etiqueta, estado) in _filtros)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(etiqueta),
                    selected: _estado == estado,
                    onSelected: (_) => setState(() => _estado = estado),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListaCitas(
            key: ValueKey(_estado),
            estado: _estado,
            mostrarPaciente: true,
            tituloVacio: 'No hay citas con este filtro',
            alTocar: (cita) => mostrarAccionesCita(context, cita, mostrarPaciente: true, acciones: transicionesAdmin(cita)),
          ),
        ),
      ]),
    );
  }
}
