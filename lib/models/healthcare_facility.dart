import 'package:latlong2/latlong.dart';

/// Type of healthcare facility for map and list display.
enum HealthcareFacilityType { hospital, clinic }

/// Level of care: primary care facility, or hospital level L1–L3.
enum FacilityLevel {
  primaryCare('Pangunahing pangangalaga'),
  l1('L1'),
  l2('L2'),
  l3('L3');

  const FacilityLevel(this.label);
  final String label;
}

/// Government or private sector.
enum FacilitySector {
  government('Pampubliko'),
  private_('Pribado');

  const FacilitySector(this.label);
  final String label;
}

/// A hospital or clinic location for the provider network map.
class HealthcareFacility {
  const HealthcareFacility({
    required this.name,
    required this.position,
    required this.type,
    this.address,
    this.distanceKm,
    this.contactPhone,
    this.contactEmail,
    this.services,
    this.level,
    this.sector,
  });

  final String name;
  final LatLng position;
  final HealthcareFacilityType type;
  final String? address;
  final double? distanceKm;
  final String? contactPhone;
  final String? contactEmail;

  /// Services offered (e.g. colonoscopy, dialysis, maternity).
  final List<String>? services;
  final FacilityLevel? level;
  final FacilitySector? sector;

  bool get isHospital => type == HealthcareFacilityType.hospital;

  /// Category string for display: level + sector (e.g. "L2 · Government").
  String get categoryLabel {
    final parts = <String>[];
    if (level != null) parts.add(level!.label);
    if (sector != null) parts.add(sector!.label);
    return parts.isEmpty ? '—' : parts.join(' · ');
  }
}

/// Returns true if [facility] matches [query] (name, services, level, sector).
bool facilityMatchesSearch(HealthcareFacility facility, String query) {
  if (query.trim().isEmpty) return true;
  final q = query.trim().toLowerCase();
  if (facility.name.toLowerCase().contains(q)) return true;
  if (facility.level?.label.toLowerCase().contains(q) ?? false) return true;
  if (facility.sector?.label.toLowerCase().contains(q) ?? false) return true;
  final aliases = <String>[
    if (facility.level == FacilityLevel.primaryCare)
      'primary care primary care facility',
    if (facility.sector == FacilitySector.government) 'government public',
    if (facility.sector == FacilitySector.private_) 'private',
  ];
  for (final alias in aliases) {
    if (alias.contains(q)) return true;
  }
  for (final s in facility.services ?? []) {
    if (s.toLowerCase().contains(q)) return true;
  }
  return false;
}

/// Default selected facility name when opening the Healthcare Provider sheet (Lian Municipal Health Office).
const String defaultSelectedFacilityName = 'Lian Municipal Health Office (RHU)';

/// Returns [sampleHealthcareFacilities] sorted by distance (nearest first). Null distances go last.
List<HealthcareFacility> get sortedHealthcareFacilities {
  final list = List<HealthcareFacility>.from(sampleHealthcareFacilities);
  list.sort((a, b) {
    final da = a.distanceKm;
    final db = b.distanceKm;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  });
  return list;
}

/// Index of [defaultSelectedFacilityName] in [sortedHealthcareFacilities], or 0.
int get defaultSelectedFacilityIndex {
  final sorted = sortedHealthcareFacilities;
  final i = sorted.indexWhere((f) => f.name == defaultSelectedFacilityName);
  return i >= 0 ? i : 0;
}

