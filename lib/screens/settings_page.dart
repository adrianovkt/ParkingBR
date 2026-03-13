import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parking_br/models/user.dart';
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
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Configurações',
                style: GoogleFonts.lexend(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontSize: 20,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 16),
              expandedTitleScale: 1.3,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ProfileCard(
                  userVehicleId: userVehicle.id,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad),
                const SizedBox(height: AppSpacing.xl),
                _buildSection(
                  context,
                  'Preferências',
                  [
                    _SettingsTile(
                      icon: Icons.color_lens_rounded,
                      title: 'Aparência do aplicativo',
                      subtitle: _themeLabel(settings.themeMode),
                      color: Colors.blue,
                      onTap: () => _showThemeSheet(context),
                    ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.05),
                    _SettingsTile(
                      icon: Icons.notifications_active_rounded,
                      title: 'Notificações',
                      subtitle: 'Ativadas',
                      color: Colors.orange,
                      onTap: () {},
                    ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSection(
                  context,
                  'Comunidade',
                  [
                    _SettingsTile(
                      icon: Icons.star_rate_rounded,
                      title: 'Avaliar aplicativo',
                      subtitle: 'Deixe sua opinião na loja',
                      color: Colors.amber,
                      onTap: () => _showRateDialog(context),
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
                    _SettingsTile(
                      icon: Icons.forum_rounded,
                      title: 'Enviar feedback',
                      subtitle: 'Sugestões de melhoria',
                      color: Colors.teal,
                      onTap: () => _showFeedbackSheet(context, withLogs: false),
                    ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSection(
                  context,
                  'Suporte Técnico',
                  [
                    _SettingsTile(
                      icon: Icons.bug_report_rounded,
                      title: 'Reportar erro',
                      subtitle: 'Envio automático de logs',
                      color: Colors.redAccent,
                      onTap: () => _showFeedbackSheet(context, withLogs: true),
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05),
                  ],
                ),
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    'Versão 1.0.0 (Build 1)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      letterSpacing: 1,
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.lexend(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  String _themeLabel(ThemeMode m) => switch (m) {
    ThemeMode.light => 'Modo Claro',
    ThemeMode.dark => 'Modo Escuro',
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (c) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 32,
          bottom: MediaQuery.of(c).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'O que você achou?',
              style: GoogleFonts.lexend(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sua avaliação nos ajuda a crescer.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            StatefulBuilder(
              builder: (context, setState) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => IconButton(
                    onPressed: () => setState(() => stars = i + 1),
                    iconSize: 40,
                    icon: Icon(
                      i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Conte-nos sua experiência (opcional)',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Obrigado pelo seu feedback!')),
                  );
                },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                child: const Text('Enviar Avaliação'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aparência',
              style: GoogleFonts.lexend(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildThemeOption(context, 'Seguir o sistema', Icons.brightness_auto_rounded, ThemeMode.system),
            _buildThemeOption(context, 'Modo Claro', Icons.light_mode_rounded, ThemeMode.light),
            _buildThemeOption(context, 'Modo Escuro', Icons.dark_mode_rounded, ThemeMode.dark),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String title, IconData icon, ThemeMode mode) {
    final settings = context.watch<SettingsProvider>();
    final isSelected = settings.themeMode == mode;
    final theme = Theme.of(context);

    return ListTile(
      onTap: () {
        Navigator.pop(context);
        settings.setThemeMode(mode);
      },
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (c) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 32,
          bottom: MediaQuery.of(c).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (withLogs ? Colors.red : theme.colorScheme.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    withLogs ? Icons.bug_report_rounded : Icons.forum_rounded,
                    color: withLogs ? Colors.red : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  withLogs ? 'Reportar Erro' : 'Feedback',
                  style: GoogleFonts.lexend(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: withLogs ? 'O que aconteceu de errado?' : 'Sua sugestão de melhoria...',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
              ),
            ),
            if (withLogs) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: Text(
                    logs.isEmpty ? 'Nenhum log disponível.' : logs,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mensagem enviada com sucesso!')),
                  );
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text('Enviar Mensagem'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
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
    if (user == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final vehicle = parking.getVehicle(userVehicleId);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                      ? Text(
                          _initials(user.fullName),
                          style: GoogleFonts.lexend(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: GoogleFonts.lexend(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _maskCpf(user.cpf),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => _showEditProfile(context, user),
                icon: const Icon(Icons.edit_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (vehicle != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '${vehicle.model} • ${vehicle.plate}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _maskCpf(String cpf) {
    final clean = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length < 11) return cpf;
    return '***.${clean.substring(3, 6)}.***-**';
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  void _showEditProfile(BuildContext context, AppUser user) {
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (c) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 32,
          bottom: MediaQuery.of(c).viewInsets.bottom + 32,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Editar Perfil',
                style: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cpfCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  _CpfInputFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'CPF',
                  prefixIcon: Icon(Icons.badge_rounded),
                  hintText: '000.000.000-00',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contactCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contato',
                  prefixIcon: Icon(Icons.contact_phone_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: avatarCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL da Foto',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () async {
                    await settings.updateUser(
                      user.copyWith(
                        fullName: nameCtrl.text.trim(),
                        cpf: cpfCtrl.text.trim(),
                        contact: contactCtrl.text.trim(),
                        avatarUrl: avatarCtrl.text.trim().isEmpty ? null : avatarCtrl.text.trim(),
                      ),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: const Text('Salvar Alterações'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null ? Text(subtitle!, style: theme.textTheme.bodySmall) : null,
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
    );
  }
}

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 11) return oldValue;
    
    var formatted = '';
    for (var i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) formatted += '.';
      if (i == 9) formatted += '-';
      formatted += text[i];
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
