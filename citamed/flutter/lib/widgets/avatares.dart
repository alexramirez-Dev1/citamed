import 'package:flutter/material.dart';
import '../core/formato.dart';
import '../core/iconos.dart';

/// Círculo con las iniciales del médico (la base de datos no guarda fotos).
class AvatarIniciales extends StatelessWidget {
  const AvatarIniciales({super.key, required this.nombre, this.radio = 28, this.color});
  final String nombre;
  final double radio;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.primary;
    return CircleAvatar(
      radius: radio,
      backgroundColor: base.withAlpha(30),
      child: Text(
        Formato.iniciales(nombre),
        style: TextStyle(color: base, fontWeight: FontWeight.w800, fontSize: radio * 0.64),
      ),
    );
  }
}

/// Ícono de especialidad dentro de un círculo de color suave.
class IconoEspecialidad extends StatelessWidget {
  const IconoEspecialidad({super.key, required this.clave, this.tamano = 46, this.apagado = false});
  final String clave;
  final double tamano;
  final bool apagado;

  @override
  Widget build(BuildContext context) {
    final color = apagado ? Colors.grey : Iconos.colorDe(clave);
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(color: color.withAlpha(32), shape: BoxShape.circle),
      child: Icon(Iconos.de(clave), color: color, size: tamano * 0.5),
    );
  }
}
