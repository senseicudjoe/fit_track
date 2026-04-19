import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';

class PedometerService {
  PedometerService._();
  static final instance = PedometerService._();

  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;

  int _stepsToday = 0;
  String _status  = 'stopped';
  String? _uid;
  int? _lastTotalSteps;
  SharedPreferences? _prefs;

  int    get stepsToday => _stepsToday;
  String get status     => _status;

  // Callbacks so providers can react to changes
  void Function(int steps)?   onStepUpdate;
  void Function(String status)? onStatusUpdate;

  // ── Start ────────────────────────────────────────────────────────────────────
  Future<void> start(String uid) async {
    // Clean up any existing subscriptions
    await stop();
    
    _uid = uid;
    _prefs ??= await SharedPreferences.getInstance();

    // Load the last total step count recorded on this device to calculate deltas
    _lastTotalSteps = _prefs?.getInt('last_total_steps_$_uid');

    // Load today's cached steps from SQLite
    final today = _todayKey();
    _stepsToday = await DatabaseService.instance.getStepsForDate(uid, today);
    onStepUpdate?.call(_stepsToday);

    _stepSub = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepError,
      cancelOnError: false,
    );

    _statusSub = Pedometer.pedestrianStatusStream.listen(
      _onPedestrianStatus,
      onError: _onStatusError,
      cancelOnError: false,
    );
  }

  // ── Stop ─────────────────────────────────────────────────────────────────────
  Future<void> stop() async {
    await _stepSub?.cancel();
    await _statusSub?.cancel();
    _stepSub   = null;
    _statusSub = null;
  }

  // ── Handlers ──────────────────────────────────────────────────────────────────
  void _onStepCount(StepCount event) {
    if (_uid == null) return;

    if (_lastTotalSteps == null) {
      // First event for this user session; establish the baseline
      _lastTotalSteps = event.steps;
      _prefs?.setInt('last_total_steps_$_uid', _lastTotalSteps!);
      return;
    }

    // Calculate how many steps were taken since the last event
    final int delta = event.steps - _lastTotalSteps!;
    
    if (delta == 0) return;

    int actualDelta = delta;
    if (delta < 0) {
      // Device was likely rebooted, so the hardware counter reset to 0
      actualDelta = event.steps;
    }

    if (actualDelta > 0) {
      _stepsToday += actualDelta;
      _lastTotalSteps = event.steps;
      
      // Update local state and notify listeners
      onStepUpdate?.call(_stepsToday);

      // Persist state
      _prefs?.setInt('last_total_steps_$_uid', _lastTotalSteps!);
      DatabaseService.instance.upsertSteps(_uid!, _todayKey(), _stepsToday);
    }
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    _status = event.status; // 'walking' | 'stopped'
    onStatusUpdate?.call(_status);
  }

  void _onStepError(Object error) {
    _status = 'unavailable';
    onStatusUpdate?.call(_status);
  }

  void _onStatusError(Object error) {
    _status = 'unavailable';
    onStatusUpdate?.call(_status);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  // Reset counter at midnight (called by StatsProvider)
  void resetForNewDay() {
    _stepsToday = 0;
    onStepUpdate?.call(_stepsToday);
    // Note: We do NOT reset _lastTotalSteps here because the hardware counter 
    // is cumulative since boot, not daily.
  }
}
