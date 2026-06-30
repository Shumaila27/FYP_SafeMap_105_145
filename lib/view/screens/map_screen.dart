// lib/view/screens/map/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import '../../../Controller/map_controller.dart';
import '../../../Models/map_model.dart';
import '../../../Models/report_model.dart';
import '../../../services/panic_service.dart';
import '../../../utils/app_colors.dart';
import '../widgets/app_bar.dart';
import '../widgets/pani_button.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // FIX: explicitly typed as fm.MapController (flutter_map's controller)
  // so .move() resolves correctly and FlutterMap accepts it.
  final fm.MapController _flutterMapController = fm.MapController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapController>().init();
    });
  }

  @override
  void dispose() {
    _flutterMapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapController>(
      builder: (context, controller, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Pan the map whenever the controller's location changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // FIX: now calls fm.MapController.move() — method exists
          _flutterMapController.move(controller.currentLatLng, 14);
        });

        // Check if there is an incoming walk alert to show a dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.showWalkAlert) {
            final walkerName = controller.trackedWalkerName ?? 'Someone';
            final destination = controller.trackedWalk?.destination ?? 'Destination';
            
            controller.dismissWalkAlert();
            _showIncomingWalkDialog(context, walkerName, destination);
          }
        });

        // Check if we should prompt the user to set/simulate their location
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.showLocationPrompt) {
            controller.showLocationPrompt = false; // Reset the flag so it doesn't prompt again
            _showLocationChoiceDialog(context, controller);
          }
        });

        return Scaffold(
          appBar: const AppMainBar(showBack: true),
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Column(
            children: [
              _SearchAndScoreHeader(
                controller:       controller,
                searchController: _searchController,
                isDark:           isDark,
              ),
              Expanded(
                child: Stack(
                  children: [
                    // ── flutter_map ──────────────────────────────────────────
                    fm.FlutterMap(
                      // FIX: _flutterMapController is now fm.MapController
                      // so the type matches MapOptions.controller parameter
                      mapController: _flutterMapController,
                      options: fm.MapOptions(
                        initialCenter: controller.currentLatLng,
                        initialZoom:   14,
                        maxZoom:       18,
                        minZoom:       10,
                        onTap: (_, __) => controller.clearSelection(),
                      ),
                      children: [
                        // 1. OpenStreetMap base tiles
                        fm.TileLayer(
                          urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.staysafe.app',
                          maxZoom: 19,
                        ),

                        // 2. Safety zone circles (broad coloured areas)
                        fm.CircleLayer(
                          circles: controller.zones
                              .map(
                                (z) => fm.CircleMarker(
                              point:  z.center,
                              radius: z.radiusMeters,
                              color:  z.color,
                              borderColor:
                              z.color.withValues(alpha: z.color.a * 2),
                              borderStrokeWidth: 1,
                              useRadiusInMeter: true,
                            ),
                          )
                              .toList(),
                        ),

                        // 3. Cluster circles (tighter, on top of zones)
                        fm.CircleLayer(
                          circles: controller.clusters
                              .map(
                                (c) => fm.CircleMarker(
                              point:  c.center,
                              radius: c.radiusMeters * 0.5,
                              color:  c.zoneColor,
                              borderColor:
                              c.markerColor.withValues(alpha: 0.6),
                              borderStrokeWidth: 1.5,
                              useRadiusInMeter: true,
                            ),
                          )
                              .toList(),
                        ),

                        // 4. Current user location marker
                        fm.MarkerLayer(
                          markers: [
                            fm.Marker(
                              point:  controller.currentLatLng,
                              width:  24,
                              height: 24,
                              child:  const _UserLocationDot(),
                            ),
                          ],
                        ),

                        // 4.5 ✅ NEW — Walker's live location (Safe Walk tracking)
                        // Only rendered when this user is a guardian for someone
                        // currently on an active Safe Walk.
                        if (controller.walkerLatLng != null)
                          fm.MarkerLayer(
                            markers: [
                              fm.Marker(
                                point:  controller.walkerLatLng!,
                                width:  50,
                                height: 50,
                                child:  _WalkerLocationDot(
                                  isEmergency: controller.isWalkEmergency,
                                ),
                              ),
                            ],
                          ),

                        // 5. Incident pin markers
                        fm.MarkerLayer(
                          markers: controller.clusters
                              .map(
                                (cluster) => fm.Marker(
                              point:  cluster.center,
                              width:  44,
                              height: 44,
                              child: _IncidentMarker(
                                cluster:    cluster,
                                isSelected: controller.selectedCluster ==
                                    cluster,
                                onTap: () {
                                  controller.selectCluster(cluster);
                                  _showClusterSheet(
                                      context, cluster, controller);
                                },
                              ),
                            ),
                          )
                              .toList(),
                        ),

                        // 4.6 ✅ NEW — Active SOS/Panic markers from other users
                        fm.MarkerLayer(
                          markers: controller.activeSOSAlerts
                              .map(
                                (alert) => fm.Marker(
                              point:  LatLng(alert.latitude, alert.longitude),
                              width:  60,
                              height: 60,
                              child: _SOSMarker(
                                alert: alert,
                                onTap: () {
                                  _showSOSAlertSheet(context, alert);
                                },
                              ),
                            ),
                          )
                              .toList(),
                        ),
                      ],
                    ),

                    // ── Loading overlay ──────────────────────────────────────
                    if (controller.isLoading)
                      const Center(child: CircularProgressIndicator()),

                    // ── Error banner ─────────────────────────────────────────
                    if (controller.errorMessage != null)
                      Positioned(
                        top: 12,
                        left: 16,
                        right: 16,
                        child: _ErrorBanner(message: controller.errorMessage!),
                      ),

                    // ── ✅ NEW — Safe Walk tracking banner ────────────────────
                    // Shown when this user (guardian) is currently tracking
                    // someone else's active Safe Walk.
                    if (controller.trackedWalk != null)
                      Positioned(
                        top: controller.errorMessage != null ? 64 : 12,
                        left: 16,
                        right: 16,
                        child: _TrackingBanner(controller: controller),
                      ),

                    // ── Risk level legend ────────────────────────────────────
                    const Positioned(
                      top: 16,
                      right: 16,
                      child: _RiskLegend(),
                    ),

                    // ── Filter chips ─────────────────────────────────────────
                    Positioned(
                      bottom: 90,
                      left: 16,
                      right: 16,
                      child: _FilterBar(controller: controller),
                    ),

                    // ── Panic Button ─────────────────────────────────────────
                    const PanicButton(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClusterSheet(
      BuildContext context,
      ReportCluster cluster,
      MapController controller,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClusterBottomSheet(cluster: cluster),
    ).whenComplete(controller.clearSelection);
  }

  void _showIncomingWalkDialog(
      BuildContext context,
      String walkerName,
      String destination,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.shield, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Safe Walk Started'),
          ],
        ),
        content: Text(
          '$walkerName has started a Safe Walk to $destination and is sharing their live location with you.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Track Now'),
          ),
        ],
      ),
    );
  }

  void _showLocationChoiceDialog(BuildContext context, MapController controller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.teal),
            SizedBox(width: 8),
            Text('Set Your Location'),
          ],
        ),
        content: const Text(
          'Choose whether to use your device\'s live GPS location or simulate a location in Pakistan (recommended for emulator testing).',
          style: TextStyle(fontSize: 15),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    controller.setLiveLocation();
                  },
                  icon: const Icon(Icons.gps_fixed),
                  label: const Text('Use Live GPS Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    controller.setSimulatedLocation(
                      30.1575,
                      71.5249,
                      'Multan, Pakistan',
                    );
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Simulate in Multan, Pakistan'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    controller.setSimulatedLocation(
                      33.6844,
                      73.0479,
                      'Islamabad, Pakistan',
                    );
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Simulate in Islamabad, Pakistan'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search + Score Header ──────────────────────────────────────────────────

