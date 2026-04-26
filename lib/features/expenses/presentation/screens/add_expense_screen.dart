import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/vehicle_scope.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../../../vehicle/presentation/providers/vehicle_providers.dart';
import '../providers/expense_providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String initialType;
  final String? preferredVehicleId;

  const AddExpenseScreen({super.key, this.initialType = 'Fuel', this.preferredVehicleId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late String _type;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _vehicleId;

  static ButtonStyle get _saveButtonStyle => FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      );

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _syncVehiclePick(List<Vehicle> vehicles) {
    if (vehicles.isEmpty) return;
    final pref = widget.preferredVehicleId;
    if (_vehicleId != null && vehicles.any((v) => v.id == _vehicleId)) return;
    if (pref != null && pref != kAllVehiclesId && vehicles.any((v) => v.id == pref)) {
      _vehicleId = pref;
      return;
    }
    _vehicleId = vehicles.first.id;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 3),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final vehicles = ref.read(vehiclesProvider).valueOrNull ?? [];
    if (vehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a vehicle before recording expenses.')),
      );
      return;
    }
    _syncVehiclePick(vehicles);
    final vid = _vehicleId;
    if (vid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a vehicle')));
      return;
    }

    final parsed = double.tryParse(_amount.text.trim());
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(expenseActionsProvider).addExpense(
            amount: parsed,
            type: _type,
            date: _date,
            note: _note.text,
            vehicleId: vid,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save expense: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomPad = mq.viewInsets.bottom + mq.padding.bottom + 24;
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.deferToChild,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: const Text('Add Expense')),
        body: SafeArea(
          child: vehiclesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load vehicles: $e')),
            data: (vehicles) {
              _syncVehiclePick(vehicles);
              return SingleChildScrollView(
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
                        if (vehicles.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Add a vehicle from Home or Profile to assign this expense.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            value: _vehicleId,
                            decoration: const InputDecoration(labelText: 'Vehicle'),
                            items: [
                              for (final v in vehicles)
                                DropdownMenuItem(value: v.id, child: Text('${v.name} · ${v.model}')),
                            ],
                            onChanged: (v) => setState(() => _vehicleId = v),
                          ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _amount,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          label: 'Amount',
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Amount is required' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _type,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: const [
                            DropdownMenuItem(value: 'Fuel', child: Text('Fuel')),
                            DropdownMenuItem(value: 'Service', child: Text('Service')),
                            DropdownMenuItem(value: 'Insurance', child: Text('Insurance')),
                          ],
                          onChanged: (v) => setState(() => _type = v ?? _type),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Date'),
                          subtitle: Text(DateFormat('MMM d, yyyy').format(_date)),
                          trailing: TextButton(onPressed: _pickDate, child: const Text('Pick')),
                        ),
                        CustomTextField(
                          controller: _note,
                          maxLines: 2,
                          label: 'Note',
                          hint: 'Optional',
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: 'Save expense',
                          isLoading: _saving,
                          style: _saveButtonStyle,
                          onPressed: vehicles.isEmpty ? null : _save,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
