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
}
