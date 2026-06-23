// lib/services/guardian_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Models/guardian_model.dart';

class GuardianService extends ChangeNotifier {   // ← CHANGED: extends ChangeNotifier
  // ── Singleton ──────────────────────────────────────────────
  static final GuardianService _instance = GuardianService._internal();
  factory GuardianService() => _instance;
  GuardianService._internal();

  // ── State ──────────────────────────────────────────────────
  final List<Guardian> _guardians = [];
  bool _initialized = false;

  SupabaseClient get _db => Supabase.instance.client;

  List<Guardian> get guardians => List.unmodifiable(_guardians);

  // ════════════════════════════════════════════════════════════
  //  INITIALIZE
  // ════════════════════════════════════════════════════════════
  Future<void> initializeGuardians() async {
    if (_initialized) return;
    if (_db.auth.currentUser == null) return;

    try {
      final rows = await _db
          .from('emergency_contacts')
          .select('*')
          .order('created_at');

      _guardians
        ..clear()
        ..addAll(rows.map((r) => Guardian.fromMap(r)));

      _initialized = true;
      notifyListeners();                          // ← ADDED
    } catch (e) {
      debugPrint('[GuardianService] initializeGuardians error: $e');
    }
  }

  /// Force a fresh reload from Supabase.
  Future<void> reload() async {
    _initialized = false;
    await initializeGuardians();
    // notifyListeners() is already called inside initializeGuardians()
  }

  // ════════════════════════════════════════════════════════════
  //  CACHE-ONLY SYNC METHODS  ← NEW
  //  Called by ProfileScreen after its own DB operations succeed.
  //  No extra DB round-trip — just keeps the in-memory list in sync.
  // ════════════════════════════════════════════════════════════

  /// Call after ProfileService.addContact() succeeds.
  void addToCache(Guardian g) {
    _guardians.add(g);
    notifyListeners();                            // ← SafeWalkScreen rebuilds instantly
  }

  /// Call after ProfileService.updateContact() succeeds.
  void updateInCache(Guardian updated) {
    final idx = _guardians.indexWhere((g) => g.id == updated.id);
    if (idx != -1) {
      _guardians[idx] = updated;
      notifyListeners();
    }
  }

  /// Call after ProfileService.deleteContact() succeeds.
  void removeFromCache(String id) {
    _guardians.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════
  //  ADD  (used when GuardianService is the source of truth)
  // ════════════════════════════════════════════════════════════
  Future<void> addGuardian(Guardian guardian) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final row = await _db
          .from('emergency_contacts')
          .insert({
        'user_id':  uid,
        'name':     guardian.name.trim(),
        'phone':    guardian.phone.trim(),
        'relation': guardian.relation.trim(),
      })
          .select()
          .single();

      _guardians.add(Guardian.fromMap(row));
      notifyListeners();                          // ← ADDED
    } on PostgrestException catch (e) {
      if (e.code == '23514') {
        throw Exception(
          'Invalid phone number. Use format: +923001234567 or 03001234567 (10–15 digits).',
        );
      }
      debugPrint('[GuardianService] addGuardian DB error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[GuardianService] addGuardian error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  //  UPDATE
  // ════════════════════════════════════════════════════════════
  Future<void> updateGuardian(String id, Guardian updatedGuardian) async {
    try {
      await _db
          .from('emergency_contacts')
          .update({
        'name':     updatedGuardian.name.trim(),
        'phone':    updatedGuardian.phone.trim(),
        'relation': updatedGuardian.relation.trim(),
      })
          .eq('id', id);

      final index = _guardians.indexWhere((g) => g.id == id);
      if (index != -1) {
        _guardians[index] = updatedGuardian.copyWith(id: id);
      }
      notifyListeners();                          // ← ADDED
    } on PostgrestException catch (e) {
      if (e.code == '23514') {
        throw Exception(
          'Invalid phone number. Use format: +923001234567 or 03001234567 (10–15 digits).',
        );
      }
      debugPrint('[GuardianService] updateGuardian DB error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[GuardianService] updateGuardian error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  //  REMOVE
  // ════════════════════════════════════════════════════════════
  Future<void> removeGuardian(String id) async {
    try {
      await _db
          .from('emergency_contacts')
          .delete()
          .eq('id', id);

      _guardians.removeWhere((g) => g.id == id);
      notifyListeners();                          // ← ADDED
    } catch (e) {
      debugPrint('[GuardianService] removeGuardian error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════════
  //  GET BY ID
  // ════════════════════════════════════════════════════════════
  Guardian? getGuardianById(String id) {
    try {
      return _guardians.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════
  //  RESET  — call on logout
  // ════════════════════════════════════════════════════════════
  void reset() {
    _guardians.clear();
    _initialized = false;
    notifyListeners();                            // ← ADDED
  }
}