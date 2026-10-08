import 'package:flutter_test/flutter_test.dart';
import 'package:citamed/core/json_util.dart';
import 'package:citamed/models/cita.dart';
import 'package:citamed/models/usuario.dart';

void main() {
  group('json_util (datos que llegan de PHP/MySQL)', () {
    test('aInt acepta número, texto y valores inválidos', () {
      expect(aInt(5), 5);
      expect(aInt('12'), 12);
      expect(aInt(3.9), 3);
      expect(aInt(null), 0);
      expect(aInt('abc'), 0);
    });
    test('aDouble y aBool', () {
      expect(aDouble('4.5'), 4.5);
      expect(aDouble(null), 0);
      expect(aBool(1), isTrue);
      expect(aBool('1'), isTrue);
      expect(aBool(0), isFalse);
    });
  });

  group('Cita', () {
    final json = {
      'id': '7', 'paciente_id': 3, 'paciente': 'Ana', 'medico_id': '2', 'medico': 'Dr. Juan',
      'especialidad': 'Cardiología', 'icono': 'favorite', 'cmp': '12345',
      'fecha': '2026-10-20', 'hora': '09:30', 'estado': 'Confirmada',
    };
    test('fromJson convierte ids en texto y el estado', () {
      final c = Cita.fromJson(json);
      expect(c.id, 7);
      expect(c.medicoId, 2);
      expect(c.estado, EstadoCita.confirmada);
      expect(c.esActiva, isTrue);
    });
    test('inicio combina fecha y hora', () {
      expect(Cita.fromJson(json).inicio, DateTime(2026, 10, 20, 9, 30));
    });
    test('estado desconocido cae en Pendiente', () {
      expect(EstadoCita.desde('XYZ'), EstadoCita.pendiente);
    });
    test('Cancelada y Atendida no son activas', () {
      expect(Cita.fromJson({...json, 'estado': 'Cancelada'}).esActiva, isFalse);
      expect(Cita.fromJson({...json, 'estado': 'Atendida'}).esActiva, isFalse);
    });
    test('fecha u hora inválidas no rompen la app', () {
      final c = Cita.fromJson({...json, 'fecha': null, 'hora': 'mal'});
      expect(c.hora, '00:00');
      expect(c.fecha, DateTime(1970));
    });
    test('hora con segundos de MySQL se recorta', () {
      expect(Cita.fromJson({...json, 'hora': '14:00:00'}).hora, '14:00');
    });
  });

  group('Usuario y roles', () {
    test('rol según rol_id', () {
      expect(Rol.desdeId(1), Rol.paciente);
      expect(Rol.desdeId(2), Rol.medico);
      expect(Rol.desdeId(3), Rol.admin);
      expect(Rol.desdeId(99), Rol.paciente);
    });
    test('fromJson con médico e inactivo', () {
      final u = Usuario.fromJson({'id': '4', 'nombre': 'Luis', 'email': 'l@d.com', 'rol_id': '2', 'estado': 'Inactivo', 'medico_id': '9'});
      expect(u.rol, Rol.medico);
      expect(u.activo, isFalse);
      expect(u.medicoId, 9);
    });
  });
}
