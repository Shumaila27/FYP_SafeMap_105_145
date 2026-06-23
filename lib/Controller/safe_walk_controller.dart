// lib/controllers/safe_walk_controller.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../Models/guardian_model.dart';
import '../services/guardian_service.dart';
import '../services/safe_walk_service.dart';

enum WalkState {
  idle,
  starting,
  active,
  emergency,
  ending,
}

class WalkValidation {
  final bool isValid;
  final String? error;

  const WalkValidation.ok()  : isValid = true,  error = null;
  const WalkValidation.fail(this.error) : isValid = false;
}

class SafeWalkController extends ChangeNotifier
    with WidgetsBindingObserver {

  final SafeWalkService  _walkSvc     = SafeWalkService.instance;
  final GuardianService  _guardianSvc = GuardianService();

  WalkState _state = WalkState.idle;
  WalkState get state => _state;

  bool get isIdle      => _state == WalkState.idle;
  bool get isStarting  => _state == WalkState.starting;
  bool get isActive    => _state == WalkState.active;
  bool get isEmergency => _state == WalkState.emergency;
  bool get isEnding    => _state == WalkState.ending;

  String? _error;
  String? get error => _error;

  String       _destination        = '';
  List<String> _selectedContactIds = [];

  String       get destination        => _destination;
  List<String> get selectedContactIds => List.unmodifiable(_selectedContactIds);

  Timer?   _timer;
  Duration _elapsed = Duration.zero;
  Duration get elapsed => _elapsed;

  String get elapsedString {
    final m = _elapsed.inMinutes;
    final s = _elapsed.inSeconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  SafeWalk? get currentWalk => _walkSvc.currentWalk;

  List<Guardian> get guardians => _guardianSvc.guardians;

  bool isSelected(String contactId) =>
      _selectedContactIds.contains(contactId);

  List<String> get _selectedProfileIds =>
      _guardianSvc.guardians
          .where((g) =>
      _selectedContactIds.contains(g.id) && g.isOnSafeMap)
          .map((g) => g.guardianProfileId!)
          .toList();

  // ════════════════════════════════════════════════════════════
  //  INIT  ✅ CHANGED — added GuardianService listener
  // ════════════════════════════════════════════════════════════

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);
    await _guardianSvc.initializeGuardians();

    // ✅ NEW: whenever GuardianService notifies (add/update/delete),
    //         forward it to the screen so it rebuilds instantly
    _guardianSvc.addListener(_onGuardiansChanged);

    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  //  ✅ NEW METHOD — forwards GuardianService changes to screen
  // ════════════════════════════════════════════════════════════

  void _onGuardiansChanged() {
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  //  ✅ NEW METHOD — force fresh fetch from Supabase
  //  Called by SafeWalkScreen.didPopNext() as a safety fallback
  //  when user navigates back from ProfileScreen
  // ════════════════════════════════════════════════════════════

  Future<void> reloadGuardians() async {
    await _guardianSvc.reload();
    // notifyListeners() already fires inside reload() → initializeGuardians()
  }

  // ════════════════════════════════════════════════════════════
  //  DISPOSE  ✅ CHANGED — remove GuardianService listener
  // ════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _guardianSvc.removeListener(_onGuardiansChanged); // ✅ NEW — prevent memory leak
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════
  //  LIFECYCLE OBSERVER — unchanged
  // ════════════════════════════════════════════════════════════

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && isActive) {
      _ensureTimerRunning();
      debugPrint('[SafeWalkController] App resumed — timer restarted');
    }
    if (state == AppLifecycleState.paused && isActive) {
      _timer?.cancel();
      debugPrint('[SafeWalkController] App paused — timer paused');
    }
  }

  // ════════════════════════════════════════════════════════════
  //  INPUT HANDLERS — unchanged
  // ════════════════════════════════════════════════════════════

  void setDestination(String value) {
    _destination = value;
    _clearError();
  }

  void toggleGuardian(String contactId) {
    if (_selectedContactIds.contains(contactId)) {
      _selectedContactIds.remove(contactId);
    } else {
      _selectedContactIds.add(contactId);
    }
    _clearError();
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  //  VALIDATION — unchanged
  // ════════════════════════════════════════════════════════════

  WalkValidation validate() {
    if (_destination.trim().isEmpty) {
      return const WalkValidation.fail('Please enter your destination first');
    }
    if (_selectedContactIds.isEmpty) {
      return const WalkValidation.fail('Please select at least one guardian');
    }
    final validIds = _guardianSvc.guardians.map((g) => g.id).toSet();
    final invalidSelected = _selectedContactIds
        .where((id) => !validIds.contains(id))
        .toList();
    if (invalidSelected.isNotEmpty) {
      return const WalkValidation.fail(
          'One or more selected guardians are invalid');
    }
    return const WalkValidation.ok();
  }

  bool get hasNoSafeMapGuardians =>
      _selectedContactIds.isNotEmpty && _selectedProfileIds.isEmpty;

  // ════════════════════════════════════════════════════════════
  //  START WALK — unchanged
  // ════════════════════════════════════════════════════════════

  Future<String?> startWalk() async {
    final validation = validate();
    if (!validation.isValid) {
      _setError(validation.error!);
      return validation.error;
    }

    final hasPermission = await _walkSvc.requestLocationPermission();
    if (!hasPermission) {
      const msg = 'Location permission denied. Please enable it in Settings.';
      _setError(msg);
      return msg;
    }

    _setState(WalkState.starting);

    try {
      await _walkSvc.startWalk(
        destination:     _destination.trim(),
        guardianUserIds: _selectedProfileIds,
      );
      _setState(WalkState.active);
      _ensureTimerRunning();
      _clearError();
      return null;
    } catch (e) {
      _setState(WalkState.idle);
      final msg = e.toString().replaceAll('Exception: ', '');
      _setError(msg);
      return msg;
    }
  }

  // ════════════════════════════════════════════════════════════
  //  END WALK — unchanged
  // ════════════════════════════════════════════════════════════

  Future<String?> endWalk() async {
    if (!isActive && !isEmergency) return null;

    _setState(WalkState.ending);

    try {
      await _walkSvc.endWalk();
      _timer?.cancel();
      _timer              = null;
      _elapsed            = Duration.zero;
      _destination        = '';
      _selectedContactIds = [];
      _setState(WalkState.idle);
      _clearError();
      return null;
    } catch (e) {
      _setState(WalkState.active);
      final msg = e.toString().replaceAll('Exception: ', '');
      _setError(msg);
      return msg;
    }
  }

  // ════════════════════════════════════════════════════════════
  //  EMERGENCY ALERT — unchanged
  // ════════════════════════════════════════════════════════════

  Future<String?> sendEmergencyAlert() async {
    if (!isActive && !isEmergency) return null;

    try {
      await _walkSvc.sendEmergencyAlert();
      _setState(WalkState.emergency);
      _clearError();
      return null;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _setError(msg);
      return msg;
    }
  }

  // ════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS — unchanged
  // ════════════════════════════════════════════════════════════

  void _setState(WalkState s) {
    _state = s;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void _ensureTimerRunning() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        _elapsed += const Duration(seconds: 1);
        notifyListeners();
      },
    );
  }

  // Unused WidgetsBindingObserver overrides
  @override void didChangeAccessibilityFeatures()                    {}
  @override void didChangeLocales(List<Locale>? l)                   {}
  @override void didChangeMetrics()                                  {}
  @override void didChangePlatformBrightness()                       {}
  @override void didChangeTextScaleFactor()                          {}
  @override void didHaveMemoryPressure()                             {}
  @override Future<bool> didPopRoute()                               async => false;
  @override Future<bool> didPushRoute(String r)                      async => false;
  @override Future<bool> didPushRouteInformation(RouteInformation i) async => false;
  @override void didChangeViewFocus(ViewFocusEvent e)                {}
}