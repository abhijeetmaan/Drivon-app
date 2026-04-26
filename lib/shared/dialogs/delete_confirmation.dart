import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/theme.dart';
import '../motion/spring_interactive.dart';

/// Premium delete confirmation: full-screen dim + blur, animated card, in-dialog loading.
///
/// If [onConfirm] is non-null, it runs after Delete is tapped (loading state), then the modal
/// closes. A success [SnackBar] is shown after close unless [showSuccessSnackBar] is false.
///
/// If [onConfirm] is null (e.g. swipe confirm only), Delete closes the modal with `true`.
Future<bool> showPremiumDeleteDialog(
  BuildContext context, {
  required String title,
  String subtitle = 'This action cannot be undone',
  Future<void> Function()? onConfirm,
  String successMessage = 'Item deleted',
  bool showSuccessSnackBar = true,
}) async {
  final rootContext = context;

  final ok = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (ctx, animation, secondaryAnimation) {
          return _PremiumDeleteModal(
            title: title,
            subtitle: subtitle,
            onConfirm: onConfirm,
            entranceAnimation: animation,
          );
        },
        transitionBuilder: (ctx, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ) ??
      false;

  if (ok && showSuccessSnackBar && onConfirm != null && rootContext.mounted) {
    ScaffoldMessenger.of(rootContext).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  return ok;
}

/// Legacy name — prefer [showPremiumDeleteDialog].
Future<bool> showDeleteConfirmation(
  BuildContext context, {
  required String title,
  String subtitle = 'This action cannot be undone',
  Future<void> Function()? onConfirm,
  String successMessage = 'Item deleted',
  bool showSuccessSnackBar = true,
}) {
  return showPremiumDeleteDialog(
    context,
    title: title,
    subtitle: subtitle,
    onConfirm: onConfirm,
    successMessage: successMessage,
    showSuccessSnackBar: showSuccessSnackBar,
  );
}

void showItemDeletedSnackbar(BuildContext context, [String message = 'Item deleted']) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

/// Swipe **right** (start → end) — red gradient + delete icon on the **left**.
Widget deleteSwipeBackground() {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppLayout.radiusCard),
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFFB91C1C),
          const Color(0xFFDC2626).withOpacity(0.92),
          const Color(0xFF991B1B).withOpacity(0.85),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFDC2626).withOpacity(0.25),
          blurRadius: 12,
          offset: const Offset(4, 0),
        ),
      ],
    ),
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.only(left: 20),
    child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
  );
}

class _PremiumDeleteModal extends StatefulWidget {
  const _PremiumDeleteModal({
    required this.title,
    required this.subtitle,
    required this.onConfirm,
    required this.entranceAnimation,
  });

  final String title;
  final String subtitle;
  final Future<void> Function()? onConfirm;
  final Animation<double> entranceAnimation;

  @override
  State<_PremiumDeleteModal> createState() => _PremiumDeleteModalState();
}

class _PremiumDeleteModalState extends State<_PremiumDeleteModal> with SingleTickerProviderStateMixin {
  bool _deleting = false;
  late AnimationController _iconBounce;

  @override
  void initState() {
    super.initState();
    _iconBounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    widget.entranceAnimation.addStatusListener(_onEntranceStatus);
    if (widget.entranceAnimation.status == AnimationStatus.completed) {
      _iconBounce.forward(from: 0);
    }
  }

  void _onEntranceStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _iconBounce.forward(from: 0);
    }
  }

  @override
  void dispose() {
    widget.entranceAnimation.removeStatusListener(_onEntranceStatus);
    _iconBounce.dispose();
    super.dispose();
  }

  Future<void> _onDelete() async {
    if (_deleting) return;
    HapticFeedback.mediumImpact();
    setState(() => _deleting = true);

    if (widget.onConfirm == null) {
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    try {
      await widget.onConfirm!();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final bounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.98), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _iconBounce, curve: Curves.easeOutCubic));

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                color: Colors.black.withOpacity(0.52),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF2A2438).withOpacity(0.94),
                          const Color(0xFF151922).withOpacity(0.97),
                          const Color(0xFF0C1018).withOpacity(0.98),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.14)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.55),
                          blurRadius: 48,
                          offset: const Offset(0, 28),
                          spreadRadius: -4,
                        ),
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.22),
                          blurRadius: 40,
                          spreadRadius: -12,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: AppColors.purple.withOpacity(0.12),
                          blurRadius: 36,
                          spreadRadius: -8,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: bounce,
                          builder: (context, child) {
                            return Transform.scale(scale: bounce.value, child: child);
                          },
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFF87171),
                                  Color(0xFFEF4444),
                                  Color(0xFFB91C1C),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withOpacity(0.55),
                                  blurRadius: 24,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: const Color(0xFFF97316).withOpacity(0.25),
                                  blurRadius: 20,
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 34),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                                height: 1.2,
                                letterSpacing: -0.3,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: SpringPressSurface(
                                enabled: !_deleting,
                                pressedScale: 0.98,
                                child: OutlinedButton.icon(
                                  onPressed: _deleting ? null : () => Navigator.of(context).pop(false),
                                  icon: Icon(Icons.close_rounded, size: 20, color: scheme.onSurface.withOpacity(0.85)),
                                  label: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: scheme.onSurface.withOpacity(0.88),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(color: Colors.white.withOpacity(0.22)),
                                    shape: const StadiumBorder(),
                                    backgroundColor: Colors.white.withOpacity(0.04),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SpringPressSurface(
                                enabled: !_deleting,
                                pressedScale: 0.98,
                                child: _PremiumDeleteButton(
                                  deleting: _deleting,
                                  onTap: _onDelete,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumDeleteButton extends StatelessWidget {
  const _PremiumDeleteButton({
    required this.deleting,
    required this.onTap,
  });

  final bool deleting;
  final VoidCallback onTap;

  static const _colors = [
    Color(0xFFDC2626),
    Color(0xFFEA580C),
    Color(0xFFF97316),
  ];

  @override
  Widget build(BuildContext context) {
    final gradientColors = deleting
        ? _colors.map((c) => c.withOpacity(0.55)).toList()
        : _colors;

    return Material(
      color: Colors.transparent,
      elevation: deleting ? 0 : 4,
      shadowColor: const Color(0xFFDC2626).withOpacity(0.45),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: deleting ? null : onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
              stops: const [0.0, 0.55, 1.0],
            ),
            boxShadow: deleting
                ? const []
                : [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withOpacity(0.42),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (deleting) ...[
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Deleting…',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ] else ...[
                const Icon(Icons.delete_forever_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Delete',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