/// Sample facilities near the user area (e.g. Lian, Batangas / nearby).
/// Replace with real data from API or local DB later.
List<HealthcareFacility> get sampleHealthcareFacilities {
  // Center roughly Lian / Nasugbu area, Batangas
  const base = LatLng(14.0, 120.65);
  return [
    HealthcareFacility(
      name: 'Lian Municipal Health Office (RHU)',
      position: base,
      type: HealthcareFacilityType.clinic,
      address: 'Lian, Batangas',
      distanceKm: 0.5,
      contactPhone: '(043) 723 1234',
      level: FacilityLevel.primaryCare,
      sector: FacilitySector.government,
      services: ['Primary care', 'Immunization', 'Prenatal', 'Family planning'],
    ),
    HealthcareFacility(
      name: 'Lian District Hospital',
      position: LatLng(base.latitude + 0.02, base.longitude + 0.01),
      type: HealthcareFacilityType.hospital,
      address: 'Brgy. Lumaniag, Lian, Batangas',
      distanceKm: 2.1,
      contactPhone: '(043) 723 4567',
      level: FacilityLevel.l1,
      sector: FacilitySector.government,
      services: ['Emergency', 'Outpatient', 'Maternity', 'Laboratory'],
    ),
    HealthcareFacility(
      name: 'Nasugbu Community Hospital',
      position: LatLng(base.latitude - 0.03, base.longitude + 0.02),
      type: HealthcareFacilityType.hospital,
      address: 'Nasugbu, Batangas',
      distanceKm: 4.0,
      contactPhone: '(043) 722 1000',
      level: FacilityLevel.l1,
      sector: FacilitySector.government,
      services: ['Emergency', 'Dialysis', 'X-ray', 'Maternity'],
    ),
    HealthcareFacility(
      name: 'Barangay Health Station - Lian',
      position: LatLng(base.latitude + 0.015, base.longitude - 0.008),
      type: HealthcareFacilityType.clinic,
      address: 'Lian, Batangas',
      distanceKm: 1.2,
      contactPhone: '(043) 723 1100',
      level: FacilityLevel.primaryCare,
      sector: FacilitySector.government,
      services: ['Primary care', 'Immunization', 'Basic consultations'],
    ),
    HealthcareFacility(
      name: 'Calatagan Rural Health Unit',
      position: LatLng(base.latitude - 0.04, base.longitude - 0.02),
      type: HealthcareFacilityType.clinic,
      address: 'Calatagan, Batangas',
      distanceKm: 8.5,
      contactPhone: '(043) 721 2000',
      level: FacilityLevel.primaryCare,
      sector: FacilitySector.government,
      services: ['Primary care', 'Prenatal', 'TB-DOTS'],
    ),
    HealthcareFacility(
      name: 'Batangas Provincial Hospital',
      position: LatLng(base.latitude + 0.08, base.longitude + 0.12),
      type: HealthcareFacilityType.hospital,
      address: 'Kumintang Ibaba, Batangas City',
      distanceKm: 18.0,
      contactPhone: '(043) 723 8000',
      level: FacilityLevel.l3,
      sector: FacilitySector.government,
      services: [
        'Emergency',
        'Surgery',
        'Dialysis',
        'Colonoscopy',
        'ICU',
        'Maternity',
      ],
    ),
    HealthcareFacility(
      name: 'St. Patrick Hospital - Batangas',
      position: LatLng(base.latitude + 0.06, base.longitude + 0.10),
      type: HealthcareFacilityType.hospital,
      address: 'Batangas City',
      distanceKm: 15.2,
      contactPhone: '(043) 723 9000',
      level: FacilityLevel.l2,
      sector: FacilitySector.private_,
      services: [
        'Emergency',
        'Dialysis',
        'Colonoscopy',
        'Endoscopy',
        'Maternity',
      ],
    ),
    HealthcareFacility(
      name: 'Lipa City District Hospital',
      position: LatLng(base.latitude + 0.12, base.longitude + 0.08),
      type: HealthcareFacilityType.hospital,
      address: 'Lipa City, Batangas',
      distanceKm: 22.5,
      contactPhone: '(043) 774 1000',
      level: FacilityLevel.l2,
      sector: FacilitySector.government,
      services: ['Emergency', 'Dialysis', 'Surgery', 'Maternity', 'Laboratory'],
    ),
    HealthcareFacility(
      name: 'Nasugbu Medicare Hospital',
      position: LatLng(base.latitude - 0.025, base.longitude + 0.018),
      type: HealthcareFacilityType.hospital,
      address: 'Nasugbu, Batangas',
      distanceKm: 3.8,
      contactPhone: '(043) 722 2000',
      level: FacilityLevel.l1,
      sector: FacilitySector.government,
      services: ['Emergency', 'Outpatient', 'Dialysis', 'X-ray'],
    ),
    HealthcareFacility(
      name: 'Calatagan District Hospital',
      position: LatLng(base.latitude - 0.045, base.longitude - 0.025),
      type: HealthcareFacilityType.hospital,
      address: 'Calatagan, Batangas',
      distanceKm: 9.2,
      contactPhone: '(043) 721 3000',
      level: FacilityLevel.l1,
      sector: FacilitySector.government,
      services: ['Emergency', 'Maternity', 'Laboratory'],
    ),
    HealthcareFacility(
      name: 'Tuy Municipal Hospital',
      position: LatLng(base.latitude - 0.01, base.longitude - 0.035),
      type: HealthcareFacilityType.hospital,
      address: 'Tuy, Batangas',
      distanceKm: 6.5,
      contactPhone: '(043) 724 1000',
      level: FacilityLevel.l1,
      sector: FacilitySector.government,
      services: ['Emergency', 'Outpatient', 'Maternity'],
    ),
    HealthcareFacility(
      name: 'Balayan District Hospital',
      position: LatLng(base.latitude - 0.02, base.longitude + 0.06),
      type: HealthcareFacilityType.hospital,
      address: 'Balayan, Batangas',
      distanceKm: 12.0,
      contactPhone: '(043) 725 1000',
      level: FacilityLevel.l1,
      sector: FacilitySector.government,
      services: ['Emergency', 'Dialysis', 'Maternity', 'X-ray'],
    ),
    HealthcareFacility(
      name: 'Lemery District Hospital',
      position: LatLng(base.latitude - 0.05, base.longitude + 0.04),
      type: HealthcareFacilityType.hospital,
      address: 'Lemery, Batangas',
      distanceKm: 10.5,
      contactPhone: '(043) 726 1000',
      level: FacilityLevel.l1,
      sector: FacilitySector.government,
      services: ['Emergency', 'Outpatient', 'Maternity'],
    ),
    HealthcareFacility(
      name: 'Taal Polymedic Hospital',
      position: LatLng(base.latitude - 0.07, base.longitude + 0.055),
      type: HealthcareFacilityType.hospital,
      address: 'Taal, Batangas',
      distanceKm: 14.3,
      contactPhone: '(043) 727 1000',
      level: FacilityLevel.l2,
      sector: FacilitySector.private_,
      services: [
        'Emergency',
        'Colonoscopy',
        'Dialysis',
        'Maternity',
        'Surgery',
      ],
    ),
  ];
}
