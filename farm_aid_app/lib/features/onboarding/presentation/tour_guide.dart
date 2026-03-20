// lib/features/onboarding/presentation/tour_guide.dart
//
// Spotlight tour guide — shown once to new users right after WizardScreen.
//
// USAGE IN HomeDashboard:
//   1. Create a TourKeys instance as a field: final _tourKeys = TourKeys();
//   2. Attach keys to widgets (see home_dashboard.dart).
//   3. In initState, after first frame:
//        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTour());
//   4. Implement _maybeShowTour():
//        if (widget.showTour) TourGuide.show(context, steps: TourGuide.homeDashboardSteps(_tourKeys));

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Tour step definition ───────────────────────────────────────────────────
class TourStep {
  final GlobalKey targetKey;
  final String    title;
  final String    body;
  final IconData  icon;
  final bool      useCircle;

  const TourStep({
    required this.targetKey,
    required this.title,
    required this.body,
    required this.icon,
    this.useCircle = false,
  });
}

// ── GlobalKey holder — instantiate once in HomeDashboard ──────────────────
class TourKeys {
  final logo        = GlobalKey();
  final alertBell   = GlobalKey();
  final scannerCard = GlobalKey();
  final navBar      = GlobalKey();
  final navWeather  = GlobalKey();
  final navCrops    = GlobalKey();
  final navHistory  = GlobalKey();
}

// ── Public API ─────────────────────────────────────────────────────────────
class TourGuide {
  static const _prefKey = 'tour_completed';

  static Future<void> show(
    BuildContext context, {
    required List<TourStep> steps,
    VoidCallback? onComplete,
  }) async {
    await Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) => _TourOverlay(
        steps:      steps,
        onComplete: onComplete,
      ),
    ));
  }

  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  static Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  // ── Step definitions (matched to HomeDashboard widget tree) ─────────────
  static List<TourStep> homeDashboardSteps(TourKeys k) => [
    TourStep(
      targetKey: k.logo,
      title:     'Welcome to FarmAid 👋',
      body:      'Your smart farming companion for Lesotho. Scan crops, track diseases and get advice tailored to your farm.',
      icon:      Icons.eco_rounded,
      useCircle: true,
    ),
    TourStep(
      targetKey: k.alertBell,
      title:     'Disease Alerts 🔔',
      body:      'We notify you about outbreaks in your district. Tap the bell to see all active alerts.',
      icon:      Icons.notifications_none_rounded,
      useCircle: true,
    ),
    TourStep(
      targetKey: k.scannerCard,
      title:     'Scan Your Crops 📸',
      body:      'Take a photo or upload one from your gallery. Our AI identifies diseases and gives you personalised treatment advice in seconds.',
      icon:      Icons.document_scanner_outlined,
    ),
    TourStep(
      targetKey: k.navWeather,
      title:     'Weather Forecast ☀️',
      body:      'Check local weather conditions that affect your crops and spraying schedule.',
      icon:      Icons.wb_sunny_outlined,
    ),
    TourStep(
      targetKey: k.navCrops,
      title:     'Manage Crop Profiles 🌱',
      body:      'Register your crops, soil type and plot size so FarmAid can give you personalised recommendations.',
      icon:      Icons.grass_rounded,
    ),
    TourStep(
      targetKey: k.navHistory,
      title:     'Scan History 📋',
      body:      'All your past diagnoses are saved here. Track treatment progress and review old scans anytime.',
      icon:      Icons.history_rounded,
    ),
  ];
}

