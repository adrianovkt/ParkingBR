import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/parking_provider.dart';
import '../providers/settings_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _graceController = TextEditingController();
  final _firstHourController = TextEditingController();
  final _extraHourController = TextEditingController();
  bool _formLoaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _graceController.dispose();
    _firstHourController.dispose();
    _extraHourController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<SettingsProvider>().updateOperationalSettings(
        parkingName: _nameController.text,
        graceSeconds: int.parse(_graceController.text) * 60,
        firstHourCents: _moneyToCents(_firstHourController.text),
        extraHourCents: _moneyToCents(_extraHourController.text),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Configurações salvas')));
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final parking = context.watch<ParkingProvider>();
    if (!settings.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_formLoaded) {
      _nameController.text = settings.parkingName;
      _graceController.text = (settings.graceSeconds ~/ 60).toString();
      _firstHourController.text = _centsToInput(settings.firstHourCents);
      _extraHourController.text = _centsToInput(settings.extraHourCents);
      _formLoaded = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Operação local',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do estacionamento',
                prefixIcon: Icon(Icons.local_parking_rounded),
              ),
              validator: _required,
            ),
            const SizedBox(height: 24),
            Text(
              'Tarifa para novas entradas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Alterações não recalculam permanências já iniciadas.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _graceController,
              decoration: const InputDecoration(
                labelText: 'Tolerância em minutos',
                prefixIcon: Icon(Icons.timer_outlined),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) => _integerRange(value, 0, 60),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstHourController,
              decoration: const InputDecoration(
                labelText: 'Primeira hora (R\$)',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _money,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _extraHourController,
              decoration: const InputDecoration(
                labelText: 'Hora adicional iniciada (R\$)',
                prefixIcon: Icon(Icons.more_time_rounded),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _money,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<ThemeMode>(
              initialValue: settings.themeMode,
              decoration: const InputDecoration(
                labelText: 'Aparência',
                prefixIcon: Icon(Icons.palette_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('Seguir o sistema'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Claro')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Escuro')),
              ],
              onChanged: (mode) async {
                if (mode == null) return;
                try {
                  await settings.setThemeMode(mode);
                } on Object catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(_message(error))));
                  }
                }
              },
            ),
            if (parking.migrationConflictCount > 0) ...[
              const SizedBox(height: 24),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: Text(
                    '${parking.migrationConflictCount} conflito(s) na migração',
                  ),
                  subtitle: const Text(
                    'Os registros originais continuam preservados no backup local.',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Salvar configurações'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;
  }

  String? _integerRange(String? value, int minimum, int maximum) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < minimum || number > maximum) {
      return 'Informe um valor entre $minimum e $maximum';
    }
    return null;
  }

  String? _money(String? value) {
    try {
      _moneyToCents(value ?? '');
      return null;
    } on FormatException {
      return 'Informe um valor válido';
    }
  }

  int _moneyToCents(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(normalized);
    if (match == null) {
      throw const FormatException();
    }
    final units = int.parse(match.group(1)!);
    final fraction = (match.group(2) ?? '').padRight(2, '0');
    return units * 100 + (fraction.isEmpty ? 0 : int.parse(fraction));
  }

  String _centsToInput(int cents) => (cents / 100).toStringAsFixed(2);

  String _message(Object error) => error.toString().replaceFirst(
    RegExp(r'^(Bad state|Invalid argument): '),
    '',
  );
}
