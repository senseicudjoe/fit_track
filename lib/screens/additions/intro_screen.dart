import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/constants.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      icon: Icons.directions_run_rounded,
      color: AppColors.teal,
      title: 'Track every workout',
      body:
          'Log runs, HIIT sessions, strength training and more. Every rep and every kilometre, captured.',
    ),
    _Slide(
      icon: Icons.flag_rounded,
      color: AppColors.primary,
      title: 'Set goals that stick',
      body:
          'Define daily step targets, calorie goals and weekly workout counts. Watch your progress in real time.',
    ),
    _Slide(
      icon: Icons.timer_rounded,
      color: AppColors.amber,
      title: 'Built-in interval timer',
      body:
          'Custom work, rest and cool-down intervals. Automatic splits so you can focus on the session.',
    ),
    _Slide(
      icon: Icons.bar_chart_rounded,
      color: AppColors.coral,
      title: 'Insights that motivate',
      body:
          'Weekly trends, streak tracking and performance tips personalised to how you train.',
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [

            // ── Skip button ──────────────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(
                    top: AppSpacing.lg, right: AppSpacing.lg),
                child: _page < _slides.length - 1
                    ? TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text('Skip',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textHint)),
                      )
                    : const SizedBox(height: 36),
              ),
            ),

            // ── Page view ────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
              ),
            ),

            // ── Dots ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 22 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? _slides[_page].color
                          : AppColors.border,
                      borderRadius: AppRadius.full,
                    ),
                  );
                }),
              ),
            ),

            // ── CTA ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _slides[_page].color,
                      minimumSize: const Size(double.infinity, 52),
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.md),
                    ),
                    child: Text(
                      _page < _slides.length - 1 ? 'Next' : 'Get started',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                  if (_page == _slides.length - 1) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ',
                            style: AppTextStyles.caption),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Text('Sign in',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slide page ────────────────────────────────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final _Slide slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          // Icon badge
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              color: slide.color.withOpacity(0.12),
              borderRadius: AppRadius.xl,
              border: Border.all(
                  color: slide.color.withOpacity(0.25), width: 1),
            ),
            child: Icon(slide.icon, color: slide.color, size: 60),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Title
          Text(
            slide.title,
            style: AppTextStyles.heading1.copyWith(fontSize: 26),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Body
          Text(
            slide.body,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _Slide {
  final IconData icon;
  final Color color;
  final String title, body;
  const _Slide(
      {required this.icon, required this.color,
       required this.title, required this.body});
}
