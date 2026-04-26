import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/theme.dart';
import 'glass_button.dart';

class ExpandableFabAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? accent;

  const ExpandableFabAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.accent,
  });
}

/// Premium expandable FAB: pulsing glow, + ↔ ×, blur veil, staggered glass actions.
class ExpandableFabWidget extends StatefulWidget {
  const ExpandableFabWidget({
    super.key,
    required this.actions,
    this.baseDuration = const Duration(milliseconds: 280),
    this.stagger = const Duration(milliseconds: 48),
    this.actionStackRight = 16,
    this.actionStackBottom = 100,
    this.fabSize = 58,
    this.actionFabGap = 14,
  });

  final List<ExpandableFabAction> actions;
  final Duration baseDuration;
  final Duration stagger;
  final double actionStackBottom;
  final double actionStackRight;
  final double fabSize;
  final double actionFabGap;

  @override
  State<ExpandableFabWidget> createState() => _ExpandableFabWidgetState();
}

class _ExpandableFabWidgetState extends State<ExpandableFabWidget> {
  OverlayEntry? _entry;
  bool _expanded = false;

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  void _close() {
    if (!_expanded) return;
    _removeOverlay();
    if (mounted) setState(() => _expanded = false);
  }

  void _show() {
    if (_entry != null) return;
    setState(() => _expanded = true);
    _entry = OverlayEntry(
      builder: (overlayContext) => _PremiumFabOverlay(
        actions: widget.actions,
        baseDuration: widget.baseDuration,
        stagger: widget.stagger,
        onDismiss: _close,
        onAction: (fn) {
          _close();
          fn();
        },
        actionStackBottom: widget.actionStackBottom,
        actionStackRight: widget.actionStackRight,
        fabSize: widget.fabSize,
        actionFabGap: widget.actionFabGap,
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  void _toggle() {
    if (_expanded) {
      HapticFeedback.lightImpact();
      _close();
    } else {
      _show();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: _expanded,
      child: AnimatedOpacity(
        opacity: _expanded ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: _GradientFabButton(
          size: widget.fabSize,
          expanded: false,
          enablePulse: true,
          onPressed: _toggle,
        ),
      ),
    );
  }
}

class _GradientFabButton extends StatefulWidget {
  const _GradientFabButton({
    required this.size,
    required this.expanded,
    required this.onPressed,
    this.enablePulse = true,
  });

  final double size;
  final bool expanded;
  final VoidCallback onPressed;
  final bool enablePulse;

  @override
  State<_GradientFabButton> createState() => _GradientFabButtonState();
}

class _GradientFabButtonState extends State<_GradientFabButton> with SingleTickerProviderStateMixin {
  AnimationController? _pulse;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    if (widget.enablePulse && !widget.expanded) {
      _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  void _tap() {
    HapticFeedback.lightImpact();
    widget.onPressed();
  }

  Widget _ink(double pulseT) {
    final extra = widget.enablePulse && !widget.expanded
        ? AppShadows.fabGlowPulseLayer(pulseT)
        : AppShadows.fabGlowPulseLayer(widget.expanded ? 0.25 : 0.32);
    final shadows = [...AppShadows.fabGlow, ...extra];

    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.95 : 1.0,
        duration: AppMotion.pressScale,
        curve: AppMotion.pressCurve,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _tap,
            splashColor: Colors.white30,
            highlightColor: Colors.white12,
            child: Ink(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primary,
                boxShadow: shadows,
                border: Border.all(color: Colors.white.withOpacity(0.14)),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  widget.expanded ? Icons.close_rounded : Icons.add_rounded,
                  key: ValueKey(widget.expanded),
                  color: Colors.white,
                  size: widget.size * 0.42,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pulse != null && !widget.expanded) {
      return AnimatedBuilder(
        animation: _pulse!,
        builder: (_, __) => _ink(_pulse!.value),
      );
    }
    return _ink(0.4);
  }
}

class _PremiumFabOverlay extends StatefulWidget {
  const _PremiumFabOverlay({
    required this.actions,
    required this.baseDuration,
    required this.stagger,
    required this.onDismiss,
    required this.onAction,
    required this.actionStackBottom,
    required this.actionStackRight,
    required this.fabSize,
    required this.actionFabGap,
  });

  final List<ExpandableFabAction> actions;
  final Duration baseDuration;
  final Duration stagger;
  final VoidCallback onDismiss;
  final void Function(VoidCallback fn) onAction;
  final double actionStackBottom;
  final double actionStackRight;
  final double fabSize;
  final double actionFabGap;

  @override
  State<_PremiumFabOverlay> createState() => _PremiumFabOverlayState();
}

class _PremiumFabOverlayState extends State<_PremiumFabOverlay> {
  late final List<bool> _visible;
  bool _veilVisible = false;

  static const double _kActionTileHeight = 52;

  @override
  void initState() {
    super.initState();
    _visible = List<bool>.filled(widget.actions.length, false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _veilVisible = true);
      for (var i = 0; i < widget.actions.length; i++) {
        final idx = i;
        Future<void>.delayed(
          Duration(milliseconds: 24 + idx * widget.stagger.inMilliseconds),
          () {
            if (!mounted) return;
            setState(() => _visible[idx] = true);
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final safeBottom = mq.padding.bottom;
    final fabBottom = widget.actionStackBottom + safeBottom;
    final actionColumnBottom = fabBottom + widget.fabSize + widget.actionFabGap;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedOpacity(
                opacity: _veilVisible ? 1 : 0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onDismiss();
                  },
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(color: Colors.black.withOpacity(0.52)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.actions.isNotEmpty)
            Positioned(
              right: widget.actionStackRight,
              bottom: actionColumnBottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < widget.actions.length; i++) ...[
                    SizedBox(
                      height: _kActionTileHeight,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _ActionTile(
                          visible: _visible[i],
                          duration: widget.baseDuration,
                          action: widget.actions[i],
                          onTap: () => widget.onAction(widget.actions[i].onPressed),
                        ),
                      ),
                    ),
                    if (i < widget.actions.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          Positioned(
            right: widget.actionStackRight,
            bottom: fabBottom,
            child: _GradientFabButton(
              size: widget.fabSize,
              expanded: true,
              enablePulse: true,
              onPressed: widget.onDismiss,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.visible,
    required this.duration,
    required this.action,
    required this.onTap,
  });

  final bool visible;
  final Duration duration;
  final ExpandableFabAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = action.accent ?? AppColors.accentCyan;
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        duration: duration,
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0.15, 0),
        child: AnimatedScale(
          duration: duration,
          curve: Curves.easeOutCubic,
          scale: visible ? 1 : 0.92,
          child: GlassButton(
            opacity: 0.10,
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            onPressed: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(action.icon, size: 22, color: accent),
                const SizedBox(width: 12),
                Text(
                  action.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.15,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
