// lib/features/auth/widgets/password_strength_indicator.dart

import 'package:flutter/material.dart';
import '../../../core/theme.dart';

// ════════════════════════════════════════════════════════════════════════════
// PasswordStrength enum
// ════════════════════════════════════════════════════════════════════════════

enum PasswordStrength {
  empty,
  weak,
  fair,
  strong,
  veryStrong;

  String get label {
    switch (this) {
      case PasswordStrength.empty:      return '';
      case PasswordStrength.weak:       return 'Weak';
      case PasswordStrength.fair:       return 'Fair';
      case PasswordStrength.strong:     return 'Strong';
      case PasswordStrength.veryStrong: return 'Very Strong';
    }
  }

  Color get color {
    switch (this) {
      case PasswordStrength.empty:      return Colors.transparent;
      case PasswordStrength.weak:       return const Color(0xFFE53935);
      case PasswordStrength.fair:       return const Color(0xFFFFA726);
      case PasswordStrength.strong:     return const Color(0xFF66BB6A);
      case PasswordStrength.veryStrong: return FarmAidTheme.primaryGreen;
    }
  }

  int get filledSegments {
    switch (this) {
      case PasswordStrength.empty:      return 0;
      case PasswordStrength.weak:       return 1;
      case PasswordStrength.fair:       return 2;
      case PasswordStrength.strong:     return 3;
      case PasswordStrength.veryStrong: return 4;
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Rule model
// ════════════════════════════════════════════════════════════════════════════

class _Rule {
  final String label;
  final bool Function(String) passes;
  const _Rule({required this.label, required this.passes});
}

// ════════════════════════════════════════════════════════════════════════════
// PasswordStrengthIndicator
// ════════════════════════════════════════════════════════════════════════════

class PasswordStrengthIndicator extends StatefulWidget {
  final String password;
  final ValueChanged<PasswordStrength>? onStrengthChanged;
  final bool showChecklist;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.onStrengthChanged,
    this.showChecklist = true,
  });

  @override
  State<PasswordStrengthIndicator> createState() =>
      _PasswordStrengthIndicatorState();
}

class _PasswordStrengthIndicatorState
    extends State<PasswordStrengthIndicator>
    with SingleTickerProviderStateMixin {

  // FIX — each RegExp is a separate clean string literal, no concatenation
  static final List<_Rule> _rules = [
    _Rule(
      label:  'At least 8 characters',
      passes: (p) => p.length >= 8,
    ),
    _Rule(
      label:  'One uppercase letter (A–Z)',
      passes: (p) => p.contains(RegExp(r'[A-Z]')),
    ),
    _Rule(
      label:  'One lowercase letter (a–z)',
      passes: (p) => p.contains(RegExp(r'[a-z]')),
    ),
    _Rule(
      label:  'One number (0–9)',
      passes: (p) => p.contains(RegExp(r'[0-9]')),
    ),
    _Rule(
      label:  'One special character (!@#\$%...)',
      // FIX — single clean raw string, no multi-part concatenation
      passes: (p) => p.contains(RegExp(r'[!@#$%^&*()\-_=+\[\]{};:,./<>?\\|`~]')),
    ),
  ];

  late AnimationController _barController;
  late Animation<double>   _barAnimation;
  PasswordStrength _lastStrength = PasswordStrength.empty;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 400),
    );
    _barAnimation = CurvedAnimation(
      parent: _barController,
      curve:  Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(PasswordStrengthIndicator old) {
    super.didUpdateWidget(old);
    if (old.password != widget.password) {
      final newStrength = _evaluate(widget.password);
      if (newStrength != _lastStrength) {
        _lastStrength = newStrength;
        _barController.forward(from: 0);
        widget.onStrengthChanged?.call(newStrength);
      }
    }
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  PasswordStrength _evaluate(String password) {
    if (password.isEmpty) return PasswordStrength.empty;
    final passed = _rules.where((r) => r.passes(password)).length;
    if (passed <= 2) return PasswordStrength.weak;
    if (passed == 3) return PasswordStrength.fair;
    if (passed == 4) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  @override
  Widget build(BuildContext context) {
    final password = widget.password;
    final strength = _evaluate(password);
    final isDark   = Theme.of(context).brightness == Brightness.dark;

    if (password.isEmpty) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve:    Curves.easeOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // ── Segmented bar ─────────────────────────────────────────
          _StrengthBar(
            strength:  strength,
            animation: _barAnimation,
            isDark:    isDark,
          ),
          const SizedBox(height: 6),

          // ── Label row ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password strength',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? Colors.white38
                      : Colors.black38,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) =>
                    FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end:   Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Text(
                  strength.label,
                  key:   ValueKey(strength),
                  style: TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w700,
                    color:      strength.color,
                  ),
                ),
              ),
            ],
          ),

          // ── Checklist ─────────────────────────────────────────────
          if (widget.showChecklist) ...[
            const SizedBox(height: 12),
            ...List.generate(_rules.length, (i) {
              final rule   = _rules[i];
              final passes = rule.passes(password);
              return _RuleRow(
                label:  rule.label,
                passes: passes,
                isDark: isDark,
              );
            }),
          ],

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _StrengthBar
// ════════════════════════════════════════════════════════════════════════════

class _StrengthBar extends StatelessWidget {
  final PasswordStrength  strength;
  final Animation<double> animation;
  final bool              isDark;

  const _StrengthBar({
    required this.strength,
    required this.animation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const segmentCount = 4;
    const gap          = 4.0;

    return LayoutBuilder(builder: (context, constraints) {
      final segmentWidth =
          (constraints.maxWidth - gap * (segmentCount - 1)) /
              segmentCount;

      return Row(
        children: List.generate(segmentCount, (i) {
          final isFilled = i < strength.filledSegments;

          return Padding(
            padding: EdgeInsets.only(
                right: i < segmentCount - 1 ? gap : 0),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final segmentProgress =
                    ((animation.value * segmentCount) - i)
                        .clamp(0.0, 1.0);

                return Container(
                  width:  segmentWidth,
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isDark
                        ? Colors.white12
                        : Colors.black.withOpacity(0.07),
                  ),
                  child: FractionallySizedBox(
                    alignment:   Alignment.centerLeft,
                    widthFactor: isFilled ? segmentProgress : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color:        strength.color,
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color: strength.color
                                      .withOpacity(0.4),
                                  blurRadius: 4,
                                  offset:
                                      const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      );
    });
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _RuleRow
// ════════════════════════════════════════════════════════════════════════════

class _RuleRow extends StatelessWidget {
  final String label;
  final bool   passes;
  final bool   isDark;

  const _RuleRow({
    required this.label,
    required this.passes,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final passColor = FarmAidTheme.primaryGreen;
    final failColor =
        isDark ? Colors.white38 : Colors.black38;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          // ── Circle icon ───────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width:  18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: passes
                  ? passColor.withOpacity(0.12)
                  : Colors.transparent,
              border: Border.all(
                color: passes ? passColor : failColor,
                width: 1.5,
              ),
            ),
            child: passes
                ? Icon(Icons.check_rounded,
                    size: 11, color: passColor)
                : null,
          ),
          const SizedBox(width: 8),

          // ── Label ────────────────────────────────────────────
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize:   12,
                height:     1.3,
                color:      passes ? passColor : failColor,
                fontWeight: passes
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}