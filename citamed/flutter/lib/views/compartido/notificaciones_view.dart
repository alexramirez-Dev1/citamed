import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/notificaciones_controller.dart';
import '../../core/tema.dart';
import '../../widgets/tarjeta_suave.dart';
import '../../widgets/vista_estado.dart';

class NotificacionesView extends StatefulWidget {
  const NotificacionesView({super.key});

  @override
  State<NotificacionesView> createState() => _NotificacionesViewState();
}

class _NotificacionesViewState extends State<NotificacionesView> {
  static final DateFormat _formatoFecha = DateFormat("d MMM, HH:mm", 'es');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NotificacionesController>().cargar());
  }

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<NotificacionesController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (controlador.sinLeer > 0)
            TextButton(
              onPressed: controlador.marcarTodasLeidas,
              child: const Text('Marcar leídas', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controlador.cargar,
        child: CuerpoAsincrono(
          cargando: controlador.cargando,
          error: controlador.error,
          vacio: controlador.items.isEmpty,
          alReintentar: controlador.cargar,
          iconoVacio: Icons.notifications_off_outlined,
          tituloVacio: 'Sin notificaciones',
          mensajeVacio: 'Aquí verás los avisos sobre tus citas.',
          construir: (_) => ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: controlador.items.length,
            itemBuilder: (_, i) {
              final n = controlador.items[i];
              final color = Theme.of(context).colorScheme.primary;
              return TarjetaSuave(
                margen: const EdgeInsets.only(bottom: 12),
                colorBorde: n.leida ? null : color.withAlpha(120),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(n.leida ? Icons.notifications_none : Icons.notifications_active, color: n.leida ? Paleta.textoSuave : color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(n.titulo, style: const TextStyle(fontWeight: FontWeight.w700, color: Paleta.texto)),
                      const SizedBox(height: 2),
                      Text(n.mensaje, style: const TextStyle(color: Paleta.textoSuave)),
                      const SizedBox(height: 6),
                      Text(_formatoFecha.format(n.fecha), style: const TextStyle(fontSize: 12, color: Paleta.textoSuave)),
                    ]),
                  ),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }
}
