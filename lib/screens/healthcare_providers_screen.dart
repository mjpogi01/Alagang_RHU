import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/healthcare_facility.dart';
import '../theme/app_theme.dart';
import '../widgets/healthcare_provider_map.dart';

/// Full-page Healthcare Provider Network screen using the same shell
/// as the Primary Care Services page.
class HealthcareProvidersScreen extends StatefulWidget {
  const HealthcareProvidersScreen({super.key});

  @override
  State<HealthcareProvidersScreen> createState() =>
      _HealthcareProvidersScreenState();
}

class _HealthcareProvidersScreenState extends State<HealthcareProvidersScreen> {
  late int _selectedIndex;
  final MapController _mapController = MapController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _mapSectionKey = GlobalKey();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIndex = defaultSelectedFacilityIndex;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<HealthcareFacility> _getFilteredFacilities() {
    final sorted = sortedHealthcareFacilities;
    if (_searchQuery.trim().isEmpty) return sorted;
    return sorted.where((f) => facilityMatchesSearch(f, _searchQuery)).toList();
  }

  void _selectFacility(int index, {bool scrollToMap = false}) {
    final facilities = _getFilteredFacilities();
    if (index < 0 || index >= facilities.length) return;

    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }

    _mapController.move(facilities[index].position, 15);

