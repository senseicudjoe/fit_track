import 'dart:async';

enum TimerPhase { work, rest, cooldown, idle }

class TimerService {
  TimerService._();
  static final instance = TimerService._();

  Timer? _ticker;

  // Config
  int _workSeconds    = 40;
  int _restSeconds    = 20;
  int _cooldownSeconds = 60;
  int _totalRounds    = 8;

  // State
  TimerPhase _phase         = TimerPhase.idle;
  int _secondsRemaining     = 0;
  int _currentRound         = 0;
  bool _isRunning           = false;
  int _totalElapsedSeconds  = 0;
  List<int> _splits         = []; // seconds taken per completed round

  // Getters
  TimerPhase get phase            => _phase;
  int get secondsRemaining        => _secondsRemaining;
  int get currentRound            => _currentRound;
  bool get isRunning              => _isRunning;
  int get totalRounds             => _totalRounds;
  int get totalElapsedSeconds     => _totalElapsedSeconds;
  List<int> get splits            => List.unmodifiable(_splits);
  bool get isFinished             => _phase == TimerPhase.idle && _currentRound > 0;

  // Callbacks
  void Function(int seconds)?     onTick;
  void Function(TimerPhase phase, int round)? onPhaseChange;
  void Function(List<int> splits)? onComplete;

  // ── Configure ─────────────────────────────────────────────────────────────────
  void configure({
    int workSeconds    = 40,
    int restSeconds    = 20,
    int cooldownSeconds = 60,
    int totalRounds    = 8,
  }) {
    _workSeconds     = workSeconds;
    _restSeconds     = restSeconds;
    _cooldownSeconds = cooldownSeconds;
    _totalRounds     = totalRounds;
  }

  // ── Start ─────────────────────────────────────────────────────────────────────
  void start() {
    if (_isRunning) return;
    _currentRound      = 1;
    _splits            = [];
    _totalElapsedSeconds = 0;
    _setPhase(TimerPhase.work);
    _isRunning = true;
    _tick();
  }

  // ── Pause / Resume ────────────────────────────────────────────────────────────
  void pause() {
    _ticker?.cancel();
    _isRunning = false;
  }

  void resume() {
    if (_isRunning || _phase == TimerPhase.idle) return;
    _isRunning = true;
    _tick();
  }

  // ── Skip current phase ────────────────────────────────────────────────────────
  void skip() {
    _ticker?.cancel();
    _advance();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────────
  void reset() {
    _ticker?.cancel();
    _ticker   = null;
    _isRunning = false;
    _phase     = TimerPhase.idle;
    _secondsRemaining  = 0;
    _currentRound      = 0;
    _totalElapsedSeconds = 0;
    _splits  = [];
  }

  // ── Internal tick ─────────────────────────────────────────────────────────────
  void _tick() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsRemaining--;
      _totalElapsedSeconds++;
      onTick?.call(_secondsRemaining);

      if (_secondsRemaining <= 0) {
        _ticker?.cancel();
        _advance();
      }
    });
  }

  void _advance() {
    switch (_phase) {
      case TimerPhase.work:
        _splits.add(_workSeconds); // record split
        if (_currentRound >= _totalRounds) {
          _setPhase(TimerPhase.cooldown);
        } else {
          _setPhase(TimerPhase.rest);
        }

      case TimerPhase.rest:
        _currentRound++;
        _setPhase(TimerPhase.work);

      case TimerPhase.cooldown:
        _finish();

      case TimerPhase.idle:
        break;
    }

    if (_isRunning && _phase != TimerPhase.idle) _tick();
  }

  void _setPhase(TimerPhase phase) {
    _phase = phase;
    _secondsRemaining = switch (phase) {
      TimerPhase.work     => _workSeconds,
      TimerPhase.rest     => _restSeconds,
      TimerPhase.cooldown => _cooldownSeconds,
      TimerPhase.idle     => 0,
    };
    onPhaseChange?.call(_phase, _currentRound);
  }

  void _finish() {
    _isRunning = false;
    _phase     = TimerPhase.idle;
    onComplete?.call(_splits);
  }

  // ── Formatted display strings ─────────────────────────────────────────────────
  String get displayTime {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining  % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get phaseLabel => switch (_phase) {
    TimerPhase.work     => 'Work',
    TimerPhase.rest     => 'Rest',
    TimerPhase.cooldown => 'Cool down',
    TimerPhase.idle     => '—',
  };
}