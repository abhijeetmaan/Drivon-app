import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../../core/utils/app_spacing.dart';
import 'skeleton.dart';

/// Composed skeleton layouts that mirror real UI shapes.
class SkeletonLoader {
  SkeletonLoader._();

  static Widget screenList({
    int items = 4,
    EdgeInsets padding = const EdgeInsets.only(top: AppSpacing.s16, bottom: 140),
  }) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(height: 56, borderRadius: BorderRadius.all(Radius.circular(20))),
          const SizedBox(height: AppLayout.sectionGap),
          const Skeleton(height: 172, borderRadius: BorderRadius.all(Radius.circular(20))),
          const SizedBox(height: AppLayout.elementGap),
          const Skeleton(height: 120, borderRadius: BorderRadius.all(Radius.circular(20))),
          const SizedBox(height: AppLayout.sectionGap),
          Row(
            children: [
              Expanded(child: _statShimmer()),
              const SizedBox(width: AppLayout.elementGap),
              Expanded(child: _statShimmer()),
              const SizedBox(width: AppLayout.elementGap),
              Expanded(child: _statShimmer()),
            ],
          ),
          const SizedBox(height: AppLayout.sectionGap),
          const Skeleton(height: 220, borderRadius: BorderRadius.all(Radius.circular(20))),
          SizedBox(height: AppLayout.sectionGap),
          for (var i = 0; i < items; i++) ...[
            listTile(),
            const SizedBox(height: AppLayout.elementGap),
          ],
        ],
      ),
    );
  }

  static Widget _statShimmer() {
    return const Skeleton(
      height: 108,
      borderRadius: BorderRadius.all(Radius.circular(20)),
    );
  }

  static Widget listTile() {
    return const Skeleton(
      height: 72,
      borderRadius: BorderRadius.all(Radius.circular(20)),
    );
  }

  static Widget chartBlock({double height = 180}) {
    return Skeleton(
      height: height,
      borderRadius: const BorderRadius.all(Radius.circular(20)),
    );
  }
}
