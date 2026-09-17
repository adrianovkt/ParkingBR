import 'package:flutter_test/flutter_test.dart';
import 'package:parking_br/features/parking/domain/pricing.dart';

void main() {
  final entry = DateTime.utc(2026, 1, 1, 12);

  group('calculateCostCents', () {
    test('aplica tolerância até o limite exato', () {
      expect(
        calculateCostCents(
          entry: entry,
          exit: entry.add(const Duration(minutes: 15)),
        ),
        0,
      );
    });

    test('cobra a primeira hora após a tolerância', () {
      expect(
        calculateCostCents(
          entry: entry,
          exit: entry.add(const Duration(minutes: 15, microseconds: 1)),
        ),
        1000,
      );
      expect(
        calculateCostCents(
          entry: entry,
          exit: entry.add(const Duration(hours: 1)),
        ),
        1000,
      );
    });

    test('arredonda cada hora adicional iniciada', () {
      expect(
        calculateCostCents(
          entry: entry,
          exit: entry.add(const Duration(hours: 1, microseconds: 1)),
        ),
        1500,
      );
      expect(
        calculateCostCents(
          entry: entry,
          exit: entry.add(const Duration(hours: 2)),
        ),
        1500,
      );
      expect(
        calculateCostCents(
          entry: entry,
          exit: entry.add(const Duration(hours: 2, microseconds: 1)),
        ),
        2000,
      );
    });

    test('usa valores inteiros configurados em centavos', () {
      expect(
        calculateCostCents(
          entry: entry,
          exit: entry.add(const Duration(hours: 3)),
          graceSeconds: 0,
          firstHourCents: 1234,
          extraHourCents: 567,
        ),
        2368,
      );
    });

    test('rejeita saída anterior e tarifa inválida', () {
      expect(
        () => calculateCostCents(
          entry: entry,
          exit: entry.subtract(const Duration(seconds: 1)),
        ),
        throwsArgumentError,
      );
      expect(
        () => calculateCostCents(entry: entry, exit: entry, graceSeconds: -1),
        throwsArgumentError,
      );
    });
  });
}
