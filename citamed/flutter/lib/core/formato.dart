import 'package:intl/intl.dart';

/// Formatos de fecha y texto usados en varias pantallas (requiere initializeDateFormatting('es')).
class Formato {
  static final DateFormat _largo = DateFormat("EEEE, d 'de' MMMM 'de' y", 'es');
  static final DateFormat _corto = DateFormat("d MMM y", 'es');
  static final DateFormat _sql = DateFormat('yyyy-MM-dd');
  static final DateFormat _diaSemana = DateFormat('EEE', 'es');

  static String fechaLarga(DateTime f) {
    final t = _largo.format(f);
    return t[0].toUpperCase() + t.substring(1);
  }

  static String fechaCorta(DateTime f) => _corto.format(f);
  static String fechaSql(DateTime f) => _sql.format(f);

  /// "Lun", "Mar"... con la primera en mayúscula y sin punto.
  static String diaAbreviado(DateTime f) {
    final t = _diaSemana.format(f).replaceAll('.', '');
    return t[0].toUpperCase() + t.substring(1);
  }

  static String iniciales(String nombre) {
    final partes = nombre
        .replaceAll(RegExp(r'^(Dr\.|Dra\.)\s*'), '')
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes[0][0] + partes[1][0]).toUpperCase();
  }

  static String primerNombre(String nombre) {
    final partes = nombre.split(' ').where((p) => p.isNotEmpty).toList();
    return partes.isEmpty ? nombre : partes.first;
  }
}
