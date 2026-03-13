import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parking_br/models/ticket.dart';
import 'package:parking_br/models/vehicle.dart';
import 'package:parking_br/providers/parking_provider.dart';
import 'package:parking_br/theme.dart';
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            theme.brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: theme.colorScheme.surface,
        systemNavigationBarIconBrightness:
            theme.brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          _showExitDialog(context);
        },
        child: Scaffold(
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
                tooltip: 'Carteira',
                onPressed: () => context.push('/wallet'),
              ).animate().fadeIn(delay: 200.milliseconds).scale(),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Configurações',
                onPressed: () => context.push('/settings'),
              ).animate().fadeIn(delay: 300.milliseconds).scale(),
            ],
            centerTitle: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  theme.brightness == Brightness.dark ? Brightness.light : Brightness.dark,
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/check-in'),
            icon: const Icon(Icons.add),
            label: const Text('Novo Veículo'),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ).animate().scale(delay: 400.milliseconds, curve: Curves.easeOutBack),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsHeader(context, activeTickets),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Veículos Estacionados',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 500.milliseconds).slideX(begin: -0.2),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Ver Tudo'),
                    ).animate().fadeIn(delay: 600.milliseconds),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
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
        ),
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, List<Ticket> activeTickets) {
    final theme = Theme.of(context);
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status Atual',
                style: GoogleFonts.lexend(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
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
                        'Veículos no Pátio',
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.md),
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
            'Nenhum veículo registrado.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  void _showActionSheet(BuildContext context, Vehicle vehicle) {
    final provider = Provider.of<ParkingProvider>(context, listen: false);
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
              'Ações para ${vehicle.plate}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(
                Icons.login_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Check-In (Entrada)'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onTap: () {
                context.pop();
                provider.checkIn(vehicle.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    content: Text('Veículo ${vehicle.plate} entrou no pátio!'),
                  ),
                );
              },
            ).animate().fadeIn(delay: 100.milliseconds).slideX(),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Editar Informações'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onTap: () {
                context.pop();
                context.push('/check-in', extra: vehicle);
              },
            ).animate().fadeIn(delay: 200.milliseconds).slideX(),
             ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('Excluir Veículo', style: TextStyle(color: Colors.red)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onTap: () {
                context.pop();
                _showDeleteDialog(context, vehicle);
              },
            ).animate().fadeIn(delay: 300.milliseconds).slideX(),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Vehicle vehicle) {
    final provider = Provider.of<ParkingProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Veículo?'),
        content: Text('Tem certeza que deseja remover o veículo ${vehicle.plate}? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteVehicle(vehicle.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veículo removido com sucesso.')),
              );
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do App'),
        content: const Text('O que você deseja fazer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saindo... (Sessão mantida)')),
              );
            },
            child: const Text('Apenas Sair'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/login');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saindo e deslogando...')),
              );
            },
            child: const Text('Sair e Deslogar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
