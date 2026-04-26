import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import 'custom_card.dart';

/// Equal-height stat tile: icon top-left, label, prominent value (single line).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = accent ?? AppColors.accentCyan;
    return CustomCard(
      onTap: onTap,
      prominent: true,
      padding: const EdgeInsets.all(16),
      gradient: AppGradients.statTint(c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: c),
          const SizedBox(height: AppLayout.elementGap),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
