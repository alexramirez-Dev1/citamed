import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:citamed/core/formato.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  test('fechaSql usa formato de MySQL', () {
    expect(Formato.fechaSql(DateTime(2026, 3, 5)), '2026-03-05');
  });
  test('fechaLarga empieza en mayúscula', () {
    final t = Formato.fechaLarga(DateTime(2026, 10, 20));
    expect(t[0], t[0].toUpperCase());
    expect(t, contains('octubre'));
  });
  test('iniciales ignora Dr./Dra.', () {
    expect(Formato.iniciales('Dr. Juan Pérez'), 'JP');
    expect(Formato.iniciales('Dra. María'), 'M');
    expect(Formato.iniciales(''), '?');
  });
  test('primerNombre', () {
    expect(Formato.primerNombre('Ana Torres'), 'Ana');
  });
}
