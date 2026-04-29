import '../Models/guardian_model.dart';

class GuardianService {
  static final GuardianService _instance = GuardianService._internal();
  factory GuardianService() => _instance;
  GuardianService._internal();

  final List<Guardian> _guardians = [];

  List<Guardian> get guardians => List.unmodifiable(_guardians);

  void initializeGuardians() {
    if (_guardians.isEmpty) {
      _guardians.addAll(mockGuardians);
    }
  }

  void addGuardian(Guardian guardian) {
    _guardians.add(guardian);
  }

  void updateGuardian(String id, Guardian updatedGuardian) {
    final index = _guardians.indexWhere((g) => g.id == id);
    if (index != -1) {
      _guardians[index] = updatedGuardian;
    }
  }

  void removeGuardian(String id) {
    _guardians.removeWhere((g) => g.id == id);
  }

  Guardian? getGuardianById(String id) {
    try {
      return _guardians.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }
}
