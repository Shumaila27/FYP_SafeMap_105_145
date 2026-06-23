// lib/Models/guardian_model.dart

class Guardian {
  final String id;
  final String name;
  final String phone;
  final String relation;
  // ✅ NEW — links to the guardian's SafeMap profile for live tracking
  // null = guardian not on SafeMap yet
  final String? guardianProfileId;

  const Guardian({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
    this.guardianProfileId,
  });

  factory Guardian.fromMap(Map<String, dynamic> m) => Guardian(
    id:                m['id']?.toString()              ?? '',
    name:              m['name']      as String?        ?? '',
    phone:             m['phone']     as String?        ?? '',
    relation:          m['relation']  as String?        ?? '',
    guardianProfileId: m['guardian_profile_id'] as String?,
  );

  Map<String, dynamic> toMap({required String userId}) => {
    'user_id':              userId,
    'name':                 name.trim(),
    'phone':                phone.trim(),
    'relation':             relation.trim(),
    'guardian_profile_id':  guardianProfileId,
  };

  // ✅ true = this guardian has SafeMap — live tracking possible
  bool get isOnSafeMap => guardianProfileId != null;

  String get initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Guardian copyWith({
    String? id,
    String? name,
    String? phone,
    String? relation,
    String? guardianProfileId,
  }) =>
      Guardian(
        id:                id                ?? this.id,
        name:              name              ?? this.name,
        phone:             phone             ?? this.phone,
        relation:          relation          ?? this.relation,
        guardianProfileId: guardianProfileId ?? this.guardianProfileId,
      );

  @override
  String toString() =>
      'Guardian(id: $id, name: $name, phone: $phone, '
          'relation: $relation, onSafeMap: $isOnSafeMap)';
}