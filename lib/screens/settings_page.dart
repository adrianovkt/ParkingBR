import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:parking_br/models/vehicle.dart';
import 'package:parking_br/providers/parking_provider.dart';
import 'package:parking_br/providers/settings_provider.dart';
import 'package:parking_br/services/log_service.dart';
import 'package:parking_br/theme.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final parking = context.watch<ParkingProvider>();
    final user = settings.user;
    final userVehicle = parking.vehicles.firstWhere(
      (v) => v.ownerCpf == user.cpf,
      orElse: () => parking.vehicles.isNotEmpty
          ? parking.vehicles.first
          : Vehicle(
              id: 'none',
              plate: '—',
              model: '—',
              color: '—',
              ownerName: user.fullName,
              ownerCpf: user.cpf,
              ownerContact: user.contact,
            ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileCard(
            userVehicleId: userVehicle.id,
          ).animate().fadeIn().moveY(begin: 12, duration: 300.ms),
          const SizedBox(height: 16),
          const _SectionHeader(title: 'Geral').animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.star_rate_rounded,
            title: 'Avaliar aplicativo',
            onTap: () => _showRateDialog(context),
          ).animate().fadeIn(delay: 120.ms).slideX(begin: 0.05),
          _SettingsTile(
            icon: Icons.color_lens_rounded,
            title: 'Aparência do aplicativo',
            subtitle: _themeLabel(settings.themeMode),
            onTap: () => _showThemeSheet(context),
          ).animate().fadeIn(delay: 160.ms).slideX(begin: 0.05),
          const SizedBox(height: 16),
          const _SectionHeader(
            title: 'Feedback',
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.forum_rounded,
            title: 'Enviar feedback de melhoria',
            onTap: () => _showFeedbackSheet(context, withLogs: false),
          ).animate().fadeIn(delay: 240.ms).slideX(begin: 0.05),
          _SettingsTile(
            icon: Icons.bug_report_rounded,
            title: 'Reportar erro (com logs)',
            onTap: () => _showFeedbackSheet(context, withLogs: true),
          ).animate().fadeIn(delay: 280.ms).slideX(begin: 0.05),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode m) => switch (m) {
    ThemeMode.light => 'Claro',
    ThemeMode.dark => 'Escuro',
    _ => 'Seguir o sistema',
  };

  void _showRateDialog(BuildContext context) {
    final theme = Theme.of(context);
    int stars = 5;
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      builder: (c) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(c).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_rounded, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'Avaliar aplicativo',
                  style: theme.textTheme.titleLarge?.bold,
                ),
              ],
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setState) => Row(
                children: List.generate(
                  5,
                  (i) => IconButton(
                    onPressed: () => setState(() => stars = i + 1),
                    icon: Icon(
                      i < stars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Conte-nos mais (opcional)',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                debugPrint(
                  'User rated app: $stars stars, comment: ${controller.text}',
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Obrigado pelo seu feedback!')),
                );
              },
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSheet(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      builder: (c) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.brightness_auto_rounded),
            title: const Text('Seguir o sistema'),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.system,
              groupValue: settings.themeMode,
              onChanged: (v) {
                Navigator.pop(c);
                settings.setThemeMode(ThemeMode.system);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.light_mode_rounded),
            title: const Text('Claro'),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.light,
              groupValue: settings.themeMode,
              onChanged: (v) {
                Navigator.pop(c);
                settings.setThemeMode(ThemeMode.light);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_rounded),
            title: const Text('Escuro'),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: settings.themeMode,
              onChanged: (v) {
                Navigator.pop(c);
                settings.setThemeMode(ThemeMode.dark);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context, {required bool withLogs}) {
    final theme = Theme.of(context);
    final controller = TextEditingController();
    final logs = withLogs ? LogService.I.exportAsText() : '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      builder: (c) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(c).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  withLogs ? Icons.bug_report_rounded : Icons.forum_rounded,
                  color: withLogs
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  withLogs
                      ? 'Reportar erro (com logs)'
                      : 'Enviar feedback de melhoria',
                  style: theme.textTheme.titleLarge?.bold,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: withLogs ? 'Descreva o erro' : 'Sua sugestão',
              ),
            ),
            if (withLogs) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                constraints: const BoxConstraints(maxHeight: 160),
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: Text(
                    logs.isEmpty ? 'Nenhum log coletado ainda.' : logs,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: logs));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logs copiados')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copiar logs'),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () {
                      LogService.I.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logs limpos')),
                      );
                    },
                    icon: const Icon(Icons.delete_sweep_rounded),
                    label: const Text('Limpar'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (withLogs) {
                  debugPrint(
                    'ERROR REPORT | message: ${controller.text}\n${LogService.I.exportAsText()}',
                  );
                } else {
                  debugPrint(
                    'IMPROVEMENT FEEDBACK | message: ${controller.text}',
                  );
                }
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Obrigado! Feedback enviado.')),
                );
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.userVehicleId});
  final String userVehicleId;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final parking = context.watch<ParkingProvider>();
    final user = settings.user;
    final theme = Theme.of(context);
    final vehicle = parking.getVehicle(userVehicleId);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage:
                (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                ? Text(
                    _initials(user.fullName),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'CPF: ${user.cpf}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                if (vehicle != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car_filled_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${vehicle.model} • ${vehicle.plate}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showEditProfile(context, user),
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  void _showEditProfile(BuildContext context, user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final cpfCtrl = TextEditingController(text: user.cpf);
    final contactCtrl = TextEditingController(text: user.contact);
    final avatarCtrl = TextEditingController(text: user.avatarUrl ?? '');
    final settings = context.read<SettingsProvider>();
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      builder: (c) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(c).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.person_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Editar perfil', style: theme.textTheme.titleLarge?.bold),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome completo'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: cpfCtrl,
              decoration: const InputDecoration(labelText: 'CPF'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contactCtrl,
              decoration: const InputDecoration(
                labelText: 'Contato (telefone/email)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: avatarCtrl,
              decoration: const InputDecoration(
                labelText: 'URL da foto (opcional)',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                await settings.updateUser(
                  user.copyWith(
                    fullName: nameCtrl.text.trim(),
                    cpf: cpfCtrl.text.trim(),
                    contact: contactCtrl.text.trim(),
                    avatarUrl: avatarCtrl.text.trim().isEmpty
                        ? null
                        : avatarCtrl.text.trim(),
                  ),
                );
                if (context.mounted) Navigator.of(context).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil atualizado')),
                  );
                }
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.bold.withColor(
        theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: AppRadius.medium,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.semiBold),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.withColor(
                          theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
