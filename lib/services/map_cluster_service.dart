// lib/services/map_cluster_service.dart
import 'package:latlong2/latlong.dart';
import '../Models/report_model.dart';
import '../Models/map_model.dart';
import 'package:flutter/material.dart';


/// Converts a flat list of reports into spatial clusters using a grid approach.
///
/// How it works:
/// 1. Divide the map into a grid of [gridSizeKm] × [gridSizeKm] cells.
/// 2. Assign each report to the cell that contains its coordinates.
/// 3. Each non-empty cell becomes one [ReportCluster].
///
/// This is O(n) — fast enough for thousands of reports on a mobile device.
class MapClusterService {
  MapClusterService._();

  /// Default grid cell size in degrees.
  /// ~0.005° ≈ 550 m — keeps nearby incidents grouped without over-merging.
  static const double _defaultCellDeg = 0.005;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns clusters + safety zones from [reports].
  /// Pass [filter] to pre-filter before clustering.
  static ({
  List<ReportCluster> clusters,
  List<SafetyZone> zones,
  }) process({
    required List<ReportModel> reports,
    required MapFilter filter,
    double cellDeg = _defaultCellDeg,
  }) {
    final filtered = _applyFilter(reports, filter);
    final clusters = _cluster(filtered, cellDeg);
    final zones    = _buildZones(clusters);
    return (clusters: clusters, zones: zones);
  }

  // ── Private: Filter ────────────────────────────────────────────────────────

  static List<ReportModel> _applyFilter(
      List<ReportModel> reports,
      MapFilter filter,
      ) {
    final cutoff = DateTime.now().subtract(filter.maxAge);
    return reports.where((r) {
      final inSeverity = filter.severities.contains(r.severity);
      // category matching: categoryId in DB is a UUID, but we compare by name.
      // The cluster service doesn't do the name→UUID lookup; the controller
      // stores the category name on the model via a join or a separate lookup.
      // For now we skip category filtering if categoryId is a UUID.
      final withinAge =
          r.incidentTime == null || r.incidentTime!.isAfter(cutoff);
      return inSeverity && withinAge;
    }).toList();
  }

  // ── Private: Clustering ────────────────────────────────────────────────────

  static List<ReportCluster> _cluster(
      List<ReportModel> reports,
      double cellDeg,
      ) {
    // Map from grid-key → list of reports in that cell
    final Map<String, List<ReportModel>> grid = {};

    for (final report in reports) {
      if (report.latitude == null || report.longitude == null) continue;
      final cellLat = (report.latitude! / cellDeg).floor();
      final cellLng = (report.longitude! / cellDeg).floor();
      final key = '$cellLat:$cellLng';
      grid.putIfAbsent(key, () => []).add(report);
    }

    return grid.values.map((cellReports) {
      final avgLat = cellReports
          .map((r) => r.latitude!)
          .reduce((a, b) => a + b) /
          cellReports.length;
      final avgLng = cellReports
          .map((r) => r.longitude!)
          .reduce((a, b) => a + b) /
          cellReports.length;

      return ReportCluster(
        center: LatLng(avgLat, avgLng),
        reports: cellReports,
        dominantSeverity: _dominant(cellReports),
        count: cellReports.length,
      );
    }).toList();
  }

  /// Returns the most severe level present in [reports].
  static String _dominant(List<ReportModel> reports) {
    if (reports.any((r) => r.severity == 'high'))   return 'high';
    if (reports.any((r) => r.severity == 'medium')) return 'medium';
    return 'low';
  }

  // ── Private: Safety Zones ──────────────────────────────────────────────────
  // Broader coloured circles shown under the pin clusters.

  static List<SafetyZone> _buildZones(List<ReportCluster> clusters) {
    return clusters.map((c) {
      late String label;
      late _ZoneStyle style;

      switch (c.dominantSeverity) {
        case 'high':
          label = 'High Risk Area';
          style = _ZoneStyle.danger;
          break;
        case 'medium':
          label = 'Moderate Area';
          style = _ZoneStyle.moderate;
          break;
        default:
          label = 'Low Risk Area';
          style = _ZoneStyle.safe;
      }

      return SafetyZone(
        center: c.center,
        radiusMeters: c.radiusMeters * 2.5, // zone is larger than the cluster
        color: style.color,
        label: label,
      );
    }).toList();
  }
}

enum _ZoneStyle {
  danger(color: Color(0x29F44336)),    // red  @ 16% opacity
  moderate(color: Color(0x29FF9800)),  // orange @ 16%
  safe(color: Color(0x2966BB6A));      // green @ 16%

  const _ZoneStyle({required this.color});
  final Color color;
}