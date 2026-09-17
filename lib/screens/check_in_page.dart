import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/vehicle.dart';
import '../providers/parking_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/plate_validator.dart';

class CheckInPage extends StatefulWidget {
  final Vehicle? vehicleToEdit;

  const CheckInPage({super.key, this.vehicleToEdit});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  static const _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _plateController;
  late final TextEditingController _modelController;
  late final TextEditingController _colorController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _ownerCpfController;
  late final TextEditingController _ownerContactController;
  bool _isLoading = false;

  bool get _isEditing => widget.vehicleToEdit != null;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicleToEdit;
    _plateController = TextEditingController(
      text: vehicle == null ? '' : PlateValidator.format(vehicle.plate),
    );
    _modelController = TextEditingController(text: vehicle?.model ?? '');
    _colorController = TextEditingController(text: vehicle?.color ?? '');
    _ownerNameController = TextEditingController(
      text: vehicle?.ownerName ?? '',
    );
    _ownerCpfController = TextEditingController(text: vehicle?.ownerCpf ?? '');
    _ownerContactController = TextEditingController(
      text: vehicle?.ownerContact ?? '',
    );
  }

  @override
  void dispose() {
    _plateController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _ownerNameController.dispose();
    _ownerCpfController.dispose();
    _ownerContactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final vehicle = Vehicle(
      id: widget.vehicleToEdit?.id ?? _uuid.v4(),
      plate: PlateValidator.canonical(_plateController.text),
      model: _modelController.text.trim(),
      color: _colorController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      ownerCpf: _ownerCpfController.text.trim(),
      ownerContact: _ownerContactController.text.trim(),
    );

    try {
      final parking = context.read<ParkingProvider>();
      if (_isEditing) {
        await parking.updateVehicle(vehicle);
      } else {
        await parking.registerEntry(
          vehicle: vehicle,
          pricing: context.read<SettingsProvider>().pricing,
        );
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Veículo atualizado'
                : 'Entrada de ${PlateValidator.format(vehicle.plate)} registrada',
          ),
        ),
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

  Future<void> _archive() async {
    if (_isLoading || widget.vehicleToEdit == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Arquivar veículo?'),
        content: const Text(
          'O cadastro sairá da lista, mas todo o histórico será preservado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Arquivar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await context.read<ParkingProvider>().archiveVehicle(
        widget.vehicleToEdit!.id,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Veículo arquivado')),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar veículo' : 'Registrar entrada'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Identificação',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _plateController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9-]')),
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: const InputDecoration(
                labelText: 'Placa',
                hintText: 'ABC-1234 ou ABC1D23',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
              validator: (value) {
                if (PlateValidator.identify(value?.trim() ?? '') ==
                    PlateType.invalid) {
                  return 'Informe uma placa válida';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 520) {
                  return Column(
                    children: [
                      _modelField(),
                      const SizedBox(height: 16),
                      _colorField(),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: _modelField()),
                    const SizedBox(width: 12),
                    Expanded(child: _colorField()),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              'Proprietário (opcional)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ownerNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nome',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ownerCpfController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CPF',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ownerContactController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contato',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isEditing ? Icons.save_outlined : Icons.login_rounded,
                    ),
              label: Text(
                _isEditing ? 'Salvar alterações' : 'Registrar entrada',
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _isLoading ? null : _archive,
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Arquivar veículo'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _message(Object error) => error.toString().replaceFirst(
    RegExp(r'^(Bad state|Invalid argument): '),
    '',
  );

  Widget _modelField() {
    return TextFormField(
      controller: _modelController,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Modelo (opcional)',
        prefixIcon: Icon(Icons.directions_car_outlined),
      ),
    );
  }

  Widget _colorField() {
    return TextFormField(
      controller: _colorController,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Cor (opcional)',
        prefixIcon: Icon(Icons.palette_outlined),
      ),
    );
  }
}