class _SearchAndScoreHeader extends StatelessWidget {
  const _SearchAndScoreHeader({
    required this.controller,
    required this.searchController,
    required this.isDark,
  });

  final MapController         controller;
  final TextEditingController searchController;
  final bool                  isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          // Search field
          TextField(
            controller: searchController,
            style: TextStyle(color: AppColor.getTextPrimary(context)),
            onSubmitted: controller.searchLocation,
            decoration: InputDecoration(
              prefixIcon: controller.isSearching
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : Icon(Icons.search,
                  color: AppColor.getIconSecondary(context)),
              hintText: 'Search location or area…',
              hintStyle: TextStyle(color: AppColor.getTextTertiary(context)),
              filled: true,
              fillColor: AppColor.getContainerBackground(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: AppColor.getContainerBorder(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: AppColor.getContainerBorder(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: AppColor.getInteractivePrimary(context)),
              ),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  searchController.clear();
                  FocusScope.of(context).unfocus();
                },
                icon: Icon(Icons.close,
                    color: AppColor.getIconSecondary(context)),
              )
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          // Location + Safety Score card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEDE9FE), const Color(0xFFFCE7F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.teal.shade700
                    : Colors.purple.shade200,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.isLocating
                          ? 'Locating…'
                          : 'Current Location',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColor.teal300
                            : Colors.purple.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.currentAddress,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColor.getTextPrimary(context),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: controller.scoreColor,
                          ),
                          child: Text('${controller.safetyScore}'),
                        ),
                        Text(
                          '/100',
                          style: TextStyle(
                            color: AppColor.getTextSecondary(context),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Safety Score',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColor.getTextSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── User Location Dot ──────────────────────────────────────────────────────

class _UserLocationDot extends StatelessWidget {
  const _UserLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.teal400,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.45),
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }
}

