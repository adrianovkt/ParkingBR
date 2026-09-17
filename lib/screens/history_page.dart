import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/ticket.dart';
import '../providers/parking_provider.dart';
import '../utils/plate_validator.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tickets = context.watch<ParkingProvider>().completedTickets;
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de saídas')),
      body: tickets.isEmpty
          ? const Center(child: Text('Nenhuma saída registrada ainda.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return _HistoryTile(ticket: ticket);
              },
            ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Ticket ticket;

  const _HistoryTile({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final exit = ticket.exitTime!;
    final duration = exit.difference(ticket.entryTime);
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Card(
      child: ListTile(
        onTap: () => context.push('/ticket/${ticket.id}'),
        leading: const CircleAvatar(child: Icon(Icons.logout_rounded)),
        title: Text(
          PlateValidator.format(ticket.plateAtEntry),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${DateFormat('dd/MM/yyyy HH:mm').format(exit.toLocal())}'
          ' • ${_durationLabel(duration)}'
          ' • ${_paymentLabel(ticket.receivedVia)}',
        ),
        trailing: Text(
          currency.format((ticket.amountCents ?? 0) / 100),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _durationLabel(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}min';
  }

  String _paymentLabel(String? method) {
    return switch (method) {
      'cash' => 'Dinheiro',
      'pix' => 'PIX',
      'card' => 'Cartão',
      'free' => 'Isento',
      _ => 'Não informado',
    };
  }
}
