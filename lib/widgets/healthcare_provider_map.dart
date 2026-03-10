import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/healthcare_facility.dart';
import '../theme/app_theme.dart';

/// Leaflet-style map (OpenStreetMap via flutter_map) showing nearest hospitals and clinics.
/// When [selectedFacility] is set, the map centers and zooms on it; pass [mapController]
/// so the parent can call [MapController.move] when selection changes.
class HealthcareProviderMap extends StatelessWidget {
  const HealthcareProviderMap({
    super.key,
    required this.facilities,
    this.selectedFacility,
    this.mapController,
    this.initialZoom = 12.5,
    this.selectedZoom = 15.0,
    this.height = 220,
    this.onMarkerTap,
  });

  final List<HealthcareFacility> facilities;
  final HealthcareFacility? selectedFacility;
  final MapController? mapController;
  final double initialZoom;
  final double selectedZoom;
  final double height;
  final void Function(HealthcareFacility)? onMarkerTap;

  @override
  Widget build(BuildContext context) {
    final center = selectedFacility?.position ?? _centerOfFacilities(facilities);
    final zoom = selectedFacility != null ? selectedZoom : initialZoom;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.spacingRadiusMd),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag | InteractiveFlag.flingAnimation | InteractiveFlag.pinchZoom | InteractiveFlag.scrollWheelZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'dev.alagang.rhu',
            ),
            MarkerLayer(
              markers: facilities
                  .map(
                    (f) => Marker(
                      point: f.position,
                      width: 44,
                      height: 44,
                      child: _MarkerPin(
                        facility: f,
                        isSelected: selectedFacility == f,
                        onTap: onMarkerTap != null ? () => onMarkerTap!(f) : null,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  static LatLng _centerOfFacilities(List<HealthcareFacility> list) {
    if (list.isEmpty) return const LatLng(14.0, 120.65);
    double lat = 0, lng = 0;
    for (final f in list) {
      lat += f.position.latitude;
      lng += f.position.longitude;
    }
    return LatLng(lat / list.length, lng / list.length);
  }
}

class _MarkerPin extends StatelessWidget {
  const _MarkerPin({
    required this.facility,
    this.isSelected = false,
    this.onTap,
  });

  final HealthcareFacility facility;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = facility.isHospital ? AppTheme.accentEmergency : AppTheme.primaryBlue;
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: facility.name,
        child: Icon(
          facility.isHospital ? Icons.local_hospital : Icons.medical_services,
          color: color,
          size: isSelected ? 36 : 32,
        ),
      ),
    );
  }
}
