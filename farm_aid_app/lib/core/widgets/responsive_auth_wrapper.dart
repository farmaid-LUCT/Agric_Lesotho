// lib/core/widgets/responsive_auth_wrapper.dart
//
// Usage: wrap any screen's body content with this widget.
// On screens wider than 600px (tablet/desktop/Chrome) it renders
// the child inside a centered card with a max width of 480px.
// On mobile it renders the child full-width as normal.

import 'package:flutter/material.dart';

class ResponsiveAuthWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final bool addCard;

  const ResponsiveAuthWrapper({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.addCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 600;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isWide) return child;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: addCard
              ? Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 40,
                              offset: const Offset(0, 8),
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 40,
                              offset: const Offset(0, 8),
                            )
                          ],
                    border: isDark
                        ? Border.all(color: Colors.white10)
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 40),
                  child: child,
                )
              : child,
        ),
      ),
    );
  }
}