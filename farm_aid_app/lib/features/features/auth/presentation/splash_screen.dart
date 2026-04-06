import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../dashboard/presentation/home_dashboard.dart';
import '../../onboarding/presentation/wizard_screen.dart';
import '../../auth/presentation/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  int _phase = 0;

  late AnimationController _wheatCtrl;
  late Animation<double> _wheatScale;

  late AnimationController _logoCtrl;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoSlide;

  late AnimationController _taglineCtrl;
  late Animation<double> _taglineOpacity;
  late Animation<double> _taglineSlide;

  late AnimationController _breatheCtrl;
  late AnimationController _raysCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _progressCtrl;
  late AnimationController _swayCtrl;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    _wheatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _wheatScale = CurvedAnimation(
            parent: _wheatCtrl, curve: const Cubic(0.34, 1.56, 0.64, 1))
        .drive(Tween(begin: 0.0, end: 1.0));

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _logoOpacity = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _logoSlide = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic)
        .drive(Tween(begin: 18.0, end: 0.0));

    _taglineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _taglineOpacity = CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _taglineSlide = CurvedAnimation(
            parent: _taglineCtrl, curve: Curves.easeOutCubic)
        .drive(Tween(begin: 10.0, end: 0.0));

    _breatheCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3500))
      ..repeat(reverse: true);

    _raysCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500))
      ..repeat(reverse: true);

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();

    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));

    _swayCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _phase = 1);
    _wheatCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _phase = 2);
    _logoCtrl.forward();
    _progressCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _phase = 3);
    _taglineCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() => _phase = 4);

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _navigate();
  }

  Future<void> _navigate() async {
    try {
      // Added a 3-second timeout to prevent infinite hanging on storage read
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 3));
      final firstRun = prefs.getBool('first_run') ?? true;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              firstRun ? const WizardScreen() : const HomeDashboard(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Navigation Error: $e");
      // Fallback: Send user to LoginScreen if any error occurs
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _wheatCtrl.dispose();
    _logoCtrl.dispose();
    _taglineCtrl.dispose();
    _breatheCtrl.dispose();
    _raysCtrl.dispose();
    _particleCtrl.dispose();
    _progressCtrl.dispose();
    _swayCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF0d2b1e),
        child: Stack(
          children: [
            AnimatedOpacity(
              opacity: _phase >= 1 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 1200),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.4),
                    radius: 1.2,
                    colors: [
                      Color(0xFF52b788),
                      Color(0xFF40916c),
                      Color(0xFF2d6a4f),
                      Color(0xFF1a4731),
                      Color(0xFF0d2b1e),
                    ],
                    stops: [0.0, 0.28, 0.55, 0.80, 1.0],
                  ),
                ),
              ),
            ),
            if (_phase >= 1)
              Positioned(
                top: size.height * 0.18 - 80,
                left: size.width / 2 - 80,
                child: AnimatedBuilder(
                  animation: _breatheCtrl,
                  builder: (_, __) {
                    final s = 1.0 + _breatheCtrl.value * 0.12;
                    return Transform.scale(
                      scale: s,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF95d5b2).withOpacity(0.55),
                              const Color(0xFF40916c).withOpacity(0.25),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.45, 0.70],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_phase >= 1)
              Positioned(
                top: size.height * 0.24 - 150,
                left: size.width / 2 - 150,
                child: AnimatedBuilder(
                  animation: _raysCtrl,
                  builder: (_, __) => SizedBox(
                    width: 300,
                    height: 300,
                    child: CustomPaint(
                      painter: _RaysPainter(_raysCtrl.value),
                    ),
                  ),
                ),
              ),
            if (_phase >= 1)
              AnimatedBuilder(
                animation: _particleCtrl,
                builder: (_, __) => CustomPaint(
                  size: size,
                  painter: _ParticlePainter(_particleCtrl.value),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: size.height * 0.28,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xFF0d2b1e),
                      Color(0xFF1a4731),
                      Color(0xFF2d6a4f),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: size.height * 0.22,
              left: -size.width * 0.1,
              right: -size.width * 0.1,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF95d5b2).withOpacity(0.3),
                      const Color(0xFF95d5b2).withOpacity(0.5),
                      const Color(0xFF95d5b2).withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Positioned(
              bottom: size.height * 0.22,
              left: 0,
              right: 0,
              height: 180,
              child: AnimatedBuilder(
                animation: _swayCtrl,
                builder: (_, __) => Stack(
                  children: [
                    for (final s in _wheatStalks) _buildWheatStalk(s, size),
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _logoCtrl,
                    builder: (_, __) => Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _logoSlide.value),
                        child: _buildLogoBlock(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedBuilder(
                    animation: _taglineCtrl,
                    builder: (_, __) => Opacity(
                      opacity: _taglineOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _taglineSlide.value),
                        child: const Text(
                          'Intelligent Plant Health Advisor',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFA8A8A8),
                            letterSpacing: 0.84,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w300,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
            Positioned(
              bottom: 52,
              left: size.width / 2 - 60,
              child: SizedBox(
                width: 120,
                height: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Container(
                    color: Colors.white.withOpacity(0.12),
                    child: AnimatedBuilder(
                      animation: _progressCtrl,
                      builder: (_, __) => FractionallySizedBox(
                        widthFactor: _progressCtrl.value,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0x4D95d5b2),
                                Color(0xFF95d5b2),
                                Color(0x4D95d5b2),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _phase >= 3 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: const Text(
                  'Powered by AI · Built for Farmers',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0x4DFFFFFF),
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoBlock() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(38, 38),
              painter: _LeafIconPainter(),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FarmAID',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: const Color(0xFF95d5b2).withOpacity(0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'LESOTHO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Color(0x80FFFFFF),
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWheatStalk(_WheatConfig s, Size size) {
    final sway = _swayCtrl.value * 3.0 - 1.5;
    return Positioned(
      left: size.width * double.parse(s.xPercent.replaceAll('%', '')) / 100 -
          (26 * s.scale),
      bottom: 0,
      child: AnimatedBuilder(
        animation: _wheatCtrl,
        builder: (_, __) => Transform.scale(
          scale: _wheatScale.value,
          alignment: Alignment.bottomCenter,
          child: Opacity(
            opacity: _phase >= 1 ? s.opacity : 0.0,
            child: Transform.rotate(
              angle: sway *
                  (pi / 180) *
                  (s.xPercent.compareTo('50%') < 0 ? 1 : -1),
              alignment: Alignment.bottomCenter,
              child: CustomPaint(
                size: Size(52 * s.scale, 160 * s.scale),
                painter: _WheatPainter(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _wheatStalks = [
    _WheatConfig(xPercent: '18%', scale: 0.55, opacity: 0.45),
    _WheatConfig(xPercent: '28%', scale: 0.70, opacity: 0.55),
    _WheatConfig(xPercent: '38%', scale: 0.85, opacity: 0.65),
    _WheatConfig(xPercent: '50%', scale: 1.15, opacity: 1.00),
    _WheatConfig(xPercent: '62%', scale: 0.85, opacity: 0.65),
    _WheatConfig(xPercent: '72%', scale: 0.70, opacity: 0.55),
    _WheatConfig(xPercent: '82%', scale: 0.55, opacity: 0.45),
  ];
}

class _WheatConfig {
  final String xPercent;
  final double scale;
  final double opacity;
  const _WheatConfig(
      {required this.xPercent, required this.scale, required this.opacity});
}

class _WheatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = const Color(0xFF52b788)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final stemPath = Path()
      ..moveTo(cx, h)
      ..cubicTo(cx, h, cx - 2, h * 0.75, cx, h * 0.56)
      ..cubicTo(cx + 1, h * 0.44, cx, h * 0.25, cx, h * 0.06);
    canvas.drawPath(stemPath, stemPaint);
    void drawSide(double fromY, double toX, double toY, double opacity, double width) {
      final p = Paint()
        ..color = const Color(0xFF40916c).withOpacity(opacity)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(cx, fromY * h), Offset(toX * w, toY * h), p);
    }
    drawSide(0.625, 0.19, 0.5125, 0.8, 1.4);
    drawSide(0.55, 0.81, 0.4375, 0.8, 1.4);
    drawSide(0.45, 0.21, 0.3375, 0.7, 1.3);
    drawSide(0.375, 0.77, 0.2625, 0.7, 1.3);
    final headPaint = Paint()
      ..color = const Color(0xFF95d5b2).withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, h * 0.1125), width: w * 0.27, height: h * 0.175),
        headPaint);
    void drawSideHead(double cx2, double cy2, double rw, double rh, double angle, Color color, double opacity2) {
      canvas.save();
      canvas.translate(cx2 * w, cy2 * h);
      canvas.rotate(angle * pi / 180);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rw * w, height: rh * h),
        Paint()..color = color.withOpacity(opacity2)..style = PaintingStyle.fill,
      );
      canvas.restore();
    }
    drawSideHead(0.365, 0.175, 0.19, 0.125, -15, const Color(0xFF74c69d), 0.75);
    drawSideHead(0.635, 0.175, 0.19, 0.125, 15, const Color(0xFF74c69d), 0.75);
    drawSideHead(0.308, 0.2375, 0.154, 0.10, -22, const Color(0xFF52b788), 0.60);
    drawSideHead(0.692, 0.2375, 0.154, 0.10, 22, const Color(0xFF52b788), 0.60);
    final dotPaint = Paint()
      ..color = const Color(0xFFb7e4c7).withOpacity(0.7)
      ..style = PaintingStyle.fill;
    final dotYs = [0.0625, 0.0875, 0.1125, 0.1375, 0.1625, 0.1875];
    for (int i = 0; i < dotYs.length; i++) {
      final dx = i % 2 == 0 ? -2.0 : 2.0;
      canvas.drawCircle(Offset(cx + dx, dotYs[i] * h), 1.5, dotPaint);
    }
  }
  @override
  bool shouldRepaint(_WheatPainter old) => false;
}

class _LeafIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final leafPaint = Paint()
      ..color = const Color(0xFF95d5b2).withOpacity(0.9)
      ..style = PaintingStyle.fill;
    final leaf = Path()
      ..moveTo(cx, cy + size.height * 0.29)
      ..cubicTo(cx - size.width * 0.26, cy + 0.08 * size.height,
          cx - size.width * 0.21, cy - 0.29 * size.height, cx,
          cy - size.height * 0.29)
      ..cubicTo(cx + size.width * 0.21, cy - 0.29 * size.height,
          cx + size.width * 0.26, cy + 0.08 * size.height, cx,
          cy + size.height * 0.29);
    canvas.drawPath(leaf, leafPaint);
    final stemPaint = Paint()
      ..color = const Color(0xFF52b788)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, cy + size.height * 0.29),
        Offset(cx, cy - size.height * 0.26), stemPaint);
    final veinPaint = Paint()
      ..color = const Color(0xFF52b788).withOpacity(0.7)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, cy + 0.05 * size.height),
        Offset(cx - size.width * 0.18, cy - 0.08 * size.height), veinPaint);
    canvas.drawLine(Offset(cx, cy - 0.08 * size.height),
        Offset(cx + size.width * 0.18, cy - 0.21 * size.height), veinPaint);
  }
  @override
  bool shouldRepaint(_LeafIconPainter old) => false;
}

class _RaysPainter extends CustomPainter {
  final double progress;
  _RaysPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final opacity = 0.07 + (sin(progress * pi) * 0.11).clamp(0.0, 0.11);
    for (int i = 0; i < 8; i++) {
      final angle = i * (2 * pi / 8) + (i * 0.08);
      final paint = Paint()
        ..shader = LinearGradient(colors: [
          const Color(0xFF95d5b2).withOpacity(opacity),
          Colors.transparent,
        ]).createShader(Rect.fromCenter(center: Offset(cx, cy), width: 2, height: 160))
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      canvas.drawLine(Offset.zero, const Offset(0, 160), paint);
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(_RaysPainter old) => old.progress != progress;
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  static final _configs = List.generate(14, (i) => _PConfig(i));
  _ParticlePainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _configs) {
      final t = (progress + p.delay) % 1.0;
      final x = p.xFraction * size.width;
      final startY = size.height * 0.75;
      final y = startY - t * 60;
      final opacity = (() {
        if (t < 0.2) return t / 0.2;
        if (t < 0.8) return 1.0;
        return 1.0 - (t - 0.8) / 0.2;
      })() * (0.25 + p.opacityBonus);
      final paint = Paint()
        ..color = const Color(0xFF95d5b2).withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }
  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _PConfig {
  final double xFraction;
  final double delay;
  final double radius;
  final double opacityBonus;
  _PConfig(int i)
      : xFraction = (8 + (i * 7.1) % 86) / 100,
        delay = (i * 0.31) % 2.4 / (3.2 + (i * 0.4) % 2),
        radius = i % 3 == 0 ? 1.5 : 1.0,
        opacityBonus = (i % 4) * 0.1;
}