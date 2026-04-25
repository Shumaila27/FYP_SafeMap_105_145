import 'dart:ui';

class Incident {
  final String id;
  final String type; // harassment, theft, crime
  final Offset location; // x,y in %
  final String severity; // high, medium, low
  final String time;
  final String description;

  Incident({
    required this.id,
    required this.type,
    required this.location,
    required this.severity,
    required this.time,
    required this.description,
  });
}

// Mock incidents
final List<Incident> mockIncidents = [
  Incident(
      id: '1',
      type: 'harassment',
      location: const Offset(35, 40),
      severity: 'high',
      time: '2 hours ago',
      description: 'Street harassment reported'),
  Incident(
      id: '2',
      type: 'theft',
      location: const Offset(60, 55),
      severity: 'medium',
      time: '5 hours ago',
      description: 'Phone snatching incident'),
  Incident(
      id: '3',
      type: 'crime',
      location: const Offset(45, 70),
      severity: 'high',
      time: '1 hour ago',
      description: 'Suspicious activity'),
  Incident(
      id: '4',
      type: 'harassment',
      location: const Offset(70, 35),
      severity: 'low',
      time: '8 hours ago',
      description: 'Catcalling reported'),
  Incident(
      id: '5',
      type: 'theft',
      location: const Offset(25, 60),
      severity: 'medium',
      time: '3 hours ago',
      description: 'Bag snatching attempt'),
];