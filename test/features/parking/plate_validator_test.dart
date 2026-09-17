import 'package:flutter_test/flutter_test.dart';
import 'package:parking_br/utils/plate_validator.dart';

void main() {
  group('PlateValidator', () {
    test('canoniza letras, espaços e hífen', () {
      expect(PlateValidator.canonical(' abc-1d23 '), 'ABC1D23');
    });

    test('identifica placas antigas e Mercosul', () {
      expect(PlateValidator.identify('ABC-1234'), PlateType.old);
      expect(PlateValidator.identify('abc1d23'), PlateType.mercosul);
    });

    test('rejeita formatos inválidos', () {
      expect(PlateValidator.identify('ABCD123'), PlateType.invalid);
      expect(PlateValidator.identify('ABC-12'), PlateType.invalid);
      expect(PlateValidator.identify('ABC@123'), PlateType.invalid);
    });

    test('formata somente placas antigas com hífen', () {
      expect(PlateValidator.format('abc1234'), 'ABC-1234');
      expect(PlateValidator.format('abc1d23'), 'ABC1D23');
    });
  });
}
