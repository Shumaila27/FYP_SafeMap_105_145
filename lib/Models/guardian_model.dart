class Guardian {
  final String id;
  final String name;
  final String phone;
  final String relation;

  Guardian({required this.id, required this.name, required this.phone, required this.relation});
}

// Mock data
final List<Guardian> mockGuardians = [
  Guardian(id: '1', name: 'Ayesha Khan', phone: '+92 300 1234567', relation: 'Sister'),
  Guardian(id: '2', name: 'Fatima Ali', phone: '+92 333 9876543', relation: 'Friend'),
  Guardian(id: '3', name: 'Mother', phone: '+92 321 5555555', relation: 'Family'),
];