import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/catalogo_controller.dart';
import '../../core/tema.dart';
import '../../widgets/avatares.dart';
import '../../widgets/tarjeta_suave.dart';
import '../../widgets/vista_estado.dart';
import 'medicos_view.dart';

class EspecialidadesView extends StatefulWidget {
  const EspecialidadesView({super.key, this.titulo = 'Especialidades'});
  final String titulo;

  @override
  State<EspecialidadesView> createState() => _EspecialidadesViewState();
}

class _EspecialidadesViewState extends State<EspecialidadesView> {
  final _busqueda = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CatalogoController>().cargarEspecialidades());
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = context.watch<CatalogoController>();
    final filtro = _busqueda.text.trim().toLowerCase();
    final visibles = catalogo.especialidades.where((e) => e.nombre.toLowerCase().contains(filtro)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: TextField(
            controller: _busqueda,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Buscar especialidad...', prefixIcon: Icon(Icons.search)),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: catalogo.cargarEspecialidades,
            child: CuerpoAsincrono(
              cargando: catalogo.cargandoEspecialidades,
              error: catalogo.errorEspecialidades,
              vacio: visibles.isEmpty,
              alReintentar: catalogo.cargarEspecialidades,
              iconoVacio: Icons.search_off,
              tituloVacio: filtro.isEmpty ? 'Aún no hay especialidades' : 'Sin resultados',
              mensajeVacio: filtro.isEmpty ? null : 'Prueba con otro nombre.',
              construir: (_) => ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: visibles.length,
                itemBuilder: (_, i) {
                  final esp = visibles[i];
                  return TarjetaSuave(
                    margen: const EdgeInsets.only(bottom: 12),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedicosView(especialidad: esp))),
                    child: Row(children: [
                      IconoEspecialidad(clave: esp.icono),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(esp.nombre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Paleta.texto)),
                          Text(esp.descripcion, style: const TextStyle(color: Paleta.textoSuave, fontSize: 13)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right, color: Paleta.textoSuave),
                    ]),
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
