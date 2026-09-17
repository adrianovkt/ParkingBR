import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/ticket.dart';
import '../models/vehicle.dart';
import '../utils/plate_validator.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final Ticket? activeTicket;
  final VoidCallback? onTap;

  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.activeTicket,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final details = [
      vehicle.model,
      vehicle.color,
    ].where((value) => value.isNotEmpty).join(' • ');
    final ticket = activeTicket;
    final activeSummary = ticket == null ? null : _activeSummary(ticket);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: CircleAvatar(
          child: Icon(
            activeTicket == null
                ? Icons.directions_car_outlined
                : Icons.local_parking_rounded,
          ),
        ),
        title: Text(
          PlateValidator.format(vehicle.plate),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details.isNotEmpty) Text(details),
            if (activeSummary != null)
              Text(activeSummary)
            else
              const Text('Fora do pátio'),
          ],
        ),
        trailing: Icon(
          activeTicket == null
              ? Icons.more_horiz_rounded
              : Icons.chevron_right_rounded,
        ),
      ),
    );
  }

  String _activeSummary(Ticket ticket) {
    final entry = ticket.entryTime.toUtc();
    final now = DateTime.now().toUtc();
    final effectiveNow = now.isBefore(entry) ? entry : now;
    final duration = effectiveNow.difference(entry);
    final safeDuration = duration.isNegative ? Duration.zero : duration;
    final hours = safeDuration.inHours;
    final minutes = safeDuration.inMinutes.remainder(60);
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return '${hours}h ${minutes}min • '
        '${currency.format(ticket.currentCostCents(effectiveNow) / 100)}';
  }
}
