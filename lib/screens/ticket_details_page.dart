import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/payment_method.dart';
import '../models/ticket.dart';
import '../providers/parking_provider.dart';
import '../utils/plate_validator.dart';

class TicketDetailsPage extends StatefulWidget {
  final String ticketId;

  const TicketDetailsPage({super.key, required this.ticketId});

  @override
  State<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage> {
  Timer? _timer;
  PaymentMethod? _selectedPaymentMethod;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _registerExit() async {
    final paymentMethod = _selectedPaymentMethod;
    if (_isLoading || paymentMethod == null) {
      if (paymentMethod == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione como o valor foi recebido')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<ParkingProvider>().checkOut(
        widget.ticketId,
        paymentMethod.id,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Recebimento e saída registrados')),
      );
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parking = context.watch<ParkingProvider>();
    final ticket = parking.getTicket(widget.ticketId);
    if (ticket == null) {
      return const Scaffold(
        body: Center(child: Text('Permanência não encontrada')),
      );
    }
    if (ticket.status == TicketStatus.completed) {
      _timer?.cancel();
      _timer = null;
    }

    final vehicle = parking.getVehicle(ticket.vehicleId);
    final candidateEnd = ticket.exitTime ?? DateTime.now();
    final end = candidateEnd.isBefore(ticket.entryTime)
        ? ticket.entryTime
        : candidateEnd;
    final duration = end.toUtc().difference(ticket.entryTime.toUtc());
    final amountCents = ticket.currentCostCents(end);
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Permanência')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.directions_car_filled_rounded,
                size: 44,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            PlateValidator.format(ticket.plateAtEntry),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (vehicle != null &&
              (vehicle.model.isNotEmpty || vehicle.color.isNotEmpty))
            Text(
              [
                vehicle.model,
                vehicle.color,
              ].where((value) => value.isNotEmpty).join(' • '),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _DetailRow(label: 'Número', value: ticket.id),
                  _DetailRow(
                    label: 'Entrada',
                    value: DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(ticket.entryTime.toLocal()),
                  ),
                  _DetailRow(
                    label: ticket.exitTime == null ? 'Tempo atual' : 'Duração',
                    value: _durationLabel(duration),
                  ),
                  if (ticket.exitTime != null)
                    _DetailRow(
                      label: 'Saída',
                      value: DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(ticket.exitTime!.toLocal()),
                    ),
                  if (vehicle != null && vehicle.ownerName.isNotEmpty)
                    _DetailRow(label: 'Proprietário', value: vehicle.ownerName),
                  _DetailRow(
                    label: 'Tarifa',
                    value: _pricingLabel(ticket, currency),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    ticket.exitTime == null ? 'Valor atual' : 'Valor recebido',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currency.format(amountCents / 100),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (ticket.receivedVia != null) ...[
                    const SizedBox(height: 8),
                    Text(_paymentLabel(ticket.receivedVia!)),
                  ],
                ],
              ),
            ),
          ),
          if (ticket.status == TicketStatus.active) ...[
            const SizedBox(height: 24),
            Text('Registrar recebimento', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'PIX e cartão são confirmações informadas pelo operador.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            RadioGroup<PaymentMethod>(
              groupValue: _selectedPaymentMethod,
              onChanged: _isLoading
                  ? (_) {}
                  : (value) {
                      setState(() => _selectedPaymentMethod = value);
                    },
              child: Column(
                children: parking.paymentMethods
                    .map((method) {
                      return RadioListTile<PaymentMethod>(
                        value: method,
                        enabled: !_isLoading,
                        secondary: Icon(method.icon, color: method.color),
                        title: Text(method.name),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isLoading ? null : _registerExit,
              icon: _isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout_rounded),
              label: const Text('Registrar recebimento e saída'),
            ),
          ],
        ],
      ),
    );
  }

  String _durationLabel(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}min';
  }

  String _paymentLabel(String method) {
    return switch (method) {
      'cash' => 'Dinheiro',
      'pix' => 'PIX confirmado',
      'card' => 'Cartão na maquininha',
      'free' => 'Isento',
      _ => 'Não informado',
    };
  }

  String _pricingLabel(Ticket ticket, NumberFormat currency) {
    final graceMinutes = ticket.graceSeconds ~/ 60;
    final origin = ticket.pricingOrigin == PricingOrigin.legacyDefault
        ? 'Regra legada • '
        : '';
    return '$origin$graceMinutes min de tolerância • '
        '${currency.format(ticket.firstHourCents / 100)} na primeira hora • '
        '${currency.format(ticket.extraHourCents / 100)} por hora adicional';
  }

  String _message(Object error) => error.toString().replaceFirst(
    RegExp(r'^(Bad state|Invalid argument): '),
    '',
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
