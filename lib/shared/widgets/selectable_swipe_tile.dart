import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../selection/list_selection_controller.dart';
import 'staggered_list_entry.dart';

/// Swipe right → delete (confirmed), long-press → selection, tap → open or toggle.
class SelectableSwipeTile extends StatefulWidget {
  const SelectableSwipeTile({
    super.key,
    required this.itemId,
    required this.selection,
    required this.child,
    this.swipeEnabled = true,
    required this.dismissKey,
    required this.swipeBackground,
    required this.confirmSwipeDelete,
    required this.onSwipeConfirmedDelete,
    this.onTapOpen,
  });

  final String itemId;
  final ListSelectionController selection;
  final Widget child;
  final bool swipeEnabled;
  final Key dismissKey;
  final Widget swipeBackground;
  final Future<bool> Function() confirmSwipeDelete;
  final Future<void> Function() onSwipeConfirmedDelete;
  final VoidCallback? onTapOpen;

  @override
  State<SelectableSwipeTile> createState() => _SelectableSwipeTileState();
}

class _SelectableSwipeTileState extends State<SelectableSwipeTile> {
  double _pressScale = 1.0;

  void _onLongPress() {
    HapticFeedback.mediumImpact();
    setState(() => _pressScale = 0.97);
    widget.selection.onLongPress(widget.itemId);
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (mounted) setState(() => _pressScale = 1.0);
    });
  }

  void _onTap() {
    if (widget.selection.isActive) {
      HapticFeedback.selectionClick();
      widget.selection.toggle(widget.itemId);
    } else {
      widget.onTapOpen?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selection.isSelected(widget.itemId);
    final mode = widget.selection.isActive;
    final canSwipe = widget.swipeEnabled && !mode;

    final decorated = AnimatedScale(
      scale: _pressScale,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.55),
                  width: 1.5,
                )
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: selected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                : Colors.transparent,
            child: InkWell(
              onTap: widget.onTapOpen != null || mode ? _onTap : null,
              onLongPress: _onLongPress,
              child: Padding(
                padding: EdgeInsets.zero,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (c, anim) => SizeTransition(
                        sizeFactor: anim,
                        axis: Axis.horizontal,
                        axisAlignment: -1,
                        child: FadeTransition(opacity: anim, child: c),
                      ),
                      child: mode
                          ? Padding(
                              key: const ValueKey('cb'),
                              padding: const EdgeInsets.only(left: 4, right: 4),
                              child: Checkbox(
                                value: selected,
                                onChanged: (_) {
                                  HapticFeedback.selectionClick();
                                  widget.selection.toggle(widget.itemId);
                                },
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                          : const SizedBox(key: ValueKey('nocb'), width: 0),
                    ),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!canSwipe) {
      return decorated;
    }

    return BouncyDismissible(
      dismissKey: widget.dismissKey,
      direction: DismissDirection.startToEnd,
      background: widget.swipeBackground,
      confirmDismiss: (_) async => await widget.confirmSwipeDelete(),
      onDismissed: (_) async => widget.onSwipeConfirmedDelete(),
      child: decorated,
    );
  }
}
