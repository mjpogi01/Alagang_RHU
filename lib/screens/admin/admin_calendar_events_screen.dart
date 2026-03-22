import 'dart:math' show min;

import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import 'admin_ui.dart';

/// DB group_type enum values for calendar_events.
const List<String> _groupTypes = ['buntis', 'bata', 'adolescent', 'adult', 'elderly'];
const Map<String, Color> _groupColor = {
  'buntis': AdminUI.rose,
  'bata': AdminUI.emerald,
  'adolescent': AdminUI.blue,
  'adult': AdminUI.amber,
  'elderly': AdminUI.violet,
};
const Map<String, String> _groupLabel = {
  'buntis': 'Buntis',
  'bata': 'Bata',
  'adolescent': 'Kabataan',
  'adult': 'Nasa hustong gulang',
  'elderly': 'Nakatatanda',
};

class _GroupFilterChip extends StatelessWidget {
  const _GroupFilterChip({
    required this.groupKey,
    required this.isSelected,
    required this.onChanged,
  });

  final String groupKey;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: isSelected,
      showCheckmark: true,
      label: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _groupLabel[groupKey] ?? groupKey,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            Text(
              _groupAgeRange[groupKey] ?? '',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? AdminUI.indigo.withOpacity(0.9) : AdminUI.textTertiary,
              ),
            ),
          ],
        ),
      ),
      selectedColor: AdminUI.indigo.withOpacity(0.18),
      checkmarkColor: AdminUI.indigo,
      onSelected: onChanged,
    );
  }
}

/// Standard age guidance per group (shown beside multi-select).
const Map<String, String> _groupAgeRange = {
  'buntis': 'Mga buntis',
  'bata': '0–9 taong gulang',
  'adolescent': '10–19 taong gulang',
  'adult': '20–59 taong gulang',
  'elderly': '60 pataas',
};

List<String> _groupsFromRow(Map<String, dynamic> e) {
  final gt = e['group_types'];
  if (gt is List && gt.isNotEmpty) {
    return gt.map((x) => x.toString()).where((s) => _groupTypes.contains(s)).toList();
  }
  final g = e['group_type'] as String? ?? 'adult';
  return _groupTypes.contains(g) ? [g] : ['adult'];
}

/// Admin: create calendar events (plotted on the app calendar).
class AdminCalendarEventsScreen extends StatefulWidget {
  const AdminCalendarEventsScreen({super.key, this.hideAppBar = false});

  final bool hideAppBar;

  @override
  State<AdminCalendarEventsScreen> createState() => _AdminCalendarEventsScreenState();
}

