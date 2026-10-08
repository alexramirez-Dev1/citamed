import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/notificaciones_controller.dart';
import '../views/compartido/notificaciones_view.dart';

/// Campana del AppBar con el contador de avisos sin leer.
class CampanaNotificaciones extends StatelessWidget {
  const CampanaNotificaciones({super.key});

  @override
  Widget build(BuildContext context) {
    final sinLeer = context.select<NotificacionesController, int>((c) => c.sinLeer);
    return IconButton(
      tooltip: 'Notificaciones',
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificacionesView())),
      icon: Badge(
        isLabelVisible: sinLeer > 0,
        label: Text('$sinLeer'),
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}
