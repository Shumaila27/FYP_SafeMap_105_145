// lib/Models/map_model.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'report_model.dart';

// ── Report Cluster ─────────────────────────────────────────────────────────
// A group of nearby reports that renders as one circle + marker on the map.
// Built by MapClusterService from a flat List<ReportModel>.

class ReportCluster {
  final LatLng center;
  final List<ReportModel> reports;
  final String dominantSeverity; // the most severe level in this cluster
  final int count;

  const ReportCluster({
    required this.center,
    required this.reports,
    required this.dominantSeverity,
    required this.count,
  });

  /// Radius in metres for the heat-zone circle.
  /// Grows with report count so denser clusters look bigger.
  double get radiusMeters {
    if (count >= 10) return 300;
    if (count >= 5) return 220;
    if (count >= 3) return 160;
    return 100;
  }

  /// Colour of the heat-zone circle (semi-transparent fill).
  Color get zoneColor {
    switch (dominantSeverity) {
      case 'high':
        return Colors.red.withValues(alpha: 0.18);
      case 'medium':
        return Colors.orange.withValues(alpha: 0.18);
      default:
        return Colors.yellow.withValues(alpha: 0.18);
    }
  }

  /// Solid colour for the pin marker.
  Color get markerColor {
    switch (dominantSeverity) {
      case 'high':
        return Colors.red.shade600;
      case 'medium':
        return Colors.orange.shade500;
      default:
        return Colors.yellow.shade600;
    }
  }
}

// ── Safety Zone ────────────────────────────────────────────────────────────
// Pre-computed zone displayed under the clusters (broader area colouring).

class SafetyZone {
  final LatLng center;
  final double radiusMeters;
  final Color color;
  final String label; // "High Risk Area", "Moderate", "Safe"

  const SafetyZone({
    required this.center,
    required this.radiusMeters,
    required this.color,
    required this.label,
  });
}

// ── Map Filter State ───────────────────────────────────────────────────────
// Held in MapController; passed to MapClusterService to pre-filter reports.

class MapFilter {
  final Set<String> severities; // 'high' | 'medium' | 'low'
  final Set<String> categories; // 'harassment' | 'theft' | 'crime' | ...
  final Duration maxAge;        // only show reports within this window

  const MapFilter({
    this.severities = const {'high', 'medium', 'low'},
    this.categories = const {'harassment', 'theft', 'crime', 'stalking', 'other'},
    this.maxAge = const Duration(days: 30),
  });

  MapFilter copyWith({
    Set<String>? severities,
    Set<String>? categories,
    Duration? maxAge,
  }) {
    return MapFilter(
      severities: severities ?? this.severities,
      categories: categories ?? this.categories,
      maxAge: maxAge ?? this.maxAge,
    );
  }

  bool get isDefault =>
      severities.length == 3 &&
          categories.length == 5 &&
          maxAge == const Duration(days: 30);
}