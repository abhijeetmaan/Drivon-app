import 'package:flutter/widgets.dart';

import '../../core/utils/app_spacing.dart';

class SectionContainer extends StatelessWidget {
  final Widget child;
  final double top;

  const SectionContainer({
    super.key,
    required this.child,
    this.top = AppSpacing.s24,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: child,
    );
  }
}

