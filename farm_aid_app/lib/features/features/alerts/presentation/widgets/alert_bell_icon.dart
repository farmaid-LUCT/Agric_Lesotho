import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/alert_service.dart' ;
import '../alerts_screen.dart';

class AlertBellIcon extends StatefulWidget {
  const AlertBellIcon({super.key});

  @override
  State<AlertBellIcon> createState() => _AlertBellIconState();
}

class _AlertBellIconState extends State<AlertBellIcon>
    with SingleTickerProviderStateMixin {

  final AlertService _service = AlertService();
  Timer? _timer;
  int _unreadCount = 0;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // ── Shake animation when new alert arrives ────────────────────────────
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end:  8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin:-8.0, end:  8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end:  0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    // ── Initial fetch + start polling ─────────────────────────────────────
    _fetchCount();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _fetchCount());
  }

  Future<void> _fetchCount() async {
    final count = await _service.fetchUnreadCount();
    if (!mounted) return;
    final hadNone = _unreadCount == 0;
    setState(() => _unreadCount = count);
    // Shake the bell only when new alerts arrive
    if (count > 0 && hadNone) {
      _shakeController.forward(from: 0);
    }
  }

  void _openAlerts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AlertsScreen()),
    );
    // After returning from alerts screen, refresh count
    _fetchCount();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _unreadCount > 0
          ? '$_unreadCount unread alert${_unreadCount == 1 ? '' : 's'}'
          : 'Alerts',
      onPressed: _openAlerts,
      icon: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) => Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Bell icon ──────────────────────────────────────────────
            Icon(
              _unreadCount > 0
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_outlined,
              color: _unreadCount > 0
                  ? Colors.white
                  : Colors.white70,
              size: 26,
            ),

            // ── Red badge (only shown when unread > 0) ─────────────────
            if (_unreadCount > 0)
              Positioned(
                top:   -4,
                right: -4,
                child: AnimatedScale(
                  scale: _unreadCount > 0 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.elasticOut,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _unreadCount > 9 ? 4 : 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),   // red-700
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadCount > 99 ? '99+' : '$_unreadCount',
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   9,
                        fontWeight: FontWeight.w700,
                        height:     1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}