// ── ✅ NEW — Walker Live Location Dot (Safe Walk) ────────────────────────────
// Shown on a guardian's map to indicate the live position of someone
// currently on a Safe Walk. Turns red + warning icon during emergencies.

class _WalkerLocationDot extends StatelessWidget {
  const _WalkerLocationDot({required this.isEmergency});
  final bool isEmergency;

  @override
  Widget build(BuildContext context) {
    final color = isEmergency ? Colors.red : Colors.deepPurple;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Icon(
        isEmergency ? Icons.warning_amber : Icons.directions_walk,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

// ── ✅ NEW — Safe Walk Tracking Banner ────────────────────────────────────────
// Shown at the top of the guardian's map while tracking an active Safe Walk.
// Tapping the close icon stops tracking (clears the marker + banner).

class _TrackingBanner extends StatelessWidget {
  const _TrackingBanner({required this.controller});
  final MapController controller;

  @override
  Widget build(BuildContext context) {
    final isEmergency = controller.isWalkEmergency;
    final name = controller.trackedWalkerName ?? 'Someone';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isEmergency
            ? Colors.red.withValues(alpha: 0.95)
            : Colors.deepPurple.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isEmergency ? Icons.warning_amber : Icons.directions_walk,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isEmergency
                  ? '🚨 $name needs help! Tracking location…'
                  : "Tracking $name's Safe Walk",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: controller.stopTrackingWalk,
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

// ── Incident Marker ────────────────────────────────────────────────────────

class _IncidentMarker extends StatelessWidget {
  const _IncidentMarker({
    required this.cluster,
    required this.isSelected,
    required this.onTap,
  });

  final ReportCluster cluster;
  final bool          isSelected;
  final VoidCallback  onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width:  isSelected ? 48 : 40,
        height: isSelected ? 48 : 40,
        decoration: BoxDecoration(
          color:  cluster.markerColor.withValues(alpha: 0.85),
          shape:  BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: cluster.markerColor.withValues(alpha: 0.4),
              blurRadius: isSelected ? 12 : 6,
              spreadRadius: isSelected ? 3 : 1,
            ),
          ],
        ),
        child: Center(
          child: cluster.count > 1
              ? Text(
            '${cluster.count}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          )
              : const Icon(Icons.location_on,
              color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ── Risk Legend ────────────────────────────────────────────────────────────

class _RiskLegend extends StatelessWidget {
  const _RiskLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.getContainerBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.getContainerBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Levels',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: AppColor.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          _dot(Colors.red,    'High Risk', context),
          _dot(Colors.orange, 'Medium',    context),
          _dot(Colors.yellow, 'Low Risk',  context),
        ],
      ),
    );
  }

  Widget _dot(Color color, String label, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColor.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Bar ─────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});
  final MapController controller;

  @override
  Widget build(BuildContext context) {
    final filter = controller.filter;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(context,
              label: 'High',
              color: Colors.red,
              active: filter.severities.contains('high'),
              onTap: () => controller.toggleSeverity('high')),
          const SizedBox(width: 8),
          _chip(context,
              label: 'Medium',
              color: Colors.orange,
              active: filter.severities.contains('medium'),
              onTap: () => controller.toggleSeverity('medium')),
          const SizedBox(width: 8),
          _chip(context,
              label: 'Low',
              color: Colors.yellow.shade700,
              active: filter.severities.contains('low'),
              onTap: () => controller.toggleSeverity('low')),
          if (!filter.isDefault) ...[
            const SizedBox(width: 8),
            _chip(context,
                label: 'Reset',
                color: Colors.grey,
                active: true,
                onTap: controller.resetFilters),
          ],
        ],
      ),
    );
  }

  Widget _chip(
      BuildContext context, {
        required String label,
        required Color color,
        required bool active,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.15)
              : AppColor.getContainerBackground(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color : AppColor.getContainerBorder(context),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? color : AppColor.getTextSecondary(context),
          ),
        ),
      ),
    );
  }
}

