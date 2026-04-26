import 'package:flutter/material.dart';

/// Page physics tuned for responsive flings: higher stiffness settles faster on
/// strong swipes while [damping] keeps motion smooth (no harsh overshoot).
class PremiumCarouselPagePhysics extends PageScrollPhysics {
  const PremiumCarouselPagePhysics({super.parent});

  @override
  PremiumCarouselPagePhysics applyTo(ScrollPhysics? ancestor) {
    return PremiumCarouselPagePhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.42,
        stiffness: 520,
        damping: 44,
      );

  /// Slightly lower bar so modest flicks still advance a page on mid-size screens.
  @override
  double get minFlingVelocity => 45;
}
