import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/ticket.dart';
import '../models/vehicle.dart';
import '../theme.dart';

class VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final Ticket? activeTicket;
  final VoidCallback onTap;

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.activeTicket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = activeTicket != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: isActive 
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Material(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          child: InkWell(
            onTap: onTap,
            splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
            child: Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: isActive
                      ? theme.colorScheme.primary.withValues(alpha: 0.5)
                      : theme.colorScheme.outline.withValues(alpha: 0.1),
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildIcon(theme, isActive),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.plate.toUpperCase(),
                              style: GoogleFonts.lexend(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                letterSpacing: 1.2,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${vehicle.model} • ${vehicle.color}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isActive) _buildStatusBadge(theme),
                    ],
                  ),
                  if (isActive) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Divider(height: 1, thickness: 0.5),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoColumn(
                          theme,
                          'Entrada',
                          DateFormat('HH:mm').format(activeTicket!.entryTime),
                          Icons.access_time_filled_rounded,
                        ),
                        _buildInfoColumn(
                          theme,
                          'Custo Atual',
                          NumberFormat.currency(
                            locale: 'pt_BR',
                            symbol: 'R\$',
                          ).format(activeTicket!.currentCost),
                          Icons.payments_rounded,
                          highlight: true,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad);
  }

  Widget _buildIcon(ThemeData theme, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [theme.colorScheme.primary, theme.colorScheme.secondary]
              : [theme.colorScheme.surfaceContainerHighest, theme.colorScheme.surfaceContainerHighest],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: isActive ? [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: Icon(
        Icons.directions_car_filled_rounded,
        color: isActive ? Colors.white : theme.colorScheme.onSurfaceVariant,
        size: 24,
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.sm + 4),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'ATIVO',
            style: GoogleFonts.lexend(
              color: theme.colorScheme.primary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(ThemeData theme, String label, String value, IconData icon, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: highlight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!highlight) Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
            if (!highlight) const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.lexend(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
            if (highlight) const SizedBox(width: 4),
            if (highlight) Icon(icon, size: 14, color: theme.colorScheme.primary),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: highlight ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
