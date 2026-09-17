import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/ticket.dart';
import '../models/vehicle.dart';
import '../providers/parking_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/plate_validator.dart';
import '../widgets/vehicle_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  Timer? _timer;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parking = context.watch<ParkingProvider>();
    final settings = context.watch<SettingsProvider>();
    if (parking.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (parking.initializationError != null) {
      return _InitializationError(
        message: parking.initializationError!,
        onRetry: parking.retryInitialization,
      );
    }

    final visibleVehicles = _visibleVehicles(parking);
    return Scaffold(
      appBar: AppBar(title: Text(settings.parkingName)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/check-in'),
        icon: const Icon(Icons.login_rounded),
        label: const Text('Registrar entrada'),
      ),
      body: RefreshIndicator(
        onRefresh: parking.retryInitialization,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _StatusCard(
                  activeCount: parking.activeTickets.length,
                  completedToday: _completedToday(parking.completedTickets),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              sliver: SliverToBoxAdapter(
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Buscar placa, modelo ou proprietário',
                  leading: const Icon(Icons.search_rounded),
                  trailing: [
                    if (_query.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() => _query = value.trim().toUpperCase());
                  },
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  _query.isEmpty ? 'Veículos no pátio' : 'Resultado da busca',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (visibleVehicles.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(searching: _query.isNotEmpty),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                sliver: SliverList.builder(
                  itemCount: visibleVehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = visibleVehicles[index];
                    final ticket = parking.getActiveTicketForVehicle(
                      vehicle.id,
                    );
                    return VehicleCard(
                      vehicle: vehicle,
                      activeTicket: ticket,
                      onTap: () {
                        if (ticket != null) {
                          context.push('/ticket/${ticket.id}');
                        } else {
                          _showVehicleActions(context, vehicle);
                        }
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Vehicle> _visibleVehicles(ParkingProvider parking) {
    if (_query.isEmpty) {
      final activeIds = parking.activeTickets
          .map((ticket) => ticket.vehicleId)
          .toSet();
      return parking.vehicles
          .where((vehicle) => activeIds.contains(vehicle.id))
          .toList(growable: false);
    }
    final canonicalQuery = PlateValidator.canonical(_query);
    return parking.vehicles
        .where((vehicle) {
          return vehicle.plate.contains(canonicalQuery) ||
              vehicle.model.toUpperCase().contains(_query) ||
              vehicle.ownerName.toUpperCase().contains(_query);
        })
        .toList(growable: false);
  }

  int _completedToday(List<Ticket> tickets) {
    final now = DateTime.now();
    return tickets.where((ticket) {
      final exit = ticket.exitTime?.toLocal();
      return exit != null &&
          exit.year == now.year &&
          exit.month == now.month &&
          exit.day == now.day;
    }).length;
  }

  Future<void> _showVehicleActions(
    BuildContext context,
    Vehicle vehicle,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.login_rounded),
                title: Text(
                  'Registrar entrada de ${PlateValidator.format(vehicle.plate)}',
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _checkInExisting(context, vehicle);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar cadastro'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/check-in', extra: vehicle);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkInExisting(BuildContext context, Vehicle vehicle) async {
    try {
      await context.read<ParkingProvider>().checkIn(
        vehicle.id,
        pricing: context.read<SettingsProvider>().pricing,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Entrada de ${PlateValidator.format(vehicle.plate)} registrada',
            ),
          ),
        );
      }
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
    }
  }

  String _message(Object error) => error.toString().replaceFirst(
    RegExp(r'^(Bad state|Invalid argument): '),
    '',
  );
}

class _StatusCard extends StatelessWidget {
  final int activeCount;
  final int completedToday;

  const _StatusCard({required this.activeCount, required this.completedToday});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _Metric(
                value: activeCount.toString(),
                label: 'no pátio',
                icon: Icons.local_parking_rounded,
              ),
            ),
            SizedBox(
              height: 52,
              child: VerticalDivider(color: colors.onPrimaryContainer),
            ),
            Expanded(
              child: _Metric(
                value: completedToday.toString(),
                label: 'saídas hoje',
                icon: Icons.logout_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _Metric({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, textAlign: TextAlign.center),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool searching;

  const _EmptyState({required this.searching});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching
                  ? Icons.search_off_rounded
                  : Icons.directions_car_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              searching ? 'Nenhum veículo encontrado' : 'O pátio está vazio',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (!searching) ...[
              const SizedBox(height: 8),
              const Text('Use “Registrar entrada” para começar.'),
            ],
          ],
        ),
      ),
    );
  }
}

class _InitializationError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _InitializationError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storage_rounded, size: 64),
              const SizedBox(height: 16),
              Text(
                'Não foi possível abrir os dados locais',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
