import 'package:flutter/material.dart';

import '../../core/theme/theme.dart';
import '../motion/app_haptics.dart';
import '../motion/spring_interactive.dart';

class CustomCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final bool prominent;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.gradient,
    this.prominent = false,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  bool _pressed = false;
  Offset _pointerNorm = Offset.zero;

  void _tap() {
    if (widget.onTap != null) {
      AppHaptics.tap();
      widget.onTap!();
    }
  }

  void _setTiltFromLocal(Offset local, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;
    setState(() {
      _pointerNorm = Offset(
        ((local.dx - cx) / cx).clamp(-1.0, 1.0),
        ((local.dy - cy) / cy).clamp(-1.0, 1.0),
      );
    });
  }

  List<BoxShadow> _shadows() {
    final lift = widget.prominent || (widget.onTap != null && _pressed);
    final base = lift ? AppShadows.cardRaised : AppShadows.cardSoft;
    final ox = _pointerNorm.dx * 10;
    final oy = _pointerNorm.dy * 8;
    final extraBlur = _pointerNorm.distance * 28;
    return [
      BoxShadow(
        color: base.first.color,
        blurRadius: base.first.blurRadius + extraBlur,
        spreadRadius: base.first.spreadRadius,
        offset: base.first.offset + Offset(ox, oy),
      ),
      if (base.length > 1)
        BoxShadow(
          color: base[1].color,
          blurRadius: base[1].blurRadius + extraBlur * 0.5,
          spreadRadius: base[1].spreadRadius,
          offset: base[1].offset + Offset(ox * 0.7, oy * 0.7),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = widget.color ?? (widget.gradient == null ? scheme.surfaceVariant : null);

    final outerR = BorderRadius.circular(AppLayout.radiusCard);
    final innerR = BorderRadius.circular(AppLayout.radiusCard - AppLayout.cardBorderWidth);

    final rotX = -_pointerNorm.dy * 0.026;
    final rotY = _pointerNorm.dx * 0.028;
    final tiltMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateX(rotX)
      ..rotateY(rotY);

    final content = Padding(
      padding: widget.padding,
      child: widget.child,
    );

    Widget core = widget.onTap == null
        ? content
        : LayoutBuilder(
            builder: (context, c) {
              final sz = Size(
                c.maxWidth.isFinite ? c.maxWidth : MediaQuery.sizeOf(context).width - 32,
                c.maxHeight.isFinite ? c.maxHeight : 120,
              );
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: innerR,
                  onTap: _tap,
                  splashColor: AppColors.purple.withOpacity(0.14),
                  highlightColor: AppColors.purple.withOpacity(0.06),
                  child: SpringPressSurface(
                    child: Listener(
                      onPointerDown: (e) => _setTiltFromLocal(e.localPosition, sz),
                      onPointerMove: (e) => _setTiltFromLocal(e.localPosition, sz),
                      onPointerUp: (_) => setState(() => _pointerNorm = Offset.zero),
                      onPointerCancel: (_) => setState(() => _pointerNorm = Offset.zero),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: tiltMatrix,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            content,
                            Positioned.fill(
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: innerR,
                                    gradient: LinearGradient(
                                      begin: Alignment(-0.8 + _pointerNorm.dx * 0.2, -0.9 + _pointerNorm.dy * 0.15),
                                      end: Alignment(0.85 - _pointerNorm.dx * 0.15, 1.0),
                                      colors: [
                                        Colors.white.withOpacity(0.0),
                                        Colors.white.withOpacity(0.045),
                                        Colors.white.withOpacity(0.0),
                                      ],
                                      stops: const [0.35, 0.5, 0.65],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );

    final bordered = AnimatedContainer(
      duration: AppMotion.pressScale,
      curve: AppMotion.pressCurve,
      decoration: BoxDecoration(
        borderRadius: outerR,
        gradient: AppGradients.cardBorder,
        boxShadow: _shadows(),
      ),
      padding: const EdgeInsets.all(AppLayout.cardBorderWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: innerR,
          color: widget.gradient == null ? fill : null,
          gradient: widget.gradient,
        ),
        child: core,
      ),
    );

    if (widget.onTap == null) return bordered;

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: bordered,
    );
  }
}
