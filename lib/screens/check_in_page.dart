import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/vehicle.dart';
import '../providers/parking_provider.dart';
import '../widgets/gradient_button.dart';

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerCpfController = TextEditingController();
  final _ownerContactController = TextEditingController();
  static const _uuid = Uuid();

  bool _isLoading = false;

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

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final provider = Provider.of<ParkingProvider>(context, listen: false);
        final vehicle = Vehicle(
          id: _uuid.v4(),
          plate: _plateController.text.toUpperCase(),
          model: _modelController.text,
          color: _colorController.text,
          ownerName: _ownerNameController.text,
          ownerCpf: _ownerCpfController.text,
          ownerContact: _ownerContactController.text,
        );

        provider.addVehicle(vehicle);
        provider.checkIn(vehicle.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Text('Vehicle ${vehicle.plate} checked in!'),
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('New Check-In'), centerTitle: true),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vehicle Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ).animate().fadeIn().slideX(begin: -0.1),
              const SizedBox(height: 16),
              _buildAnimatedField(
                index: 0,
                child: _buildTextField(
                  controller: _plateController,
                  label: 'License Plate',
                  hint: 'ABC-1234',
                  icon: Icons.directions_car,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildAnimatedField(
                      index: 1,
                      child: _buildTextField(
                        controller: _modelController,
                        label: 'Model',
                        hint: 'Honda Civic',
                        icon: Icons.airport_shuttle,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAnimatedField(
                      index: 2,
                      child: _buildTextField(
                        controller: _colorController,
                        label: 'Color',
                        hint: 'Silver',
                        icon: Icons.color_lens,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Owner Information',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ).animate().fadeIn(delay: 300.milliseconds).slideX(begin: -0.1),
              const SizedBox(height: 16),
              _buildAnimatedField(
                index: 3,
                delay: 400.milliseconds,
                child: _buildTextField(
                  controller: _ownerNameController,
                  label: 'Full Name',
                  hint: 'John Doe',
                  icon: Icons.person,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildAnimatedField(
                index: 4,
                delay: 450.milliseconds,
                child: _buildTextField(
                  controller: _ownerCpfController,
                  label: 'CPF',
                  hint: '000.000.000-00',
                  keyboardType: TextInputType.number,
                  icon: Icons.badge,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 16),
              _buildAnimatedField(
                index: 5,
                delay: 500.milliseconds,
                child: _buildTextField(
                  controller: _ownerContactController,
                  label: 'Contact (Phone)',
                  hint: '(00) 00000-0000',
                  keyboardType: TextInputType.phone,
                  icon: Icons.phone,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 40),
              GradientButton(
                    text: 'Check In Vehicle',
                    onTap: _submit,
                    isLoading: _isLoading,
                  )
                  .animate()
                  .fadeIn(delay: 600.milliseconds)
                  .scale(curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedField({
    required Widget child,
    required int index,
    Duration delay = Duration.zero,
  }) {
    return child
        .animate()
        .fadeIn(delay: delay + (index * 50).milliseconds)
        .slideY(begin: 0.1, curve: Curves.easeOutQuad);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
      validator: validator,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}