    if (scrollToMap) {
      _scrollToMapSection();
    }
  }

  void _scrollToMapSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final mapSectionContext = _mapSectionKey.currentContext;
      if (mapSectionContext == null) return;

      Scrollable.ensureVisible(
        mapSectionContext,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        alignment: 0.02,
      );
    });
  }

  Future<void> _openGoogleMapsDirections(double lat, double lng) async {
    final navigationUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final fallbackUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    try {
      final openedMaps = await launchUrl(
        navigationUri,
        mode: LaunchMode.externalApplication,
      );
      if (openedMaps) return;

      final openedFallback = await launchUrl(
        fallbackUri,
        mode: LaunchMode.externalApplication,
      );
      if (openedFallback) return;
    } catch (_) {
      // Fall through to user feedback below.
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Hindi mabuksan ang Google Maps. Pakisigurong may naka-install na app para sa mapa.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.bgGradientStart,
                  AppTheme.bgGradientMid,
                  AppTheme.bgGradientEnd,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -70,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -40,
            left: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: -80,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.035),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 280,
            left: -50,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            top: true,
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                Expanded(
                  child: Container(
                    color: AppTheme.surfaceWhite,
                    child: _buildBody(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scale = AppTheme.scale(context, 1.0);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.scale(context, AppTheme.spacingLg),
        AppTheme.scale(context, AppTheme.spacingLg),
        AppTheme.scale(context, AppTheme.spacingLg),
        AppTheme.scale(context, AppTheme.spacingSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: scale * 36,
                  height: scale * 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: scale * 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Center(
                  child: Text(
                    'Ugnayan ng mga\nPasilidad Pangkalusugan',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.25,
                      fontSize: AppTheme.scale(context, 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          SizedBox(height: AppTheme.scale(context, AppTheme.spacingLg)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final facilities = _getFilteredFacilities();
    if (_selectedIndex >= facilities.length) {
      _selectedIndex = 0;
    }
    final selected = facilities.isEmpty ? null : facilities[_selectedIndex];

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: false,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(
          AppTheme.scale(context, AppTheme.spacingLg),
          AppTheme.scale(context, AppTheme.spacingLg),
          AppTheme.scale(context, AppTheme.spacingLg),
          AppTheme.scale(context, AppTheme.spacingXxl) +
              AppTheme.floatingNavBarClearance,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchBar(context),
            SizedBox(height: AppTheme.scale(context, AppTheme.spacingLg)),
            Text(
              'MALALAPIT NA PASILIDAD PANGKALUSUGAN',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: AppTheme.scale(context, 12),
                fontWeight: FontWeight.w700,
                color: AppTheme.textTertiary,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(
              height: AppTheme.scale(context, AppTheme.sectionTitleToContent),
            ),
            if (facilities.isEmpty)
              _SectionPanel(
                title: 'Walang nahanap na pasilidad',
                subtitle: 'Subukan ang ibang ospital, klinika, o serbisyo.',
                accentColor: AppTheme.accentEmergency,
                child: Text(
                  'Walang pasilidad na tumutugma sa iyong hinanap.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
            else ...[
              Container(
                key: _mapSectionKey,
                child: _SectionPanel(
                  title: 'Mapa ng mga pasilidad',
                  subtitle:
                      'I-tap ang marker o item sa listahan para piliin ang pasilidad.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppTheme.spacingRadiusMd + 4,
                          ),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.22),
                            width: 1.4,
                          ),
                        ),
                        child: Stack(
                          children: [
                            HealthcareProviderMap(
                              facilities: facilities,
                              selectedFacility: selected,
                              mapController: _mapController,
                              selectedZoom: 15,
                              height: 220,
                              onMarkerTap: (facility) {
                                final index = facilities.indexOf(facility);
                                if (index >= 0) _selectFacility(index);
                              },
                            ),
                            Positioned(
                              right: AppTheme.scale(context, 12),
                              bottom: AppTheme.scale(context, 12),
                              child: FloatingActionButton.extended(
                                onPressed: () {
                                  final facility = facilities[_selectedIndex];
                                  _openGoogleMapsDirections(
                                    facility.position.latitude,
                                    facility.position.longitude,
                                  );
                                },
                                icon: const Icon(Icons.directions),
                                label: const Text('Mga Direksyon'),
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected != null) ...[
                        SizedBox(
                          height: AppTheme.scale(context, AppTheme.spacingMd),
                        ),
                        Text(
                          'Napiling pasilidad',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        SizedBox(
                          height: AppTheme.scale(context, AppTheme.spacingSm),
                        ),
                        _SelectedFacilityCard(facility: selected),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppTheme.scale(context, AppTheme.spacingLg)),
              _SectionPanel(
                title: 'Malapit sa iyo',
                subtitle:
                    'Pumili ng pasilidad sa ibaba para maituon ito sa mapa.',
                child: Column(
                  children: facilities.asMap().entries.map((entry) {
                    final isLast = entry.key == facilities.length - 1;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: isLast
                            ? 0
                            : AppTheme.scale(context, AppTheme.spacingMd),
                      ),
                      child: _FacilityTile(
                        facility: entry.value,
                        isSelected: entry.key == _selectedIndex,
                        onTap: () =>
                            _selectFacility(entry.key, scrollToMap: true),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final scale = AppTheme.scale(context, 1.0);
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
          final filtered = _getFilteredFacilities();
          if (_selectedIndex >= filtered.length) {
            _selectedIndex = 0;
          } else {
            final currentName = filtered[_selectedIndex].name;
            final newIndex = filtered.indexWhere(
              (facility) => facility.name == currentName,
            );
            _selectedIndex = newIndex >= 0 ? newIndex : 0;
          }
        });
      },
      decoration: InputDecoration(
        hintText:
            'Maghanap ng ospital, klinika, o serbisyo (hal. dialysis, colonoscopy)',
        hintStyle: TextStyle(
          color: AppTheme.textTertiary,
          fontSize: scale * 14,
        ),
        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
        filled: true,
        fillColor: AppTheme.searchBarBackground,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: AppTheme.primaryBlue.withValues(alpha: 0.22),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: AppTheme.primaryBlue.withValues(alpha: 0.22),
            width: 1.2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppTheme.scale(context, AppTheme.spacingLg),
          vertical: scale * 16,
        ),
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.child,
    this.title,
    this.subtitle,
    this.accentColor = AppTheme.primaryBlue,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final scale = AppTheme.scale(context, 1.0);
    return Container(
      padding: EdgeInsets.all(scale * 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.spacingRadiusMd + 4),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.18),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
          if (subtitle != null) ...[
            SizedBox(height: scale * 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          SizedBox(height: scale * 12),
          child,
        ],
      ),
    );
  }
}

class _SelectedFacilityCard extends StatelessWidget {
  const _SelectedFacilityCard({required this.facility});

  final HealthcareFacility facility;

  @override
  Widget build(BuildContext context) {
    final scale = AppTheme.scale(context, 1.0);
    final accentColor = facility.isHospital
        ? AppTheme.accentEmergency
        : AppTheme.primaryBlue;
    return Container(
      padding: EdgeInsets.all(scale * AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.spacingRadiusMd + 4),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(scale * 10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              facility.isHospital
                  ? Icons.local_hospital
                  : Icons.medical_services,
              color: accentColor,
              size: 28,
            ),
          ),
          SizedBox(width: scale * AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  facility.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: scale * 8),
                if (facility.address != null)
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    text: facility.address!,
                    scale: scale,
                  ),
                if (facility.contactPhone != null)
                  _DetailRow(
                    icon: Icons.phone_outlined,
                    text: facility.contactPhone!,
                    scale: scale,
                  ),
                if (facility.contactEmail != null)
                  _DetailRow(
                    icon: Icons.email_outlined,
                    text: facility.contactEmail!,
                    scale: scale,
                  ),
                _DetailRow(
                  icon: Icons.category_outlined,
                  text: facility.categoryLabel,
                  scale: scale,
                ),
                if (facility.distanceKm != null)
                  _DetailRow(
                    icon: Icons.straighten,
                    text:
                        '${facility.distanceKm!.toStringAsFixed(1)} km ang layo',
                    scale: scale,
                  ),
                if (facility.services != null &&
                    facility.services!.isNotEmpty) ...[
                  SizedBox(height: scale * 8),
                  Container(
                    padding: EdgeInsets.all(scale * 10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Mga Serbisyo: ${facility.services!.join(', ')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.text,
    required this.scale,
  });

  final IconData icon;
  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: scale * 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.primaryBlue.withValues(alpha: 0.8),
          ),
          SizedBox(width: scale * 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityTile extends StatelessWidget {
  const _FacilityTile({
    required this.facility,
    required this.onTap,
    this.isSelected = false,
  });

  final HealthcareFacility facility;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = AppTheme.scale(context, 1.0);
    final accentColor = facility.isHospital
        ? AppTheme.accentEmergency
        : AppTheme.primaryBlue;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.spacingRadiusMd + 4),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.spacingRadiusMd + 4),
        child: Container(
          padding: EdgeInsets.all(scale * AppTheme.spacingLg),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryBlue.withValues(alpha: 0.08)
                : AppTheme.cardBackground,
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryBlue
                  : AppTheme.primaryBlue.withValues(alpha: 0.2),
              width: isSelected ? 1.8 : 1.2,
            ),
            borderRadius: BorderRadius.circular(AppTheme.spacingRadiusMd + 4),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? AppTheme.primaryBlue : accentColor)
                    .withValues(alpha: isSelected ? 0.08 : 0.04),
                blurRadius: isSelected ? 18 : 10,
                offset: Offset(0, isSelected ? 8 : 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(scale * 10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  facility.isHospital
                      ? Icons.local_hospital
                      : Icons.medical_services,
                  color: accentColor,
                  size: 24,
                ),
              ),
              SizedBox(width: scale * AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      facility.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (facility.address != null) ...[
                      SizedBox(height: scale * 6),
                      Text(
                        facility.address!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                    SizedBox(height: scale * 6),
                    Text(
                      facility.categoryLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    if (facility.contactPhone != null) ...[
                      SizedBox(height: scale * 6),
                      Text(
                        facility.contactPhone!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                    if (facility.distanceKm != null) ...[
                      SizedBox(height: scale * 6),
                      Text(
                        '${facility.distanceKm!.toStringAsFixed(1)} km ang layo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : AppTheme.textTertiary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
