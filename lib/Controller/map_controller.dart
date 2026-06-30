// lib/Controller/map_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/report_model.dart';
import '../Models/map_model.dart';
import '../services/report_service.dart';
import '../services/safety_score_service.dart';
import '../services/map_cluster_service.dart';
import '../services/safe_walk_service.dart'; // ✅ NEW
import '../services/panic_service.dart';

class MapController extends ChangeNotifier {
  // ── Dependencies ───────────────────────────────────────────────────────────
  final _reportService = ReportService();
  final _supabase      = Supabase.instance.client;

  // ── Location State ─────────────────────────────────────────────────────────
  LatLng currentLatLng  = const LatLng(30.1575, 71.5249); // Multan fallback
  String currentAddress = 'Locating…';
  bool   isLocating     = false;

  // ── Report / Map State ─────────────────────────────────────────────────────
  List<ReportModel>   _allReports = [];
  List<ReportCluster> clusters    = [];
  List<SafetyZone>    zones       = [];
  ReportCluster?      selectedCluster;

  // ── Pagination State ───────────────────────────────────────────────────────
  int  _currentPage = 0;
  bool hasMorePages = true;
  bool isLoadingMore = false;

  static const int _pageSize = 50;

  // ── Safety Score ───────────────────────────────────────────────────────────
  int    safetyScore = 100;
  Color  scoreColor  = Colors.green;
  String scoreLabel  = 'Safe';

  // ── Filters ────────────────────────────────────────────────────────────────
  MapFilter filter = const MapFilter();

  // ── Loading / Error ────────────────────────────────────────────────────────
  bool    isLoading    = false;
  String? errorMessage;

  // ── Realtime ───────────────────────────────────────────────────────────────
  RealtimeChannel? _realtimeChannel;

  // Debounce timer — prevents multiple rapid realtime signals from triggering
  // multiple simultaneous re-fetches (e.g. if 5 reports are inserted quickly)
  Timer? _realtimeDebounce;

  // ── Search ─────────────────────────────────────────────────────────────────
  bool isSearching = false;

  // ════════════════════════════════════════════════════════════════════════
  // ✅ NEW — GUARDIAN: Safe Walk Live Tracking
  // ════════════════════════════════════════════════════════════════════════
  //
  // When this user is a guardian for someone currently on a Safe Walk,
  // these fields hold the walker's live position so MapScreen can render
  // a marker + tracking banner.

  SafeWalk? trackedWalk;
  String?   trackedWalkerName;
  LatLng?   walkerLatLng;
  DateTime? walkerLastUpdate;
  bool      isWalkEmergency = false;
  bool      showWalkAlert = false;
  bool      hasPromptedLocation = false;
  bool      showLocationPrompt = false;
  bool      isMockLocation = false;

  StreamSubscription<Map<String, dynamic>>? _walkEventSub;
  StreamSubscription<List<SafeWalk>>?      _assignedWalksSub;

  // ── Panic Mode State ──
  bool isPanicActive = false;
  String? activePanicAlertId;
  List<PanicAlert> activeSOSAlerts = [];
  StreamSubscription<List<PanicAlert>>? _panicAlertsSub;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    // Flag the UI to show the location choice prompt on first load
    if (!hasPromptedLocation) {
      showLocationPrompt = true;
      hasPromptedLocation = true;
    }

