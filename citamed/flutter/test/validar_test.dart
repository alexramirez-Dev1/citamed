import 'package:flutter_test/flutter_test.dart';
import 'package:citamed/widgets/formulario.dart';

void main() {
  group('Validar (mismas reglas que el servidor)', () {
    test('clave exige 8 caracteres, letras y números', () {
      expect(Validar.clave('abc12'), isNotNull);
      expect(Validar.clave('aaaaaaaa'), isNotNull);
      expect(Validar.clave('12345678'), isNotNull);
      expect(Validar.clave('Demo12345'), isNull);
      expect(Validar.clave('a1' * 40), isNotNull);
    });
    test('correo', () {
      expect(Validar.correo('paciente@demo.com'), isNull);
      expect(Validar.correo('sin-arroba'), isNotNull);
    });
    test('DNI opcional de 8 dígitos', () {
      expect(Validar.dniOpcional(''), isNull);
      expect(Validar.dniOpcional('12345678'), isNull);
      expect(Validar.dniOpcional('1234'), isNotNull);
    });
    test('teléfono opcional', () {
      expect(Validar.telefonoOpcional(''), isNull);
      expect(Validar.telefonoOpcional('+51 999 999 999'), isNull);
      expect(Validar.telefonoOpcional('abc'), isNotNull);
    });
  });
}
