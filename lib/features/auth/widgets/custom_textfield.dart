import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/theme.dart';

/// Glass field: focus scale, purple glow, optional mic, error flash, password toggle.
class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
    this.validator,
    this.obscureText = false,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onFieldSubmitted,
    this.focusNode,
    this.errorFlashSeq = 0,
    this.voiceEnabled = false,
    this.voiceActive = false,
    this.onVoiceTap,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final bool obscureText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;

  /// Increment on submit-validation failure to flash invalid fields red briefly.
  final int errorFlashSeq;
  final bool voiceEnabled;
  final bool voiceActive;
  final VoidCallback? onVoiceTap;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> with TickerProviderStateMixin {
  final GlobalKey _ensureVisibleKey = GlobalKey();
  late FocusNode _focusNode;
  late bool _ownsFocus;
  bool _obscure = true;
  late AnimationController _glow;
  late AnimationController _scaleFocus;
  late AnimationController _errorFlash;

  @override
  void initState() {
    super.initState();
    _ownsFocus = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
    _scaleFocus = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _errorFlash = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      HapticFeedback.selectionClick();
      _glow.forward();
      _scaleFocus.forward();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _ensureVisibleKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: 0.12,
          );
        }
      });
    } else {
      _glow.reverse();
      _scaleFocus.reverse();
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorFlashSeq != oldWidget.errorFlashSeq) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final msg = widget.validator?.call(widget.controller.text);
        if (msg != null && mounted) {
          HapticFeedback.heavyImpact();
          _errorFlash.forward(from: 0);
        }
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocus) _focusNode.dispose();
    _glow.dispose();
    _scaleFocus.dispose();
    _errorFlash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    final showObscure = widget.isPassword ? _obscure : widget.obscureText;

    return AnimatedBuilder(
      animation: Listenable.merge([_glow, _scaleFocus, _errorFlash]),
      builder: (context, child) {
        final g = CurvedAnimation(parent: _glow, curve: Curves.easeOutCubic);
        final blurSigma = 10 + 6 * g.value;
        final scaleLift = 1 + 0.02 * CurvedAnimation(parent: _scaleFocus, curve: Curves.easeOutCubic).value;

        final purpleBorder = Color.lerp(
          Colors.white.withOpacity(0.14),
          AppColors.purple.withOpacity(0.88),
          g.value,
        )!;
        final errT = _errorFlash.value;
        final redPeak = errT <= 0.5 ? errT * 2 : (1 - errT) * 2;
        final borderColor = Color.lerp(
          purpleBorder,
          const Color(0xFFF87171),
          redPeak * 0.92,
        )!;
        final shadowOpacity = 0.12 + 0.22 * g.value + redPeak * 0.15;

        return Transform.scale(
          scale: scaleLift,
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06 + 0.03 * g.value),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: focused || redPeak > 0.05 ? 1.4 : 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withOpacity(shadowOpacity),
                      blurRadius: 16 + 8 * g.value,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      child: KeyedSubtree(
        key: _ensureVisibleKey,
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: showObscure,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
          cursorColor: AppColors.purple,
          validator: widget.validator,
          onFieldSubmitted: widget.onFieldSubmitted,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.transparent,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            labelText: widget.label,
            hintText: widget.hint,
            labelStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.95),
              fontWeight: FontWeight.w500,
            ),
            hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.55)),
            prefixIcon: Icon(widget.icon, color: focused ? AppColors.purple : AppColors.textSecondary, size: 22),
            suffixIcon: _buildSuffix(focused),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          ),
        ),
      ),
    );
  }

  Widget? _buildSuffix(bool focused) {
    final widgets = <Widget>[];
    if (widget.voiceEnabled) {
      widgets.add(
        IconButton(
          tooltip: 'Voice input',
          splashRadius: 22,
          onPressed: widget.onVoiceTap,
          icon: Icon(
            widget.voiceActive ? Icons.mic_rounded : Icons.mic_none_rounded,
            color: widget.voiceActive ? AppColors.accentCyan : AppColors.textSecondary,
            size: 22,
          ),
        ),
      );
    }
    if (widget.isPassword) {
      widgets.add(
        IconButton(
          splashRadius: 22,
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() => _obscure = !_obscure);
          },
          icon: Icon(
            _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
        ),
      );
    }
    if (widgets.isEmpty) return null;
    if (widgets.length == 1) return widgets.first;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}
