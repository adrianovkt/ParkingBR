import '../features/parking/domain/pricing.dart';

enum TicketStatus { active, completed }

enum PricingOrigin { configured, legacyDefault }

class Ticket {
  final String id;
  final String vehicleId;
  final String plateAtEntry;
  final DateTime entryTime;
  final DateTime? exitTime;
  final int graceSeconds;
  final int firstHourCents;
  final int extraHourCents;
  final PricingOrigin pricingOrigin;
  final int? amountCents;
  final String? receivedVia;

  Ticket({
    required this.id,
    required this.vehicleId,
    required this.plateAtEntry,
    required this.entryTime,
    this.exitTime,
    this.graceSeconds = 15 * 60,
    this.firstHourCents = 1000,
    this.extraHourCents = 500,
    this.pricingOrigin = PricingOrigin.configured,
    this.amountCents,
    this.receivedVia,
  });

  TicketStatus get status =>
      exitTime == null ? TicketStatus.active : TicketStatus.completed;

  int currentCostCents([DateTime? now]) =>
      amountCents ??
      calculateCostCents(
        entry: entryTime,
        exit: now ?? DateTime.now(),
        graceSeconds: graceSeconds,
        firstHourCents: firstHourCents,
        extraHourCents: extraHourCents,
      );

  double get currentCost => currentCostCents() / 100;
  double get paidAmount => (amountCents ?? 0) / 100;
  String? get paymentMethodId => receivedVia;

  Duration get duration {
    final endTime = exitTime ?? DateTime.now();
    return endTime.difference(entryTime);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicleId': vehicleId,
    'plateAtEntry': plateAtEntry,
    'entryTime': entryTime.toIso8601String(),
    'exitTime': exitTime?.toIso8601String(),
    'status': status.name,
    'paidAmount': paidAmount,
    'paymentMethodId': receivedVia,
  };

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
    id: json['id'],
    vehicleId: json['vehicleId'],
    plateAtEntry: json['plateAtEntry'] as String? ?? '',
    entryTime: DateTime.parse(json['entryTime']),
    exitTime: json['exitTime'] != null
        ? DateTime.parse(json['exitTime'])
        : null,
    amountCents: json['exitTime'] == null
        ? null
        : (((json['paidAmount'] as num?) ?? 0) * 100).round(),
    receivedVia: json['exitTime'] == null
        ? null
        : _legacyPaymentType(json['paymentMethodId'] as String?),
  );

  factory Ticket.fromDatabase(Map<String, Object?> row) => Ticket(
    id: row['id']! as String,
    vehicleId: row['vehicle_id']! as String,
    plateAtEntry: row['plate_at_entry']! as String,
    entryTime: DateTime.fromMillisecondsSinceEpoch(
      row['entered_at_ms']! as int,
      isUtc: true,
    ),
    exitTime: row['exited_at_ms'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            row['exited_at_ms']! as int,
            isUtc: true,
          ),
    graceSeconds: row['grace_seconds']! as int,
    firstHourCents: row['first_hour_cents']! as int,
    extraHourCents: row['extra_hour_cents']! as int,
    pricingOrigin: switch (row['pricing_origin']) {
      'legacy_default' => PricingOrigin.legacyDefault,
      _ => PricingOrigin.configured,
    },
    amountCents: row['amount_cents'] as int?,
    receivedVia: row['received_via'] as String?,
  );
}

String _legacyPaymentType(String? value) {
  return switch (value) {
    '3' || 'pix' => 'pix',
    '4' || 'cash' => 'cash',
    'free' => 'free',
    '1' || '2' || 'card' => 'card',
    _ => throw const FormatException('Forma de recebimento legada inválida'),
  };
}
