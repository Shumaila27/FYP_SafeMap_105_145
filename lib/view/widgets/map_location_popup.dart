import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapLocationPopup extends StatefulWidget {
  const MapLocationPopup({super.key});

  @override
  State<MapLocationPopup> createState() => _MapLocationPopupState();
}

class _MapLocationPopupState extends State<MapLocationPopup> {
  final MapController _mapController = MapController();
  LatLng? _selectedLatLng;
  String _selectedAddress = "";
  final TextEditingController _searchController = TextEditingController();

  // Default fallback location (Islamabad)
  static final LatLng _fallbackLocation =
  LatLng(33.6844, 73.0479);

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  // ---------------- Location Initialization ----------------

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (!serviceEnabled) {
        _setFallbackLocation();
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setFallbackLocation();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _selectedLatLng = LatLng(position.latitude, position.longitude);
      await _updateAddress(_selectedLatLng!);
      setState(() {});
    } catch (_) {
      _setFallbackLocation();
    }
  }

  void _setFallbackLocation() async {
    _selectedLatLng = _fallbackLocation;
    await _updateAddress(_selectedLatLng!);
    setState(() {});
  }

  // ---------------- Address Helpers ----------------

  Future<void> _updateAddress(LatLng latLng) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(latLng.latitude, latLng.longitude);

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _selectedAddress =
        "${p.name ?? ""}, ${p.locality ?? ""}, ${p.administrativeArea ?? ""}";
      } else {
        _selectedAddress =
        "${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}";
      }
    } catch (_) {
      _selectedAddress =
      "${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}";
    }
  }

  // ---------------- Search Location ----------------

  Future<void> _searchLocation() async {
    if (_searchController.text.trim().isEmpty) return;

    try {
      List<Location> locations =
      await locationFromAddress(_searchController.text.trim());

      if (locations.isNotEmpty) {
        final loc = locations.first;
        final LatLng newLatLng = LatLng(loc.latitude, loc.longitude);

        _mapController.move(newLatLng, 15);

        _selectedLatLng = newLatLng;
        await _updateAddress(newLatLng);
        setState(() {});
      }
    } catch (_) {}
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 520,
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search location",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchLocation,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Map
            Expanded(
              child: _selectedLatLng == null
                  ? const Center(child: CircularProgressIndicator())
                  : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLatLng!,
                  initialZoom: 14,
                  onTap: (tapPosition, latLng) async {
                    _selectedLatLng = latLng;
                    await _updateAddress(latLng);
                    setState(() {});
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName:
                    "com.example.safemap",
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLatLng!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Address + Select Button
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    _selectedAddress,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          {
                            "latLng": _selectedLatLng,
                            "address": _selectedAddress,
                          },
                        );
                      },
                      child: const Text("Select Location"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