// ── Cluster Bottom Sheet ───────────────────────────────────────────────────

class _ClusterBottomSheet extends StatelessWidget {
  const _ClusterBottomSheet({required this.cluster});
  final ReportCluster cluster;

  @override
  Widget build(BuildContext context) {
    // FIX: removed unused 'isDark' variable that was causing the warning

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize:     0.25,
      maxChildSize:     0.85,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: AppColor.getContainerBackground(context),
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColor.getContainerBorder(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cluster.markerColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${cluster.dominantSeverity.toUpperCase()} RISK',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${cluster.count} incident${cluster.count > 1 ? 's' : ''} nearby',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColor.getTextPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: cluster.reports.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) =>
                      _ReportTile(report: cluster.reports[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Individual Report Tile ─────────────────────────────────────────────────

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});
  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final color   = _severityColor(report.severity);
    final timeAgo = _formatTime(report.incidentTime);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border:
                  Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  report.severity.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  timeAgo,
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColor.getTextSecondary(context)),
                ),
              ),
            ],
          ),
          if (report.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              report.description,
              style: TextStyle(
                  fontSize: 14,
                  color: AppColor.getTextPrimary(context)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (report.locationAddress != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 13,
                    color: AppColor.getTextTertiary(context)),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    report.locationAddress!,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColor.getTextTertiary(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (report.severity == 'high') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '⚠️ Exercise caution in this area',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.amber,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'high':   return Colors.red.shade600;
      case 'medium': return Colors.orange.shade500;
      default:       return Colors.yellow.shade700;
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Unknown time';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Error Banner ───────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SOS Marker Widget & Details Sheet ────────────────────────────────────────

class _SOSMarker extends StatefulWidget {
  final PanicAlert alert;
  final VoidCallback onTap;

  const _SOSMarker({
    required this.alert,
    required this.onTap,
  });

  @override
  State<_SOSMarker> createState() => _SOSMarkerState();
}

class _SOSMarkerState extends State<_SOSMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulsar;

  @override
  void initState() {
    super.initState();
    _pulsar = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.7,
      upperBound: 1.2,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulsar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulsar,
        builder: (context, _) {
          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 50 * _pulsar.value,
                  height: 50 * _pulsar.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emergency,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

void _showSOSAlertSheet(BuildContext context, PanicAlert alert) {
  final colorScheme = Theme.of(context).colorScheme;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🚨 ACTIVE SOS ALERT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'A nearby SafeMap user needs assistance.',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: colorScheme.outlineVariant),
            const SizedBox(height: 12),
            const Text(
              'Safety Instructions:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _safetyRule(Icons.call, 'Call official emergency response (15) immediately.'),
            const SizedBox(height: 6),
            _safetyRule(Icons.people, 'Only approach the area if it is safe to do so.'),
            const SizedBox(height: 6),
            _safetyRule(Icons.remove_red_eye, 'Observe from a distance and assist authorities if needed.'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final Uri tel = Uri(scheme: 'tel', path: '15');
                      if (await canLaunchUrl(tel)) {
                        await launchUrl(tel);
                      }
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Call 15'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget _safetyRule(IconData icon, String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: Colors.grey.shade600),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, height: 1.3),
        ),
      ),
    ],
  );
}