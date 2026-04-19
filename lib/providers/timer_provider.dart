import 'package:flutter/foundation.dart';
import '../services/timer_service.dart';

class TimerProvider extends ChangeNotifier {
  final _timer = TimerService.instance;

  TimerPhase get phase            => _timer.phase;
  int get secondsRemaining        => _timer.secondsRemaining;
  int get currentRound            => _timer.currentRound;
  int get totalRounds             => _timer.totalRounds;
  bool get isRunning              => _timer.isRunning;
  bool get isFinished             => _timer.isFinished;
  String get displayTime          => _timer.displayTime;
  String get phaseLabel           => _timer.phaseLabel;
  List<int> get splits            => _timer.splits;
  int get totalElapsedSeconds     => _timer.totalElapsedSeconds;

  TimerProvider() {
    _timer.onTick = (_) => notifyListeners();

    _timer.onPhaseChange = (phase, round) {
      // Audio calls removed
      notifyListeners();
    };

    _timer.onComplete = (splits) {
      // Audio calls removed
      notifyListeners();
    };
  }

  // ── Configure before starting ─────────────────────────────────────────────────
  void configure({
    int workSeconds     = 40,
    int restSeconds     = 20,
    int cooldownSeconds = 60,
    int totalRounds     = 8,
  }) {
    _timer.configure(
      workSeconds:     workSeconds,
      restSeconds:     restSeconds,
      cooldownSeconds: cooldownSeconds,
      totalRounds:     totalRounds,
    );
    notifyListeners();
  }

  void start()  => _timer.start();
  void pause()  => _timer.pause();
  void resume() => _timer.resume();
  void skip()   => _timer.skip();
  void reset()  { _timer.reset(); notifyListeners(); }

  // Progress 0.0 → 1.0 within the current phase (for animated ring)
  double get phaseProgress {
    final total = switch (phase) {
      TimerPhase.work     => 40,
      TimerPhase.rest     => 20,
      TimerPhase.cooldown => 60,
      TimerPhase.idle     => 1,
    };
    return 1.0 - (secondsRemaining / total).clamp(0.0, 1.0);
  }

  // Overall session progress 0.0 → 1.0
  double get sessionProgress {
    if (totalRounds == 0) return 0;
    return ((currentRound - 1) / totalRounds).clamp(0.0, 1.0);
  }
}
