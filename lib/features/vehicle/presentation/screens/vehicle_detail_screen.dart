import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/dialogs/delete_confirmation.dart' show showPremiumDeleteDialog;
import '../../../../shared/widgets/custom_card.dart';
import '../../../../shared/widgets/gradient_card.dart';
import '../../domain/entities/vehicle.dart';
import '../providers/vehicle_providers.dart';

class VehicleDetailScreen extends ConsumerWidget {
  final Vehicle vehicle;
  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Vehicle'),
        actions: [
          IconButton(
            tooltip: 'Delete vehicle',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showPremiumDeleteDialog(
                context,
                title: 'Delete Vehicle?',
                onConfirm: () async {
                  await ref.read(vehicleActionsProvider).deleteVehicle(vehicle.id);
                },
                successMessage: 'Vehicle deleted',
              );
              if (ok && context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Hero(
            tag: 'vehicle_${vehicle.id}',
            child: Material(
              color: Colors.transparent,
              child: GradientCard(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.90),
                  Colors.deepPurpleAccent.withOpacity(0.60),
                  Colors.blueAccent.withOpacity(0.50),
                ],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicle.model} • ${vehicle.fuelType}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.85)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const CustomCard(
            child: Text('Mileage / fuel indicators are UI-only in this demo build.'),
          ),
        ],
      ),
    );
  }
}
