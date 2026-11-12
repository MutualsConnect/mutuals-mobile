import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/features/auth/domain/validators.dart';

void main() {
  group('email', () {
    test('acepta correos válidos', () {
      expect(Validators.email('ana@utec.edu.pe'), isNull);
    });
    test('rechaza vacío y mal formado', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('ana@'), isNotNull);
      expect(Validators.email('ana utec@x.com'), isNotNull);
    });
  });

  group('username', () {
    test('acepta minúsculas, números, punto y guion bajo', () {
      expect(Validators.username('ana.lopez_9'), isNull);
    });
    test('rechaza mayúsculas, cortos y símbolos', () {
      expect(Validators.username('Ana'), isNotNull);
      expect(Validators.username('ab'), isNotNull);
      expect(Validators.username('ana!'), isNotNull);
    });
  });

  group('strongPassword', () {
    test('acepta una contraseña fuerte', () {
      expect(Validators.strongPassword('Prueba!2026x'), isNull);
    });
    test('pide cada requisito que falta', () {
      expect(Validators.strongPassword('Ab1!'), contains('8'));
      expect(Validators.strongPassword('prueba!2026x'), contains('mayúscula'));
      expect(Validators.strongPassword('PRUEBA!2026X'), contains('minúscula'));
      expect(Validators.strongPassword('Prueba!!!!x'), contains('número'));
      expect(Validators.strongPassword('Prueba2026xx'), contains('símbolo'));
    });
  });
}
