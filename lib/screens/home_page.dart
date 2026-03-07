import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parking_br/models/ticket.dart';
import 'package:parking_br/models/vehicle.dart';
import 'package:parking_br/providers/parking_provider.dart';
import 'package:parking_br/widgets/vehicle_card.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<ParkingProvider>(context);
    final vehicles = provider.vehicles;
    final activeTickets = provider.tickets
        .where((t) => t.status == TicketStatus.active)
        .toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Parking BR',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.wallet),
            onPressed: () => context.push('/wallet'),
          ).animate().fadeIn(delay: 200.milliseconds).scale(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ).animate().fadeIn(delay: 300.milliseconds).scale(),
        ],
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/check-in'),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ).animate().scale(delay: 400.milliseconds, curve: Curves.easeOutBack),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsHeader(context, activeTickets),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Parked Vehicles',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 500.milliseconds).slideX(begin: -0.2),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ).animate().fadeIn(delay: 600.milliseconds),
              ],
            ),
            const SizedBox(height: 16),
            if (vehicles.isEmpty)
              _buildEmptyState(context)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  final ticket = provider.getActiveTicketForVehicle(vehicle.id);
                  return VehicleCard(
                        vehicle: vehicle,
                        activeTicket: ticket,
                        onTap: () {
                          if (ticket != null) {
                            context.push('/ticket/${ticket.id}');
                          } else {
                            _showActionSheet(context, vehicle);
                          }
                        },
                      )
                      .animate(delay: (100 * index + 600).milliseconds)
                      .fadeIn(duration: 500.milliseconds)
                      .slideY(begin: 0.2, curve: Curves.easeOutQuad);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, List<Ticket> activeTickets) {
    final theme = Theme.of(context);
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Status',
                style: GoogleFonts.lexend(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${activeTickets.length}',
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().shimmer(
                        delay: 1.seconds,
                        duration: 2.seconds,
                      ),
                      Text(
                        'Vehicles Parked',
                        style: GoogleFonts.lexend(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.local_parking,
                          color: Colors.white,
                          size: 32,
                        ),
                      )
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 1.seconds,
                        curve: Curves.easeInOut,
                      ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.milliseconds)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(
                Icons.directions_car_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shake(hz: 2, duration: 2.seconds),
          const SizedBox(height: 16),
          Text(
            'No vehicles registered yet.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  void _showActionSheet(BuildContext context, Vehicle vehicle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Actions for ${vehicle.plate}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(
                Icons.timer,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Check In'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onTap: () {
                context.pop();
                final provider = Provider.of<ParkingProvider>(
                  context,
                  listen: false,
                );
                provider.checkIn(vehicle.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    content: Text('Vehicle ${vehicle.plate} checked in!'),
                  ),
                );
              },
            ).animate().fadeIn(delay: 100.milliseconds).slideX(),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Details'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onTap: () {
                context.pop();
              },
            ).animate().fadeIn(delay: 200.milliseconds).slideX(),
          ],
        ),
      ),
    );
  }
}
