enum TicketStatus { active, paid, completed }

class Ticket {
  final String id;
  final String vehicleId;
  final DateTime entryTime;
  DateTime? exitTime;
  TicketStatus status;
  double paidAmount;
  String? paymentMethodId;

  Ticket({
    required this.id,
    required this.vehicleId,
    required this.entryTime,
    this.exitTime,
    this.status = TicketStatus.active,
    this.paidAmount = 0.0,
    this.paymentMethodId,
  });

  double get currentCost {
    final now = DateTime.now();
    final endTime = exitTime ?? now;
    final duration = endTime.difference(entryTime);
    if (duration.inMinutes <= 15) return 0.0;

    double cost = 10.0;
    if (duration.inMinutes > 60) {
      final extraMinutes = duration.inMinutes - 60;
      final extraHours = (extraMinutes / 60).ceil();
      cost += extraHours * 5.0;
    }

    return cost;
  }

  Duration get duration {
    final endTime = exitTime ?? DateTime.now();
    return endTime.difference(entryTime);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'entryTime': entryTime.toIso8601String(),
        'exitTime': exitTime?.toIso8601String(),
        'status': status.name,
        'paidAmount': paidAmount,
        'paymentMethodId': paymentMethodId,
      };

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
        id: json['id'],
        vehicleId: json['vehicleId'],
        entryTime: DateTime.parse(json['entryTime']),
        exitTime: json['exitTime'] != null ? DateTime.parse(json['exitTime']) : null,
        status: TicketStatus.values.byName(json['status']),
        paidAmount: (json['paidAmount'] as num).toDouble(),
        paymentMethodId: json['paymentMethodId'],
      );
}
