import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.4, 0.8, curve: Curves.easeIn)),
    );
    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.4, 0.8, curve: Curves.easeOut)),
    );

    _ctrl.forward();

    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) context.go('/intro');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadius.xl,
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: Colors.white, size: 52),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FadeTransition(
              opacity: _textFade,
              child: SlideTransition(
                position: _textSlide,
                child: Column(
                  children: [
                    Text('FitTrack',
                        style: AppTextStyles.heading1
                            .copyWith(fontSize: 32, letterSpacing: -0.5)),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Your personal fitness companion',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
            FadeTransition(opacity: _textFade, child: const _PulseDots()),
          ],
        ),
      ),
    );
  }
}

class _PulseDots extends StatefulWidget {
  const _PulseDots();

  @override
  State<_PulseDots> createState() => _PulseDotsState();
}

class _PulseDotsState extends State<_PulseDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final delay = i / 3;
          final t     = ((_ctrl.value - delay) % 1.0 + 1.0) % 1.0;
          final scale = 0.6 + 0.4 * (1 - (t * 2 - 1).abs());
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 7 * scale, height: 7 * scale,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.4 + 0.6 * scale),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}
