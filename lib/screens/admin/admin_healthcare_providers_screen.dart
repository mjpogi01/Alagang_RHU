import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import 'admin_ui.dart';

const _typeColors = {
  'Barangay Health Center': AdminUI.emerald,
  'Government Hospital': AdminUI.blue,
  'Private Clinic': AdminUI.violet,
  'Rural Health Unit': AdminUI.teal,
  'Specialty Center': AdminUI.amber,
};

const _facilityTypes = [
  'Barangay Health Center',
  'Government Hospital',
  'Private Clinic',
  'Rural Health Unit',
  'Specialty Center',
];

/// Admin: add, edit, or remove healthcare facilities (from Supabase).
class AdminHealthcareProvidersScreen extends StatefulWidget {
  const AdminHealthcareProvidersScreen({super.key, this.hideAppBar = false});

  final bool hideAppBar;

  @override
  State<AdminHealthcareProvidersScreen> createState() =>
      _AdminHealthcareProvidersScreenState();
}

class _AdminHealthcareProvidersScreenState
    extends State<AdminHealthcareProvidersScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _facilities = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await SupabaseService.client
          .from('health_facilities')
          .select()
          .order('name', ascending: true);
      final list = List<Map<String, dynamic>>.from(res as List);
      if (!mounted) return;
      setState(() {
        _facilities = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.hideAppBar) return body;
    return Scaffold(
      backgroundColor: AdminUI.bg,
      appBar: const AdminAppBar(title: 'Health Facilities'),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    final pad = AppTheme.scale(context, AppTheme.spacingLg);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AdminUI.red)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + AppTheme.floatingNavBarClearance),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Health Facilities',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AdminUI.textPrimary,
                    ),
              ),
              Material(
                color: AdminUI.indigo,
                borderRadius: BorderRadius.circular(AdminUI.radiusSm),
                child: InkWell(
                  onTap: () => _showAddOrEditFacility(context),
                  borderRadius: BorderRadius.circular(AdminUI.radiusSm),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_facilities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No facilities yet. Tap Add to create one.',
                  style: TextStyle(color: AdminUI.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...List.generate(_facilities.length, (i) {
              final f = _facilities[i];
              return _FacilityCard(
                facility: f,
                typeColor: _typeColors[f['type'] as String?] ?? AdminUI.indigo,
                onEdit: () => _showAddOrEditFacility(context, existing: f),
                onRemove: () => _confirmRemove(context, f),
                onAddService: () => _showAddService(context, f),
                onRemoveService: (index) => _removeService(f, index),
              );
            }),
        ],
      ),
    );
  }

  void _showAddOrEditFacility(BuildContext context, {Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] as String? ?? '');
    final typeIdx = existing != null
        ? _facilityTypes.indexOf(existing['type'] as String? ?? '')
        : 0;
    final phoneCtrl = TextEditingController(text: existing?['phone'] as String? ?? '');
    final hoursCtrl = TextEditingController(text: existing?['hours'] as String? ?? '');
    final serviceInputCtrl = TextEditingController();
    bool isActive = existing?['is_open'] as bool? ?? true;
    int selectedTypeIndex = typeIdx >= 0 ? typeIdx : 0;
    List<String> servicesList = List<String>.from(
      (existing?['services'] as List<dynamic>?)?.map((e) => e.toString()) ?? [],
    );
    LatLng? pinPosition;
    final lat = existing?['latitude'] as num?;
    final lng = existing?['longitude'] as num?;
    if (lat != null && lng != null) pinPosition = LatLng(lat.toDouble(), lng.toDouble());
    const defaultMapCenter = LatLng(14.0, 120.65);

    final isEdit = existing != null;
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: AdminUI.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminUI.radiusMd)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminUI.radiusMd), borderSide: const BorderSide(color: AdminUI.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminUI.radiusMd), borderSide: const BorderSide(color: AdminUI.indigo, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: AdminUI.textSecondary),
      hintStyle: const TextStyle(color: AdminUI.textTertiary),
    );

    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 560),
              decoration: BoxDecoration(
                color: AdminUI.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8)),
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                    decoration: BoxDecoration(
                      color: AdminUI.indigo.withOpacity(0.08),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AdminUI.indigo.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_hospital_rounded, color: AdminUI.indigo, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            isEdit ? 'Edit facility' : 'Add facility',
                            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AdminUI.textPrimary,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: IconButton.styleFrom(foregroundColor: AdminUI.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: nameCtrl,
                            decoration: inputDecoration.copyWith(labelText: 'Name', hintText: 'Facility name'),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<int>(
                            value: selectedTypeIndex,
                            decoration: inputDecoration.copyWith(labelText: 'Type'),
                            dropdownColor: AdminUI.surface,
                            borderRadius: BorderRadius.circular(AdminUI.radiusMd),
                            items: List.generate(_facilityTypes.length, (i) => DropdownMenuItem(value: i, child: Text(_facilityTypes[i]))),
                            onChanged: (v) => setDialogState(() => selectedTypeIndex = v ?? 0),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: phoneCtrl,
                            decoration: inputDecoration.copyWith(
                              labelText: 'Contact number / hotline',
                              hintText: 'e.g. +63 2 8123 4567',
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: hoursCtrl,
                            decoration: inputDecoration.copyWith(
                              labelText: 'Days and hours of operation',
                              hintText: 'e.g. Mon–Fri 8AM–5PM or 24/7',
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Location (tap map to set pin)',
                            style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AdminUI.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 160,
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: pinPosition ?? defaultMapCenter,
                                  initialZoom: pinPosition != null ? 15 : 12,
                                  onTap: (_, point) => setDialogState(() => pinPosition = point),
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.scrollWheelZoom,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'dev.alagang.rhu',
                                  ),
                                  if (pinPosition != null)
                                    MarkerLayer(
                                      markers: [
                                        Marker(
                                          point: pinPosition!,
                                          width: 40,
                                          height: 40,
                                          child: const Icon(Icons.location_on_rounded, color: AdminUI.indigo, size: 40),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (pinPosition != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${pinPosition!.latitude.toStringAsFixed(5)}, ${pinPosition!.longitude.toStringAsFixed(5)}',
                                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: AdminUI.textTertiary),
                              ),
                            ),
                          const SizedBox(height: 20),
                          Text(
                            'Services offered',
                            style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AdminUI.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...servicesList.map((s) => Chip(
                                    label: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                    deleteIcon: const Icon(Icons.close_rounded, size: 16, color: AdminUI.textTertiary),
                                    onDeleted: () => setDialogState(() => servicesList.remove(s)),
                                    backgroundColor: AdminUI.indigo.withOpacity(0.08),
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  )),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: serviceInputCtrl,
                                  decoration: inputDecoration.copyWith(
                                    hintText: 'Type to add a service',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  ).copyWith(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                                  textCapitalization: TextCapitalization.words,
                                  onSubmitted: (v) {
                                    final t = v.trim();
                                    if (t.isNotEmpty && !servicesList.contains(t)) {
                                      setDialogState(() => servicesList.add(t));
                                      serviceInputCtrl.clear();
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: AdminUI.indigo.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                child: IconButton(
                                  icon: const Icon(Icons.add_rounded, color: AdminUI.indigo),
                                  onPressed: () {
                                    final t = serviceInputCtrl.text.trim();
                                    if (t.isNotEmpty && !servicesList.contains(t)) {
                                      setDialogState(() => servicesList.add(t));
                                      serviceInputCtrl.clear();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AdminUI.border.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Active', style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AdminUI.textPrimary)),
                                Theme(
                                  data: Theme.of(ctx).copyWith(
                                    switchTheme: SwitchThemeData(
                                      thumbColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? AdminUI.indigo : null),
                                      trackColor: MaterialStateProperty.resolveWith((states) => states.contains(MaterialState.selected) ? AdminUI.indigo.withOpacity(0.5) : null),
                                    ),
                                  ),
                                  child: Switch.adaptive(
                                    value: isActive,
                                    onChanged: (v) => setDialogState(() => isActive = v),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AdminUI.textSecondary,
                              side: const BorderSide(color: AdminUI.border),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Name is required')));
                                return;
                              }
                  final payload = {
                    'name': name,
                    'type': _facilityTypes[selectedTypeIndex],
                    'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    'hours': hoursCtrl.text.trim().isEmpty ? null : hoursCtrl.text.trim(),
                    'is_open': isActive,
                    'services': servicesList,
                    if (pinPosition != null) 'latitude': pinPosition!.latitude,
                    if (pinPosition != null) 'longitude': pinPosition!.longitude,
                  };
                              try {
                                if (existing != null) {
                                  await SupabaseService.client.from('health_facilities').update(payload).eq('id', existing['id']);
                                } else {
                                  await SupabaseService.client.from('health_facilities').insert(payload);
                                }
                                if (!context.mounted) return;
                                Navigator.of(ctx).pop();
                                _loadData();
                              } on PostgrestException catch (e) {
                                if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.message)));
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AdminUI.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(isEdit ? 'Save changes' : 'Add facility'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddService(BuildContext context, Map<String, dynamic> facility) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add service'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Service name'),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) => _submitAddService(ctx, facility, ctrl.text.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => _submitAddService(ctx, facility, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAddService(BuildContext ctx, Map<String, dynamic> facility, String name) async {
    if (name.isEmpty) return;
    final list = List<String>.from((facility['services'] as List<dynamic>?)?.map((e) => e.toString()) ?? []);
    if (list.contains(name)) {
      Navigator.of(ctx).pop();
      return;
    }
    list.add(name);
    try {
      await SupabaseService.client.from('health_facilities').update({'services': list}).eq('id', facility['id']);
      if (!mounted) return;
      Navigator.of(ctx).pop();
      _loadData();
    } on PostgrestException catch (e) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _removeService(Map<String, dynamic> facility, int index) async {
    final list = List<String>.from((facility['services'] as List<dynamic>?)?.map((e) => e.toString()) ?? []);
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    try {
      await SupabaseService.client.from('health_facilities').update({'services': list}).eq('id', facility['id']);
      if (mounted) _loadData();
    } catch (_) {}
  }

  void _confirmRemove(BuildContext context, Map<String, dynamic> facility) {
    final name = facility['name'] as String? ?? 'Facility';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove facility?'),
        content: Text('Remove "$name"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminUI.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await SupabaseService.client.from('health_facilities').delete().eq('id', facility['id']);
                if (mounted) _loadData();
              } catch (_) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete')));
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({
    required this.facility,
    required this.typeColor,
    required this.onEdit,
    required this.onRemove,
    required this.onAddService,
    required this.onRemoveService,
  });

  final Map<String, dynamic> facility;
  final Color typeColor;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onAddService;
  final void Function(int index) onRemoveService;

  @override
  Widget build(BuildContext context) {
    final name = facility['name'] as String? ?? '—';
    final type = facility['type'] as String? ?? '—';
    final address = facility['address'] as String? ?? '';
    final phone = facility['phone'] as String? ?? '';
    final hours = facility['hours'] as String? ?? '';
    final isOpen = facility['is_open'] as bool? ?? true;
    final lat = facility['latitude'] as num?;
    final lng = facility['longitude'] as num?;
    final hasLocation = lat != null && lng != null;
    final services = (facility['services'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AdminCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: typeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.local_hospital_outlined, color: typeColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AdminUI.textPrimary)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: typeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                        child: Text(type, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: typeColor)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isOpen ? const Color(0xFF16A34A) : AdminUI.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(isOpen ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isOpen ? const Color(0xFF16A34A) : AdminUI.red)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (address.isNotEmpty) _DetailRow(icon: Icons.location_on_outlined, text: address),
            if (phone.isNotEmpty) _DetailRow(icon: Icons.phone_outlined, text: phone),
            if (hours.isNotEmpty) _DetailRow(icon: Icons.schedule_outlined, text: hours),
            if (hasLocation) _DetailRow(icon: Icons.pin_drop_rounded, text: 'Map pin: ${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'),
            const SizedBox(height: 10),
            Text('SERVICES OFFERED', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminUI.textTertiary, fontWeight: FontWeight.w700, fontSize: 10)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...services.asMap().entries.map((e) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AdminUI.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AdminUI.indigo)),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => onRemoveService(e.key),
                            child: Icon(Icons.close, size: 12, color: AdminUI.indigo.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    )),
                GestureDetector(
                  onTap: onAddService,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(border: Border.all(color: AdminUI.border), borderRadius: BorderRadius.circular(8)),
                    child: Text('+ Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AdminUI.textTertiary)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(foregroundColor: AdminUI.indigo, side: const BorderSide(color: AdminUI.indigo)),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(foregroundColor: AdminUI.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AdminUI.textTertiary),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminUI.textSecondary))),
        ],
      ),
    );
  }
}