    if (!isMockLocation) {
      await _acquireLocation();
    }
    await loadArea(currentLatLng);
    _subscribeRealtime();
    await refreshTrackedWalk(); // ✅ NEW — check for active assigned walk
    _subscribeToAssignedWalks();
    _subscribeToPanicAlerts();
  }

  // ── Location ───────────────────────────────────────────────────────────────

  Future<void> _acquireLocation() async {
    isLocating = true;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        currentAddress = 'Location services disabled';
        isLocating = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        currentAddress = 'Location permission denied';
        isLocating = false;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy:  LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      currentLatLng  = LatLng(position.latitude, position.longitude);
      currentAddress = await _reverseGeocode(currentLatLng);
      await _updateLastLocationInProfile(currentLatLng);
    } catch (_) {
      currentAddress = 'Location unavailable';
    }

    isLocating = false;
    notifyListeners();
  }

  Future<String> _reverseGeocode(LatLng latLng) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isEmpty) return 'Unknown location';
      final p = placemarks.first;
      final parts = [
        if (p.subLocality?.isNotEmpty == true) p.subLocality,
        if (p.locality?.isNotEmpty    == true) p.locality,
      ];
      return parts.join(', ');
    } catch (_) {
      return 'Unknown location';
    }
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  Future<void> searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    isSearching  = true;
    errorMessage = null;
    notifyListeners();

    try {
      final locations = await locationFromAddress(query);
      if (locations.isEmpty) {
        errorMessage = 'Location "$query" not found.';
        isSearching  = false;
        notifyListeners();
        return;
      }

      final loc      = locations.first;
      currentLatLng  = LatLng(loc.latitude, loc.longitude);
      currentAddress = await _reverseGeocode(currentLatLng);

      await loadArea(currentLatLng);
    } catch (_) {
      errorMessage = 'Search failed. Please check your connection.';
    }

    isSearching = false;
    notifyListeners();
  }

  // ── Load Area (page 0) ─────────────────────────────────────────────────────

  Future<void> loadArea(LatLng center, {double radiusKm = 5.0}) async {
    isLoading    = true;
    errorMessage = null;
    notifyListeners();

    // Clear stale state before fetching new area
    _allReports     = [];
    clusters        = [];
    zones           = [];
    _currentPage    = 0;
    hasMorePages    = true;
    selectedCluster = null;

    try {
      final page0 = await _reportService.getNearbyReports(
        latitude:  center.latitude,
        longitude: center.longitude,
        radiusKm:  radiusKm,
        page:      0,
        pageSize:  _pageSize,
      );

      _allReports  = page0;
      hasMorePages = page0.length == _pageSize;
      _recompute();
    } catch (e) {
      errorMessage = 'Failed to load map data. Pull down to retry.';
    }

    isLoading = false;
    notifyListeners();
  }

  // ── Load Next Page (Pagination) ────────────────────────────────────────────

  Future<void> loadNextPage({double radiusKm = 5.0}) async {
    if (!hasMorePages || isLoadingMore) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final nextPage = await _reportService.getNearbyReports(
        latitude:  currentLatLng.latitude,
        longitude: currentLatLng.longitude,
        radiusKm:  radiusKm,
        page:      _currentPage,
        pageSize:  _pageSize,
      );

      if (nextPage.isEmpty) {
        hasMorePages = false;
      } else {
        _allReports  = [..._allReports, ...nextPage];
        hasMorePages = nextPage.length == _pageSize;
        _recompute();
      }
    } catch (_) {
      _currentPage--;
    }

    isLoadingMore = false;
    notifyListeners();
  }

  // ── Recompute ──────────────────────────────────────────────────────────────

  void _recompute() {
    final result = MapClusterService.process(
      reports: _allReports,
      filter:  filter,
    );
    clusters = result.clusters;
    zones    = result.zones;

    final cutoff   = DateTime.now().subtract(filter.maxAge);
    final filtered = _allReports.where((r) =>
    filter.severities.contains(r.severity) &&
        (r.incidentTime == null ||
            r.incidentTime!.isAfter(cutoff))).toList();

    safetyScore = SafetyScoreService.calculate(filtered);
    scoreColor  = SafetyScoreService.scoreColor(safetyScore);
    scoreLabel  = SafetyScoreService.scoreLabel(safetyScore);
  }

  // ── Filters ────────────────────────────────────────────────────────────────

  void toggleSeverity(String severity) {
    final updated = Set<String>.from(filter.severities);
    if (updated.contains(severity)) {
      if (updated.length == 1) return;
      updated.remove(severity);
    } else {
      updated.add(severity);
    }
    filter = filter.copyWith(severities: updated);
    _recompute();
    notifyListeners();
  }

  void setMaxAge(Duration age) {
    filter = filter.copyWith(maxAge: age);
    _recompute();
    notifyListeners();
  }

  void resetFilters() {
    filter = const MapFilter();
    _recompute();
    notifyListeners();
  }

  // ── Selection ──────────────────────────────────────────────────────────────

  void selectCluster(ReportCluster cluster) {
    selectedCluster = cluster;
    notifyListeners();
  }

  void clearSelection() {
    selectedCluster = null;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════
  // ✅ NEW — GUARDIAN: Safe Walk Live Tracking methods
  // ════════════════════════════════════════════════════════════════════════

  /// Checks Supabase for any active Safe Walk where this user is a guardian.
  /// If found, subscribes to that walk's live location/event stream.
  ///
  /// Safe to call multiple times — if already tracking the same walk,
  /// it does nothing.
  Future<void> refreshTrackedWalk() async {
    try {
      final walks = await SafeWalkService.instance.fetchMyAssignedWalks();

      if (walks.isEmpty) {
        if (trackedWalk != null) {
          _clearTrackedWalk();
          notifyListeners();
        }
        return;
      }

      await _updateTrackedWalk(walks.first);
    } catch (e) {
      debugPrint('[MapController] refreshTrackedWalk error: $e');
    }
  }

  Future<void> _updateTrackedWalk(SafeWalk walk) async {
    if (trackedWalk?.id == walk.id) return;

    final isFirstTime = trackedWalk == null;

    trackedWalk      = walk;
    walkerLatLng     = (walk.currentLat != null && walk.currentLng != null)
        ? LatLng(walk.currentLat!, walk.currentLng!)
        : null;
    walkerLastUpdate = walk.lastUpdated;
    isWalkEmergency  = walk.isEmergency;

    trackedWalkerName = await _fetchWalkerName(walk.userId);

    _subscribeToWalkEvents(walk.id);

    if (isFirstTime) {
      showWalkAlert = true;
    }
    notifyListeners();
  }

  void _subscribeToAssignedWalks() {
    _assignedWalksSub?.cancel();
    _assignedWalksSub = SafeWalkService.instance
        .guardianActiveWalksStream()
        .listen((walks) async {
      if (walks.isEmpty) {
        if (trackedWalk != null) {
          _clearTrackedWalk();
          notifyListeners();
        }
        return;
      }

      await _updateTrackedWalk(walks.first);
    });
  }

  void dismissWalkAlert() {
    showWalkAlert = false;
    notifyListeners();
  }

  void setSimulatedLocation(double lat, double lng, String address) {
    isMockLocation = true;
    currentLatLng = LatLng(lat, lng);
    currentAddress = address;

    // Set mock coordinates in SafeWalkService too
    SafeWalkService.instance.isMockLocation = true;
    SafeWalkService.instance.mockLat = lat;
    SafeWalkService.instance.mockLng = lng;

    _updateLastLocationInProfile(currentLatLng);
    loadArea(currentLatLng);
    notifyListeners();
  }

  void setLiveLocation() async {
    isMockLocation = false;
    SafeWalkService.instance.isMockLocation = false;
    await _acquireLocation();
    loadArea(currentLatLng);
  }

  Future<String> _fetchWalkerName(String userId) async {
    try {
      final row = await _supabase
          .from('profiles')
          .select('name')
          .eq('id', userId)
          .single();
      return row['name'] as String? ?? 'Someone';
    } catch (_) {
      return 'Someone';
    }
  }

  void _subscribeToWalkEvents(String walkId) {
    _walkEventSub?.cancel();
    _walkEventSub = SafeWalkService.instance
        .guardianWalkEventStream(walkId)
        .listen((event) {
      switch (event['type']) {
        case 'location':
          final lat = (event['lat'] as num?)?.toDouble();
          final lng = (event['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            walkerLatLng = LatLng(lat, lng);
          }
          walkerLastUpdate =
              DateTime.tryParse(event['timestamp'] as String? ?? '');
          notifyListeners();
          break;

        case 'emergency':
          isWalkEmergency = true;
          final lat = (event['lat'] as num?)?.toDouble();
          final lng = (event['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            walkerLatLng = LatLng(lat, lng);
          }
          notifyListeners();
          break;

        case 'walk_ended':
          _clearTrackedWalk();
          notifyListeners();
          break;
      }
    });
  }

  void _clearTrackedWalk() {
    _walkEventSub?.cancel();
    _walkEventSub     = null;
    trackedWalk       = null;
    trackedWalkerName = null;
    walkerLatLng      = null;
    walkerLastUpdate  = null;
    isWalkEmergency   = false;
  }

  /// Called when guardian manually dismisses the tracking banner.
  void stopTrackingWalk() {
    _clearTrackedWalk();
    notifyListeners();
  }

  // ── Realtime ───────────────────────────────────────────────────────────────
  //
  // FIX (Reviewer Point 1 — Realtime Subscription):
  //
  // Problem: Supabase Realtime only broadcasts on TABLES, not views.
  // The raw realtime payload for a new report contains only the table columns
  // (no category_name, no category_color) because those come from a JOIN in
  // the view. Trying to build a ReportModel from the raw payload produces
  // markers with null category info.
  //
  // Solution: Subscribe to the 'reports' TABLE (correct), but when a signal
  // arrives, use it purely as a trigger to re-fetch page 0 from
  // reports_map_view via the RPC. This gives us the full joined data.
  //
  // A 500ms debounce timer prevents multiple rapid inserts from firing
  // multiple simultaneous re-fetches.

  void _subscribeRealtime() {
    _realtimeChannel = _supabase
        .channel('map_reports_realtime')
        .onPostgresChanges(
      event:    PostgresChangeEvent.insert,
      schema:   'public',
      table:    'reports',  // ← table, not view — Realtime only works on tables
      callback: _onRealtimeSignal,
    )
        .subscribe();
  }

  /// Called when a new row is inserted into the reports table.
  /// We do NOT parse the raw payload — it lacks joined category data.
  /// Instead we debounce and re-fetch from the view so markers are complete.
  void _onRealtimeSignal(PostgresChangePayload payload) {
    // Quick proximity check using the raw lat/lng from the payload
    // so we only refresh if the new report is actually near the user
    try {
      final rawLat = payload.newRecord['latitude'];
      final rawLng = payload.newRecord['longitude'];

      if (rawLat == null || rawLng == null) return;

      final dist = const Distance().as(
        LengthUnit.Kilometer,
        currentLatLng,
        LatLng((rawLat as num).toDouble(), (rawLng as num).toDouble()),
      );

      if (dist > 5.0) return; // outside current view — ignore
    } catch (_) {
      return; // malformed payload — ignore
    }

    // Debounce: cancel any pending refresh and schedule a new one 500ms out.
    // If 10 reports arrive in rapid succession, we only fetch once.
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        // Re-fetch page 0 from the RPC (returns joined category data)
        final fresh = await _reportService.getNearbyReports(
          latitude:  currentLatLng.latitude,
          longitude: currentLatLng.longitude,
          page:      0,
          pageSize:  _pageSize,
        );

        // Replace only page 0 — keep any additional pages the user already loaded
        if (_allReports.length <= _pageSize) {
          _allReports = fresh;
        } else {
          _allReports = [...fresh, ..._allReports.skip(_pageSize)];
        }

        _recompute();
        notifyListeners();
      } catch (_) {
        // Silent — realtime refresh failure is non-critical
      }
    });
  }

  // ── Panic Mode Actions & Subscriptions ─────────────────────────────────────

  void _subscribeToPanicAlerts() {
    _panicAlertsSub?.cancel();
    _panicAlertsSub = PanicService.instance
        .activePanicAlertsStream()
        .listen((alerts) {
      final myUid = _supabase.auth.currentUser?.id;
      activeSOSAlerts = alerts
          .where((alert) => alert.userId != myUid)
          .toList();
      notifyListeners();
    });
  }

  Future<void> _updateLastLocationInProfile(LatLng latLng) async {
    try {
      final myUid = _supabase.auth.currentUser?.id;
      if (myUid == null) return;
      await _supabase.from('profiles').update({
        'last_lat': latLng.latitude,
        'last_lng': latLng.longitude,
        'last_located_at': DateTime.now().toIso8601String(),
      }).eq('id', myUid);
      debugPrint('[MapController] Profile location updated in Supabase: $latLng');
    } catch (e) {
      debugPrint('[MapController] Error updating profile location: $e');
    }
  }

  Future<void> triggerPanicMode() async {
    try {
      isPanicActive = true;
      notifyListeners();

      final alert = await PanicService.instance.triggerPanicMode(
        currentLatLng.latitude,
        currentLatLng.longitude,
      );
      activePanicAlertId = alert.id;
      debugPrint('[MapController] Panic mode triggered: ${alert.id}');
    } catch (e) {
      isPanicActive = false;
      debugPrint('[MapController] triggerPanicMode error: $e');
      errorMessage = 'Failed to activate Panic Mode: $e';
    }
    notifyListeners();
  }

  Future<void> resolvePanicMode() async {
    if (activePanicAlertId == null) {
      isPanicActive = false;
      notifyListeners();
      return;
    }

    try {
      await PanicService.instance.resolvePanicMode(activePanicAlertId!);
      activePanicAlertId = null;
      isPanicActive = false;
      debugPrint('[MapController] Panic mode resolved');
    } catch (e) {
      debugPrint('[MapController] resolvePanicMode error: $e');
      errorMessage = 'Failed to resolve Panic Mode: $e';
    }
    notifyListeners();
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _realtimeDebounce?.cancel();
    _realtimeChannel?.unsubscribe();
    _walkEventSub?.cancel();
    _assignedWalksSub?.cancel();
    _panicAlertsSub?.cancel();
    super.dispose();
  }
}