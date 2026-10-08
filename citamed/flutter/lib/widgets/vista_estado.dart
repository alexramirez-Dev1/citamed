import 'package:flutter/material.dart';
import '../core/tema.dart';

class CargandoVista extends StatelessWidget {
  const CargandoVista({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class VacioVista extends StatelessWidget {
  const VacioVista({super.key, required this.icono, required this.titulo, this.mensaje});
  final IconData icono;
  final String titulo;
  final String? mensaje;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icono, size: 56, color: Paleta.textoSuave.withAlpha(140)),
            const SizedBox(height: 14),
            Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Paleta.texto)),
            if (mensaje != null) ...[
              const SizedBox(height: 6),
              Text(mensaje!, textAlign: TextAlign.center, style: const TextStyle(color: Paleta.textoSuave)),
            ],
          ]),
        ),
      );
}

class ErrorVista extends StatelessWidget {
  const ErrorVista({super.key, required this.mensaje, required this.alReintentar});
  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: Paleta.cancelada),
            const SizedBox(height: 14),
            Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(color: Paleta.texto)),
            const SizedBox(height: 16),
            SizedBox(width: 180, child: OutlinedButton.icon(onPressed: alReintentar, icon: const Icon(Icons.refresh), label: const Text('Reintentar'))),
          ]),
        ),
      );
}

/// Decide qué mostrar según el estado de una carga: loader, error, vacío o contenido.
/// Si ya hay datos y se está refrescando, se siguen mostrando.
class CuerpoAsincrono extends StatelessWidget {
  const CuerpoAsincrono({
    super.key,
    required this.cargando,
    required this.error,
    required this.vacio,
    required this.alReintentar,
    required this.construir,
    this.iconoVacio = Icons.inbox_outlined,
    this.tituloVacio = 'Nada por aquí',
    this.mensajeVacio,
  });

  final bool cargando;
  final String? error;
  final bool vacio;
  final VoidCallback alReintentar;
  final WidgetBuilder construir;
  final IconData iconoVacio;
  final String tituloVacio;
  final String? mensajeVacio;

  @override
  Widget build(BuildContext context) {
    if (vacio && cargando) return const CargandoVista();
    if (vacio && error != null) return ErrorVista(mensaje: error!, alReintentar: alReintentar);
    if (vacio) {
      // Dentro de un scroll para que el "tirar para refrescar" también funcione en estado vacío.
      return LayoutBuilder(
        builder: (context, caja) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: caja.maxHeight,
            child: VacioVista(icono: iconoVacio, titulo: tituloVacio, mensaje: mensajeVacio),
          ),
        ),
      );
    }
    return construir(context);
  }
}
