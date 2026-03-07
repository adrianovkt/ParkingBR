import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/payment_method.dart';
import '../models/ticket.dart';
import '../providers/parking_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class TicketDetailsPage extends StatefulWidget {
  final String ticketId;

  const TicketDetailsPage({super.key, required this.ticketId});

  @override
  _TicketDetailsPageState createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage> {
  Timer? _timer;
  PaymentMethod? _selectedPaymentMethod;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _processPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final provider = Provider.of<ParkingProvider>(context, listen: false);
      provider.checkOut(widget.ticketId, _selectedPaymentMethod!.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Text('Payment Successful! Ticket Closed.'),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<ParkingProvider>(context);
    Ticket? ticket;
    try {
      ticket = provider.tickets.firstWhere((t) => t.id == widget.ticketId);
    } catch (e) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Ticket not found')),
      );
    }

    final vehicle = provider.getVehicle(ticket.vehicleId);
    if (vehicle == null) {
      return const Scaffold(body: Center(child: Text('Vehicle not found')));
    }

    final cost = ticket.currentCost;
    final duration = DateTime.now().difference(ticket.entryTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return Scaffold(
      appBar: AppBar(title: const Text('Ticket Details'), centerTitle: true),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GlassCard(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      image: vehicle.photoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(vehicle.photoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: vehicle.photoUrl == null
                        ? Icon(
                            Icons.directions_car,
                            size: 80,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          )
                        : null,
                  ).animate().scale(
                    duration: 600.milliseconds,
                    curve: Curves.easeOutBack,
                  ),
                  const SizedBox(height: 24),
                  Text(
                        vehicle.plate,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 200.milliseconds)
                      .slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    '${vehicle.model} • ${vehicle.color}',
                    style: theme.textTheme.titleMedium,
                  ).animate().fadeIn(delay: 300.milliseconds),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Vehicle Information',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.milliseconds),
                  const Divider().animate().scaleX(
                    delay: 400.milliseconds,
                    alignment: Alignment.centerLeft,
                  ),
                  _buildAnimatedDetailRow(
                    context,
                    'Owner Name',
                    vehicle.ownerName,
                    450,
                  ),
                  _buildAnimatedDetailRow(
                    context,
                    'Owner CPF',
                    vehicle.ownerCpf,
                    500,
                  ),
                  _buildAnimatedDetailRow(
                    context,
                    'Contact',
                    vehicle.ownerContact,
                    550,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Stay Information',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.milliseconds),
                  const Divider().animate().scaleX(
                    delay: 600.milliseconds,
                    alignment: Alignment.centerLeft,
                  ),
                  _buildAnimatedDetailRow(
                    context,
                    'Entry Time',
                    DateFormat('dd/MM/yyyy HH:mm').format(ticket.entryTime),
                    650,
                  ),
                  _buildAnimatedDetailRow(
                    context,
                    'Duration',
                    '${hours}h ${minutes}m',
                    700,
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Total Amount',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                        NumberFormat.currency(symbol: 'R\$').format(cost),
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .shimmer(duration: 2.seconds),
                ],
              ),
            ).animate().fadeIn(delay: 800.milliseconds).scale(),
            const SizedBox(height: 32),
            if (ticket.status == TicketStatus.active) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Payment Method',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().fadeIn(delay: 900.milliseconds),
              const SizedBox(height: 16),
              ...provider.paymentMethods.asMap().entries.map((entry) {
                final index = entry.key;
                final method = entry.value;
                final isSelected = _selectedPaymentMethod?.id == method.id;
                return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedPaymentMethod = method),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: 300.milliseconds,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withOpacity(0.1)
                                : theme.colorScheme.surface,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(method.icon, color: method.color, size: 32),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      method.name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if (method.details != null)
                                      Text(
                                        method.details!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                ).animate().scale(),
                            ],
                          ),
                        ),
                      ),
                    )
                    .animate(delay: (1000 + (index * 50)).milliseconds)
                    .fadeIn()
                    .slideX(begin: 0.1);
              }),
              const SizedBox(height: 32),
              GradientButton(
                    text: 'Confirm Payment',
                    onTap: _processPayment,
                    isLoading: _isLoading,
                  )
                  .animate()
                  .fadeIn(delay: 1200.milliseconds)
                  .scale(curve: Curves.easeOutBack),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ).animate().scale(
                      duration: 600.milliseconds,
                      curve: Curves.easeOutBack,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Paid & Completed',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 200.milliseconds),
                    const SizedBox(height: 8),
                    Text(
                      'Exit Time: ${DateFormat('HH:mm').format(ticket.exitTime ?? DateTime.now())}',
                      style: theme.textTheme.bodyMedium,
                    ).animate().fadeIn(delay: 400.milliseconds),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.2),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDetailRow(
    BuildContext context,
    String label,
    String value,
    int delayMs,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ).animate(delay: delayMs.milliseconds).fadeIn().slideX(begin: 0.05);
  }
}
