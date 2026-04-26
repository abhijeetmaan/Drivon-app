import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/primary_button.dart';
import '../providers/vehicle_providers.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _model = TextEditingController();
  String _fuel = 'Petrol';
  bool _saving = false;

  static ButtonStyle get _saveButtonStyle => FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      );

  @override
  void dispose() {
    _name.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _saving = true);
    try {
      await ref.read(vehicleActionsProvider).addVehicle(
            name: _name.text,
            model: _model.text,
            fuelType: _fuel,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save vehicle: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPad = mq.viewInsets.bottom + mq.padding.bottom + 24;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.deferToChild,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: const Text('Add Vehicle')),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: bottomPad,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Vehicle name (e.g. My Car)'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _model,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Model (e.g. Civic 2020)'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Model is required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _fuel,
                      decoration: const InputDecoration(labelText: 'Fuel type'),
                      items: const [
                        DropdownMenuItem(value: 'Petrol', child: Text('Petrol')),
                        DropdownMenuItem(value: 'Diesel', child: Text('Diesel')),
                        DropdownMenuItem(value: 'Electric', child: Text('Electric')),
                        DropdownMenuItem(value: 'Hybrid', child: Text('Hybrid')),
                      ],
                      onChanged: (v) => setState(() => _fuel = v ?? _fuel),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Save vehicle',
                      isLoading: _saving,
                      style: _saveButtonStyle,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