// ── Overlay widget ─────────────────────────────────────────────────────────
class _TourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final VoidCallback?  onComplete;
  const _TourOverlay({required this.steps, this.onComplete});

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay>
    with SingleTickerProviderStateMixin {

  int   _current     = 0;
  Rect? _targetRect;

  late AnimationController _cardCtrl;
  late Animation<double>   _cardSlide;
  late Animation<double>   _cardOpacity;

  @override
  void initState() {
    super.initState();
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _cardSlide = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic)
        .drive(Tween(begin: 60.0, end: 0.0));
    _cardOpacity = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));

    WidgetsBinding.instance.addPostFrameCallback((_) => _goToStep(0));
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    super.dispose();
  }

  Rect? _rectFor(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _goToStep(int index) {
    if (index >= widget.steps.length) { _finish(); return; }
    final rect = _rectFor(widget.steps[index].targetKey);
    _cardCtrl.reset();
    setState(() { _current = index; _targetRect = rect; });
    _cardCtrl.forward();
  }

  Future<void> _finish() async {
    await TourGuide.markComplete();
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onComplete?.call();
  }

  void _next() => _goToStep(_current + 1);
  void _skip() => _finish();

  @override
  Widget build(BuildContext context) {
    final step  = widget.steps[_current];
    final total = widget.steps.length;
    final size  = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dark overlay with spotlight cutout
          if (_targetRect != null)
            _AnimatedSpotlight(
              targetRect: _targetRect!,
              useCircle:  step.useCircle,
              screenSize: size,
            ),

          // Tap dark area to advance
          Positioned.fill(
            child: GestureDetector(
              onTap: _next,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),

          // Pulsing border around target
          if (_targetRect != null)
            _HighlightBorder(rect: _targetRect!, useCircle: step.useCircle),

          // Step card slides up from bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _cardCtrl,
              builder: (_, __) => Opacity(
                opacity: _cardOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, _cardSlide.value),
                  child: _StepCard(
                    step:    step,
                    current: _current,
                    total:   total,
                    onNext:  _next,
                    onSkip:  _skip,
                  ),
                ),
              ),
            ),
          ),

          // Skip button top-right
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: GestureDetector(
              onTap: _skip,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Text(
                  'Skip tour',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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

// ── Animated spotlight (slides smoothly between targets) ──────────────────
class _AnimatedSpotlight extends StatefulWidget {
  final Rect targetRect;
  final bool useCircle;
  final Size screenSize;
  const _AnimatedSpotlight({
    required this.targetRect,
    required this.useCircle,
    required this.screenSize,
  });

  @override
  State<_AnimatedSpotlight> createState() => _AnimatedSpotlightState();
}

class _AnimatedSpotlightState extends State<_AnimatedSpotlight>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<Rect?>    _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _anim = RectTween(begin: widget.targetRect, end: widget.targetRect)
        .animate(_ctrl);
    _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_AnimatedSpotlight old) {
    super.didUpdateWidget(old);
    if (old.targetRect != widget.targetRect) {
      _anim = RectTween(begin: old.targetRect, end: widget.targetRect)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => CustomPaint(
      size: widget.screenSize,
      painter: _SpotlightPainter(
        targetRect: _anim.value ?? widget.targetRect,
        useCircle:  widget.useCircle,
      ),
    ),
  );
}

// ── Spotlight painter ──────────────────────────────────────────────────────
class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final bool useCircle;
  const _SpotlightPainter({required this.targetRect, required this.useCircle});

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 14.0;
    final expanded = targetRect.inflate(pad);
    final path = Path()
      ..addRect(Offset.zero & size)
      ..fillType = PathFillType.evenOdd;

    if (useCircle) {
      final r = max(expanded.width, expanded.height) / 2;
      path.addOval(Rect.fromCircle(center: expanded.center, radius: r));
    } else {
      path.addRRect(RRect.fromRectAndRadius(expanded, const Radius.circular(16)));
    }

    canvas.drawPath(path, Paint()..color = Colors.black.withOpacity(0.78));
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.targetRect != targetRect || old.useCircle != useCircle;
}

// ── Pulsing highlight border ───────────────────────────────────────────────
class _HighlightBorder extends StatefulWidget {
  final Rect targetRect;
  final bool useCircle;
  const _HighlightBorder({required this.rect, required this.useCircle})
      : targetRect = rect;
  final Rect rect;

  @override
  State<_HighlightBorder> createState() => _HighlightBorderState();
}

class _HighlightBorderState extends State<_HighlightBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const pad = 14.0;
    final expanded = widget.targetRect.inflate(pad);

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final opacity = 0.45 + _pulse.value * 0.55;
        return Positioned(
          left: expanded.left, top: expanded.top,
          width: expanded.width, height: expanded.height,
          child: IgnorePointer(
            child: widget.useCircle
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF69F0AE).withOpacity(opacity),
                        width: 2.5,
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF69F0AE).withOpacity(opacity),
                        width: 2.5,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

// ── Step card ──────────────────────────────────────────────────────────────
class _StepCard extends StatelessWidget {
  final TourStep     step;
  final int          current;
  final int          total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _StepCard({
    required this.step,
    required this.current,
    required this.total,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = current == total - 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 36),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2B1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.22)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.55),
              blurRadius: 32, offset: const Offset(0, -4)),
          BoxShadow(color: const Color(0xFF69F0AE).withOpacity(0.07),
              blurRadius: 20),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Progress dots
          Row(
            children: List.generate(total, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 5),
              width:  i == current ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: i == current
                    ? const Color(0xFF69F0AE)
                    : const Color(0xFF69F0AE).withOpacity(0.22),
              ),
            )),
          ),

          const SizedBox(height: 18),

          // Icon + title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF69F0AE).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(step.icon, color: const Color(0xFF69F0AE), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Body text
          Text(
            step.body,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.72),
              height: 1.6,
            ),
          ),

          const SizedBox(height: 22),

          // Bottom row: counter + next button
          Row(
            children: [
              Text(
                '${current + 1} of $total',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.38),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onNext,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF69F0AE),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF69F0AE).withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    isLast ? "Let's go! 🚀" : 'Next →',
                    style: const TextStyle(
                      color: Color(0xFF0D2B1E),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}