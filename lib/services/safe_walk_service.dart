// lib/services/safe_walk_service.dart
//
// ──────────────────────────────────────────────────────────────
//  SafeWalkService
//  Handles:
//  ✅ Starting / ending a safe walk session
//  ✅ Live location updates to Supabase every 5 seconds
//  ✅ Supabase Realtime Broadcast for instant guardian updates
//  ✅ Emergency alert
//  ✅ Guardian monitoring stream
//  ✅ FCM notifications to guardians (start / end / emergency)
// ──────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

// ── Models ───────────────────────────────────────────────────

class SafeWalk {
  final String id;
  final String userId;
  final String destination;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double? currentLat;
  final double? currentLng;
  final DateTime? lastUpdated;

  const SafeWalk({
    required this.id,
    required this.userId,
    required this.destination,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.currentLat,
    this.currentLng,
    this.lastUpdated,
  });

  factory SafeWalk.fromMap(Map<String, dynamic> m) => SafeWalk(
    id:          m['id'] as String,
    userId:      m['user_id'] as String,
    destination: m['destination'] as String,
    status:      m['status'] as String,
    startedAt:   DateTime.parse(m['started_at'] as String),
    endedAt:     m['ended_at'] != null
        ? DateTime.parse(m['ended_at'] as String)
        : null,
    currentLat:  (m['current_lat'] as num?)?.toDouble(),
    currentLng:  (m['current_lng'] as num?)?.toDouble(),
    lastUpdated: m['last_updated'] != null
        ? DateTime.parse(m['last_updated'] as String)
        : null,
  );

  bool get isActive   => status == 'active';
  bool get isEmergency => status == 'emergency';
}

class LiveLocation {
  final double lat;
  final double lng;
  final DateTime timestamp;

  const LiveLocation({
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  factory LiveLocation.fromMap(Map<String, dynamic> m) => LiveLocation(
    lat:       (m['lat'] as num).toDouble(),
    lng:       (m['lng'] as num).toDouble(),
    timestamp: DateTime.parse(m['timestamp'] as String),
  );
}

// ── Service ──────────────────────────────────────────────────

class SafeWalkService {
  // ── Singleton ─────────────────────────────────────────────
  SafeWalkService._();
  static final SafeWalkService instance = SafeWalkService._();

  final _client = Supabase.instance.client;

  // ── Internal state ────────────────────────────────────────
  SafeWalk?               _currentWalk;
  Timer?                  _locationTimer;
  RealtimeChannel?        _broadcastChannel;
  StreamSubscription<Position>? _positionSub;

  // ✅ NEW — remembers which guardians are watching this walk
  // so endWalk() / sendEmergencyAlert() can notify them later
  // without needing the caller to pass the list again.
  List<String> _activeGuardianIds = [];

  SafeWalk? get currentWalk => _currentWalk;
  bool      get isWalking   => _currentWalk?.isActive ?? false;

  String get _uid {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('User not authenticated');
    return uid;
  }

  // ════════════════════════════════════════════════════════════
  //  LOCATION PERMISSION
  // ════════════════════════════════════════════════════════════

  /// Call this before starting a walk.
  /// Returns true if permission granted, false otherwise.
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  // ════════════════════════════════════════════════════════════
  //  START WALK
  // ════════════════════════════════════════════════════════════

  Future<SafeWalk> startWalk({
    required String destination,
    required List<String> guardianUserIds, // profile IDs of guardians
  }) async {
    // 1. Get current location first
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    // 2. Create walk session in DB
    final row = await _client
        .from('safe_walks')
        .insert({
      'user_id':      _uid,
      'destination':  destination.trim(),
      'status':       'active',
      'current_lat':  position.latitude,
      'current_lng':  position.longitude,
      'last_updated': DateTime.now().toIso8601String(),
    })
        .select()
        .single();

    _currentWalk = SafeWalk.fromMap(row);

    // ✅ NEW — remember guardians for this walk (used by endWalk/emergency)
    _activeGuardianIds = guardianUserIds;

    // 3. Insert walk_guardians rows (who is monitoring)
    if (guardianUserIds.isNotEmpty) {
      await _client.from('walk_guardians').insert(
        guardianUserIds.map((gId) => {
          'walk_id':     _currentWalk!.id,
          'guardian_id': gId,
        }).toList(),
      );
    }

    // 4. Start Supabase Realtime Broadcast channel
    _startBroadcastChannel(_currentWalk!.id);

    // 5. Start location updates every 5 seconds
    _startLocationUpdates();

    // 6. ✅ NEW — Notify guardians that a Safe Walk has started
    final walkerName = await _getWalkerName();
    await NotificationService.instance.notifyGuardiansSafeWalkStarted(
      walkId:            _currentWalk!.id,
      walkerName:        walkerName,
      destination:       _currentWalk!.destination,
      guardianProfileIds: guardianUserIds,
    );

    return _currentWalk!;
  }

  // ════════════════════════════════════════════════════════════
  //  LOCATION UPDATES (every 5 seconds)
  // ════════════════════════════════════════════════════════════

  void _startLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _pushLocation(),
    );
  }