class _AdminCalendarEventsScreenState extends State<AdminCalendarEventsScreen> {
  DateTime _month = DateTime.now();
  int? selectedDay;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await SupabaseService.client
          .from('calendar_events')
          .select()
          .order('event_date', ascending: true);
      final list = List<Map<String, dynamic>>.from(res as List);
      if (!mounted) return;
      setState(() {
        _events = list;
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

  String _dateStr(Map<String, dynamic> e) {
    final d = e['event_date'];
    if (d == null) return '';
    if (d is String) return d.split('T').first;
    return d.toString().split('T').first;
  }

  /// Age groups that have at least one event on this date (legend order).
  List<String> _groupsForDate(String dateStr) {
    final set = <String>{};
    for (final e in _events) {
      if (_dateStr(e) != dateStr) continue;
      for (final g in _groupsFromRow(e)) {
        set.add(g);
      }
    }
    return _groupTypes.where((t) => set.contains(t)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (widget.hideAppBar) return body;
    return Scaffold(
      backgroundColor: AdminUI.bg,
      appBar: const AdminAppBar(title: 'Calendar Events'),
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
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AdminUI.red)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadEvents, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday % 7;
    final monthPrefix = '${_month.year}-${_month.month.toString().padLeft(2, '0')}-';

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView(
        padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + AppTheme.floatingNavBarClearance),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Calendar Events',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AdminUI.textPrimary,
                    ),
              ),
              Material(
                color: AdminUI.indigo,
                borderRadius: BorderRadius.circular(AdminUI.radiusSm),
                child: InkWell(
                  onTap: () => _showAddOrEditEvent(context),
                  borderRadius: BorderRadius.circular(AdminUI.radiusSm),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text('Create a sched', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_monthMonthName(_month)} ${_month.year}', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AdminUI.textPrimary)),
                    Row(
                      children: [
                        IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)), icon: const Icon(Icons.chevron_left), padding: EdgeInsets.zero),
                        IconButton(onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)), icon: const Icon(Icons.chevron_right), padding: EdgeInsets.zero),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Center(
                          child: Text(
                            ['S', 'M', 'T', 'W', 'T', 'F', 'S'][i],
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AdminUI.textTertiary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    ...List.generate(firstWeekday, (int _) => const SizedBox(width: 44, height: 52)),
                    ...List.generate(daysInMonth, (i) {
                      final d = i + 1;
                      final dateStr = '$monthPrefix${d.toString().padLeft(2, '0')}';
                      final groupsForDots = _groupsForDate(dateStr);
                      final hasEvent = groupsForDots.isNotEmpty;
                      final isSelected = selectedDay == d;
                      return SizedBox(
                        width: 44,
                        height: 52,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => selectedDay = d),
                            borderRadius: BorderRadius.circular(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AdminUI.indigo : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$d',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : (hasEvent ? AdminUI.indigo : AdminUI.textPrimary),
                                    ),
                                  ),
                                ),
                                if (groupsForDots.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: groupsForDots
                                          .map(
                                            (g) => Container(
                                              width: 5,
                                              height: 5,
                                              margin: const EdgeInsets.symmetric(horizontal: 1),
                                              decoration: BoxDecoration(
                                                color: _groupColor[g] ?? AdminUI.indigo,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AdminUI.border.withOpacity(0.8),
                                                  width: 0.4,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: _groupTypes
                      .map(
                        (g) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _groupColor[g],
                                shape: BoxShape.circle,
                                border: Border.all(color: AdminUI.border, width: 0.5),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _groupLabel[g] ?? g,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AdminUI.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_events.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No events yet. Tap "Create a sched" to add an event to the calendar.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminUI.textTertiary),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ..._events.map((e) {
              final dateStr = _dateStr(e);
              final groups = _groupsFromRow(e);
              final leadColor = _groupColor[groups.first] ?? AdminUI.amber;
              final amin = e['age_range_min'];
              final amax = e['age_range_max'];
              final int? ageMin = amin is int ? amin : int.tryParse(amin?.toString() ?? '');
              final int? ageMax = amax is int ? amax : int.tryParse(amax?.toString() ?? '');
              String? ageLine;
              if (ageMin != null || ageMax != null) {
                if (ageMin != null && ageMax != null) {
                  ageLine = 'Tiyak na edad: $ageMin–$ageMax taong gulang';
                } else if (ageMin != null) {
                  ageLine = 'Tiyak na edad: $ageMin+ taong gulang';
                } else {
                  ageLine = 'Tiyak na edad: hanggang $ageMax taong gulang';
                }
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AdminCard(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AdminUI.radiusLg),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(width: 4, color: leadColor),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: groups
                                              .map(
                                                (g) => Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: (_groupColor[g] ?? AdminUI.amber).withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    _groupLabel[g] ?? g,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: _groupColor[g] ?? AdminUI.amber,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                      IconButton(icon: Icon(Icons.edit_outlined, size: 18, color: AdminUI.textTertiary), onPressed: () => _showAddOrEditEvent(context, existing: e), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                                      IconButton(icon: Icon(Icons.delete_outline, size: 18, color: AdminUI.red), onPressed: () => _confirmDelete(context, e), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32)),
                                    ],
                                  ),
                                  if (ageLine != null) ...[
                                    const SizedBox(height: 6),
                                    Text(ageLine, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminUI.textSecondary, fontWeight: FontWeight.w600)),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(e['title'] as String? ?? 'Event', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AdminUI.textPrimary)),
                                  if (e['description'] != null && (e['description'] as String).isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(e['description'] as String, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminUI.textSecondary)),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_outlined, size: 14, color: AdminUI.textTertiary),
                                      const SizedBox(width: 6),
                                      Text(dateStr, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminUI.textSecondary)),
                                      if (e['start_time'] != null && (e['start_time'] as String).isNotEmpty) ...[
                                        const SizedBox(width: 12),
                                        Icon(Icons.schedule_outlined, size: 14, color: AdminUI.textTertiary),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatTimeRangeFromDb(e['start_time'] as String, e['end_time'] as String?),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminUI.textSecondary),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (e['facility'] != null && (e['facility'] as String).isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 14, color: AdminUI.textTertiary),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text(e['facility'] as String, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminUI.textSecondary))),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _showAddOrEditEvent(BuildContext context, {Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    DateTime eventDate;
    if (existing != null) {
      final d = existing['event_date'];
      if (d is String) {
        final parts = d.split('T').first.split('-');
        if (parts.length == 3) eventDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        else eventDate = DateTime.now();
      } else {
        eventDate = DateTime.now();
      }
    } else {
      eventDate = _month;
    }
    final titleCtrl = TextEditingController(text: existing?['title'] as String? ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] as String? ?? '');
    final facilityCtrl = TextEditingController(text: existing?['facility'] as String? ?? '');
    bool sendAnnouncement = existing?['send_announcement'] as bool? ?? false;
    final announcementTitleCtrl = TextEditingController(
      text: existing?['announcement_title'] as String? ?? '',
    );
    final announcementBodyCtrl = TextEditingController(
      text: existing?['announcement_body'] as String? ?? '',
    );
    final ageMinCtrl = TextEditingController(
      text: existing != null && existing['age_range_min'] != null ? '${existing['age_range_min']}' : '',
    );
    final ageMaxCtrl = TextEditingController(
      text: existing != null && existing['age_range_max'] != null ? '${existing['age_range_max']}' : '',
    );
    final selectedGroups =
        existing != null ? _groupsFromRow(existing).toSet() : <String>{'adult'};
    if (selectedGroups.isEmpty) selectedGroups.add('adult');

    // Parse existing start_time and end_time (e.g. "09:00:00" from DB).
    TimeOfDay eventStartTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay eventEndTime = const TimeOfDay(hour: 9, minute: 0);
    final startTimeRaw = existing?['start_time'];
    if (startTimeRaw != null && startTimeRaw is String) {
      final parts = startTimeRaw.split(':');
      if (parts.isNotEmpty) {
        final h = int.tryParse(parts[0]);
        final m = parts.length > 1 ? int.tryParse(parts[1]) : 0;
        if (h != null && h >= 0 && h < 24) {
          eventStartTime = TimeOfDay(hour: h, minute: m ?? 0);
        }
      }
    }
    final endTimeRaw = existing?['end_time'];
    if (endTimeRaw != null && endTimeRaw is String) {
      final parts = endTimeRaw.split(':');
      if (parts.isNotEmpty) {
        final h = int.tryParse(parts[0]);
        final m = parts.length > 1 ? int.tryParse(parts[1]) : 0;
        if (h != null && h >= 0 && h < 24) {
          eventEndTime = TimeOfDay(hour: h, minute: m ?? 0);
        }
      }
    }

    // Load service names from primary_care_services for the title dropdown.
    List<String> serviceNames = [];
    try {
      final svcRes = await SupabaseService.client
          .from('primary_care_services')
          .select('name')
          .order('name', ascending: true);
      final svcList = List<Map<String, dynamic>>.from(svcRes as List);
      serviceNames = svcList
          .map((row) => row['name'] as String?)
          .whereType<String>()
          .map((n) => n.trim())
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
    } catch (_) {
      // If loading services fails, we silently fall back to free-text title.
      serviceNames = [];
    }
    String? selectedTitle = existing?['title'] as String?;
    if (serviceNames.isNotEmpty) {
      if (selectedTitle != null && selectedTitle.trim().isNotEmpty && !serviceNames.contains(selectedTitle)) {
        serviceNames = [selectedTitle, ...serviceNames];
      }
      selectedTitle ??= serviceNames.isNotEmpty ? serviceNames.first : null;
    }

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: AdminUI.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminUI.radiusMd)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminUI.radiusMd), borderSide: const BorderSide(color: AdminUI.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AdminUI.radiusMd), borderSide: const BorderSide(color: AdminUI.indigo, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final dialogMaxW = min(MediaQuery.sizeOf(ctx).width - 28, 560.0);
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
            title: Text(isEdit ? 'Edit event' : 'Create a sched'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: min(dialogMaxW, 400.0), maxWidth: dialogMaxW),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
                      subtitle: Text('${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}'),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(context: ctx, initialDate: eventDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (picked != null) setDialogState(() => eventDate = picked);
                        },
                        child: const Text('Change'),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Time range'),
                      subtitle: Text('${_formatTimeOfDay(eventStartTime)} – ${_formatTimeOfDay(eventEndTime)}'),
                      trailing: TextButton(
                        onPressed: () async {
                          final start = await showTimePicker(context: ctx, initialTime: eventStartTime);
                          if (start != null) setDialogState(() => eventStartTime = start);
                        },
                        child: const Text('Start'),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('End time'),
                      subtitle: Text(_formatTimeOfDay(eventEndTime)),
                      trailing: TextButton(
                        onPressed: () async {
                          final end = await showTimePicker(context: ctx, initialTime: eventEndTime);
                          if (end != null) setDialogState(() => eventEndTime = end);
                        },
                        child: const Text('Change'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Grupo (marami ang puwede)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AdminUI.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Piliin ang target na edad/grupo; may kasamang karaniwang saklaw ng edad.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminUI.textTertiary, fontSize: 11),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: dialogMaxW,
                      child: Column(
                        children: [
                          for (int i = 0; i < _groupTypes.length; i += 2)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _GroupFilterChip(
                                      groupKey: _groupTypes[i],
                                      isSelected: selectedGroups.contains(_groupTypes[i]),
                                      onChanged: (v) {
                                        setDialogState(() {
                                          if (v) {
                                            selectedGroups.add(_groupTypes[i]);
                                          } else if (selectedGroups.length > 1) {
                                            selectedGroups.remove(_groupTypes[i]);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (i + 1 < _groupTypes.length)
                                    Expanded(
                                      child: _GroupFilterChip(
                                        groupKey: _groupTypes[i + 1],
                                        isSelected: selectedGroups.contains(_groupTypes[i + 1]),
                                        onChanged: (v) {
                                          setDialogState(() {
                                            if (v) {
                                              selectedGroups.add(_groupTypes[i + 1]);
                                            } else if (selectedGroups.length > 1) {
                                              selectedGroups.remove(_groupTypes[i + 1]);
                                            }
                                          });
                                        },
                                      ),
                                    )
                                  else
                                    const Spacer(),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Tiyak na edad (opsyonal)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AdminUI.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kung may limitasyon (hal. 5–12 lang), ilagay dito. Iwanang blangko kung sakop ang buong grupo.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminUI.textTertiary, fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ageMinCtrl,
                            keyboardType: TextInputType.number,
                            decoration: inputDecoration.copyWith(
                              labelText: 'Mula (taong gulang)',
                              hintText: 'hal. 5',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: ageMaxCtrl,
                            keyboardType: TextInputType.number,
                            decoration: inputDecoration.copyWith(
                              labelText: 'Hanggang (taong gulang)',
                              hintText: 'hal. 12',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (serviceNames.isEmpty)
                      TextField(
                        controller: titleCtrl,
                        decoration: inputDecoration.copyWith(labelText: 'Title', hintText: 'e.g. Free Blood Pressure Screening'),
                        textCapitalization: TextCapitalization.words,
                      )
                    else
                      GestureDetector(
                        onTap: () async {
                          final picked = await showModalBottomSheet<String>(
                            context: ctx,
                            isScrollControlled: true,
                            backgroundColor: AdminUI.surface,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (sheetCtx) {
                              List<String> filtered = List.from(serviceNames);
                              return StatefulBuilder(
                                builder: (sheetCtx, setSheetState) {
                                  void applyFilter(String value) {
                                    final q = value.toLowerCase().trim();
                                    filtered = q.isEmpty
                                        ? List.from(serviceNames)
                                        : serviceNames
                                            .where((name) => name.toLowerCase().contains(q))
                                            .toList();
                                    setSheetState(() {});
                                  }

                                  return SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Select service',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: AdminUI.textPrimary,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close, size: 20),
                                                onPressed: () => Navigator.of(sheetCtx).pop(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          TextField(
                                            autofocus: true,
                                            decoration: const InputDecoration(
                                              prefixIcon: Icon(Icons.search),
                                              hintText: 'Search services',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(12)),
                                              ),
                                            ),
                                            onChanged: applyFilter,
                                          ),
                                          const SizedBox(height: 12),
                                          Flexible(
                                            child: filtered.isEmpty
                                                ? const Center(
                                                    child: Padding(
                                                      padding: EdgeInsets.all(16),
                                                      child: Text(
                                                        'No services found.',
                                                        style: TextStyle(color: AdminUI.textTertiary),
                                                      ),
                                                    ),
                                                  )
                                                : ListView.separated(
                                                    shrinkWrap: true,
                                                    itemCount: filtered.length,
                                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                                    itemBuilder: (ctx2, index) {
                                                      final name = filtered[index];
                                                      final selected = name == selectedTitle;
                                                      return ListTile(
                                                        title: Text(name),
                                                        trailing: selected
                                                            ? const Icon(Icons.check, color: AdminUI.indigo, size: 18)
                                                            : null,
                                                        onTap: () => Navigator.of(sheetCtx).pop(name),
                                                      );
                                                    },
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                          if (picked != null) {
                            setDialogState(() => selectedTitle = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: inputDecoration.copyWith(labelText: 'Service'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  (selectedTitle ?? 'Select service'),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: selectedTitle == null ? AdminUI.textTertiary : AdminUI.textPrimary,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: AdminUI.textTertiary),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descCtrl,
                      decoration: inputDecoration.copyWith(labelText: 'Description (optional)', hintText: 'Short description'),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: facilityCtrl,
                      decoration: inputDecoration.copyWith(
                        labelText: 'Facility (optional)',
                        hintText: 'e.g. RHU Main, Barangay Health Station',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Send announcement'),
                      subtitle: const Text(
                        'Shows a notification to users about this new event (bell icon / Announcement tab).',
                      ),
                      trailing: Switch(
                        value: sendAnnouncement,
                        onChanged: (v) {
                          setDialogState(() => sendAnnouncement = v);
                        },
                      ),
                    ),
                    if (sendAnnouncement) ...[
                      const SizedBox(height: 4),
                      TextField(
                        controller: announcementTitleCtrl,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Announcement title',
                          hintText: 'e.g. New RHU schedule posted',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: announcementBodyCtrl,
                        decoration: inputDecoration.copyWith(
                          labelText: 'Announcement message',
                          hintText: 'e.g. Please check the schedule details and book if applicable.',
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  final title = serviceNames.isNotEmpty
                      ? (selectedTitle ?? '').trim()
                      : titleCtrl.text.trim();
                  if (title.isEmpty) return;
                  if (selectedGroups.isEmpty) return;
                  final orderedGroups = _groupTypes.where((t) => selectedGroups.contains(t)).toList();
                  int? amin;
                  int? amax;
                  final minS = ageMinCtrl.text.trim();
                  final maxS = ageMaxCtrl.text.trim();
                  if (minS.isNotEmpty) amin = int.tryParse(minS);
                  if (maxS.isNotEmpty) amax = int.tryParse(maxS);
                  if (amin != null && amax != null && amin > amax) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ang "mula" ay hindi dapat mas mataas sa "hanggang".')),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop(<String, dynamic>{
                    'event_date': '${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}',
                    'start_time': '${eventStartTime.hour.toString().padLeft(2, '0')}:${eventStartTime.minute.toString().padLeft(2, '0')}:00',
                    'end_time': '${eventEndTime.hour.toString().padLeft(2, '0')}:${eventEndTime.minute.toString().padLeft(2, '0')}:00',
                    'group_types': orderedGroups,
                    'age_range_min': amin,
                    'age_range_max': amax,
                    'title': title,
                    'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    'facility': facilityCtrl.text.trim().isEmpty ? null : facilityCtrl.text.trim(),
                    'send_announcement': sendAnnouncement,
                    'announcement_title': announcementTitleCtrl.text.trim().isEmpty ? null : announcementTitleCtrl.text.trim(),
                    'announcement_body': announcementBodyCtrl.text.trim().isEmpty ? null : announcementBodyCtrl.text.trim(),
                  });
                },
                child: Text(isEdit ? 'Save' : 'Create'),
              ),
            ],
          );
        },
      ),
    );
    if (result == null || !mounted) return;
    try {
      if (isEdit) {
        await SupabaseService.client.from('calendar_events').update({
          'event_date': result['event_date'],
          'start_time': result['start_time'],
          'end_time': result['end_time'],
          'group_types': result['group_types'],
          'age_range_min': result['age_range_min'],
          'age_range_max': result['age_range_max'],
          'title': result['title'],
          'description': result['description'],
          'facility': result['facility'],
          'send_announcement': result['send_announcement'] ?? false,
          'announcement_title': result['announcement_title'],
          'announcement_body': result['announcement_body'],
        }).eq('id', existing['id']);
      } else {
        await SupabaseService.client.from('calendar_events').insert({
          'event_date': result['event_date'],
          'start_time': result['start_time'],
          'end_time': result['end_time'],
          'group_types': result['group_types'],
          'age_range_min': result['age_range_min'],
          'age_range_max': result['age_range_max'],
          'title': result['title'],
          'description': result['description'],
          'facility': result['facility'],
          'send_announcement': result['send_announcement'] ?? false,
          'announcement_title': result['announcement_title'],
          'announcement_body': result['announcement_body'],
        });
      }
      if (!mounted) return;
      _loadEvents();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _confirmDelete(BuildContext context, Map<String, dynamic> e) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('Remove "${e['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AdminUI.red), onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await SupabaseService.client.from('calendar_events').delete().eq('id', e['id']);
      _loadEvents();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $err')));
    }
  }

  static String _monthMonthName(DateTime d) {
    const m = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return m[d.month - 1];
  }

  static String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour;
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final minute = t.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }

  static String _formatTimeFromDb(String dbTime) {
    final parts = dbTime.split(':');
    if (parts.isEmpty) return dbTime;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour:${m.toString().padLeft(2, '0')} $period';
  }

  static String _formatTimeRangeFromDb(String startDb, String? endDb) {
    final start = _formatTimeFromDb(startDb);
    if (endDb == null || endDb.trim().isEmpty) return start;
    return '$start – ${_formatTimeFromDb(endDb)}';
  }
}
