import 'package:flutter/material.dart';
import '../core/tema.dart';

void mostrarMensaje(BuildContext context, String texto, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto), backgroundColor: error ? Paleta.cancelada : Paleta.texto));
}

Future<bool> confirmar(BuildContext context, {required String titulo, required String mensaje, String accion = 'Confirmar'}) async {
  final respuesta = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(100, 42)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(accion),
        ),
      ],
    ),
  );
  return respuesta ?? false;
}