  Future<void> _pushLocation() async {
    if (_currentWalk == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final lat = position.latitude;
      final lng = position.longitude;
      final now = DateTime.now().toIso8601String();

      // Update current location in safe_walks table
      await _client
          .from('safe_walks')
          .update({
        'current_lat':  lat,
        'current_lng':  lng,
        'last_updated': now,
      })
          .eq('id', _currentWalk!.id);

      // Save breadcrumb to walk_locations
      await _client.from('walk_locations').insert({
        'walk_id':     _currentWalk!.id,
        'lat':         lat,
        'lng':         lng,
        'recorded_at': now,
      });

      // Broadcast live location to guardians via Realtime
      // (instant, no DB round-trip on guardian's side)
      await _broadcastChannel?.sendBroadcastMessage(
        event: 'location_update',
        payload: {
          'walk_id':   _currentWalk!.id,
          'lat':       lat,
          'lng':       lng,
          'timestamp': now,
        },
      );

      debugPrint('[SafeWalk] Location pushed: $lat, $lng');
    } catch (e) {
      debugPrint('[SafeWalk] Location push error: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  //  BROADCAST CHANNEL  (Supabase Realtime)
  // ════════════════════════════════════════════════════════════

  void _startBroadcastChannel(String walkId) {
    _broadcastChannel?.unsubscribe();
    _broadcastChannel = _client.channel('walk:$walkId');
    _broadcastChannel!.subscribe();
    debugPrint('[SafeWalk] Broadcast channel started: walk:$walkId');
  }

  /// Guardian calls this to listen to live location updates.
  /// Returns a Stream of LiveLocation objects.
  Stream<LiveLocation> guardianLocationStream(String walkId) {
    final channel = _client.channel('walk:$walkId');

    final controller = StreamController<LiveLocation>.broadcast();

    channel.onBroadcast(
      event: 'location_update',
      callback: (payload) {
        try {
          controller.add(LiveLocation.fromMap(
            Map<String, dynamic>.from(payload),
          ));
        } catch (e) {
          debugPrint('[SafeWalk] Guardian stream parse error: $e');
        }
      },
    ).subscribe();

    controller.onCancel = () {
      channel.unsubscribe();
    };

    return controller.stream;
  }

  // ════════════════════════════════════════════════════════════
  // ✅ NEW — GUARDIAN: combined walk event stream
  // ════════════════════════════════════════════════════════════
  //
  // Guardian calls this to listen to ALL walk-related events for [walkId]:
  // - location updates → {'type': 'location', 'lat':, 'lng':, 'timestamp':}
  // - walk ended       → {'type': 'walk_ended'}
  // - emergency alert  → {'type': 'emergency', 'lat':, 'lng':, 'message':}
  //
  // Used by MapController to drive the live walker marker + tracking banner.
  Stream<Map<String, dynamic>> guardianWalkEventStream(String walkId) {
    final channel = _client.channel('walk:$walkId');
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    channel
        .onBroadcast(
      event: 'location_update',
      callback: (payload) {
        controller.add({'type': 'location', ...payload});
      },
    )
        .onBroadcast(
      event: 'walk_ended',
      callback: (payload) {
        controller.add({'type': 'walk_ended', ...payload});
      },
    )
        .onBroadcast(
      event: 'emergency',
      callback: (payload) {
        controller.add({'type': 'emergency', ...payload});
      },
    )
        .subscribe();

    controller.onCancel = () => channel.unsubscribe();
    return controller.stream;
  }

  // ════════════════════════════════════════════════════════════
  //  END WALK  (arrived safely)
  // ════════════════════════════════════════════════════════════

  Future<void> endWalk() async {
    if (_currentWalk == null) return;

    // ✅ NEW — capture before _cleanup() wipes state
    final guardianIds = List<String>.from(_activeGuardianIds);
    final walkerName  = await _getWalkerName();

    try {
      await _client
          .from('safe_walks')
          .update({
        'status':   'completed',
        'ended_at': DateTime.now().toIso8601String(),
      })
          .eq('id', _currentWalk!.id);

      // Notify guardians walk ended (Realtime broadcast)
      await _broadcastChannel?.sendBroadcastMessage(
        event: 'walk_ended',
        payload: {
          'walk_id': _currentWalk!.id,
          'status':  'completed',
        },
      );

      // ✅ NEW — Push notification to guardians
      await NotificationService.instance.notifyGuardiansSafeWalkEnded(
        walkerName:         walkerName,
        guardianProfileIds: guardianIds,
      );
    } catch (e) {
      debugPrint('[SafeWalk] endWalk error: $e');
    } finally {
      _cleanup();
    }
  }

  // ════════════════════════════════════════════════════════════
  //  EMERGENCY ALERT
  // ════════════════════════════════════════════════════════════

  Future<void> sendEmergencyAlert() async {
    if (_currentWalk == null) return;

    try {
      // Update status in DB
      await _client
          .from('safe_walks')
          .update({'status': 'emergency'})
          .eq('id', _currentWalk!.id);

      // Broadcast emergency to all guardians instantly
      await _broadcastChannel?.sendBroadcastMessage(
        event: 'emergency',
        payload: {
          'walk_id':  _currentWalk!.id,
          'lat':      _currentWalk!.currentLat,
          'lng':      _currentWalk!.currentLng,
          'message':  'EMERGENCY: Walker needs immediate help!',
          'sent_at':  DateTime.now().toIso8601String(),
        },
      );

      // ✅ NEW — Push notification to guardians
      final walkerName = await _getWalkerName();
      await NotificationService.instance.notifyGuardiansEmergency(
        walkerName:         walkerName,
        lat:                _currentWalk!.currentLat ?? 0.0,
        lng:                _currentWalk!.currentLng ?? 0.0,
        guardianProfileIds: _activeGuardianIds,
      );

      debugPrint('[SafeWalk] Emergency alert sent');
    } catch (e) {
      debugPrint('[SafeWalk] Emergency alert error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  //  GUARDIAN — fetch active walks assigned to me
  // ════════════════════════════════════════════════════════════

  Future<List<SafeWalk>> fetchMyAssignedWalks() async {
    try {
      final rows = await _client
          .from('safe_walks')
          .select('*, walk_guardians!inner(guardian_id)')
          .eq('walk_guardians.guardian_id', _uid)
          .eq('status', 'active')
          .order('started_at', ascending: false);

      return rows.map((r) => SafeWalk.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[SafeWalk] fetchMyAssignedWalks error: $e');
      return [];
    }
  }

  /// Stream that fires whenever a new walk is assigned to this guardian.
  Stream<List<SafeWalk>> guardianActiveWalksStream() {
    return _client
        .from('safe_walks')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .map((rows) => rows.map((r) => SafeWalk.fromMap(r)).toList());
  }

  // ════════════════════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════════════════════

  /// Fetches the current user's display name for notification text.
  Future<String> _getWalkerName() async {
    try {
      final row = await _client
          .from('profiles')
          .select('name')
          .eq('id', _uid)
          .single();
      return row['name'] as String? ?? 'Someone';
    } catch (_) {
      return 'Someone';
    }
  }

  // ════════════════════════════════════════════════════════════
  //  CLEANUP
  // ════════════════════════════════════════════════════════════

  void _cleanup() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _broadcastChannel?.unsubscribe();
    _broadcastChannel = null;
    _positionSub?.cancel();
    _positionSub = null;
    _currentWalk = null;
    _activeGuardianIds = []; // ✅ NEW — reset guardian list
    debugPrint('[SafeWalk] Cleaned up');
  }

  /// Call on logout
  void reset() => _cleanup();
}