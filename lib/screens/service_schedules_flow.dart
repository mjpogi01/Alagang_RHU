import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

const List<String> _tagalogMonths = [
  'Enero', 'Pebrero', 'Marso', 'Abril', 'Mayo', 'Hunyo',
  'Hulyo', 'Agosto', 'Setyembre', 'Oktubre', 'Nobyembre', 'Disyembre',
];

const Map<String, String> _groupLabel = {
  'buntis': 'Buntis',
  'bata': 'Bata',
  'adolescent': 'Kabataan',
  'adult': 'Nasa hustong gulang',
  'elderly': 'Nakatatanda',
};

String _formatDate(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final s = raw.split('T').first;
  final parts = s.split('-');
  if (parts.length != 3) return s;
  final y = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 1;
  final d = int.tryParse(parts[2]) ?? 1;
  if (m < 1 || m > 12) return s;
  return '${_tagalogMonths[m - 1]} $d, $y';
}

String _formatTimeRange(String? start, String? end) {
  String one(String? t) {
    if (t == null || t.trim().isEmpty) return '';
    final parts = t.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:${m.toString().padLeft(2, '0')} $period';
  }

  final a = one(start);
  final b = one(end);
  if (a.isEmpty && b.isEmpty) return 'Walang itinakdang oras';
  if (b.isEmpty) return a;
  if (a.isEmpty) return b;
  return '$a – $b';
}

List<String> _groupTypesFromRow(Map<String, dynamic> row) {
  final gt = row['group_types'];
  if (gt is List && gt.isNotEmpty) {
    return gt.map((e) => e.toString()).where((s) => _groupLabel.containsKey(s)).toList();
  }
  final g = row['group_type'] as String?;
  if (g != null && _groupLabel.containsKey(g)) return [g];
  return [];
}

String? _eventDateKey(Map<String, dynamic> event) {
  final raw = event['event_date']?.toString().split('T').first;
  if (raw == null || raw.isEmpty) return null;
  return raw;
}

DateTime _timeOnDay(DateTime day, String? timeStr) {
  if (timeStr == null || timeStr.trim().isEmpty) {
    return DateTime(day.year, day.month, day.day, 23, 59, 59);
  }
  final p = timeStr.split(':');
  final h = int.tryParse(p[0]) ?? 0;
  final m = p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0;
  return DateTime(day.year, day.month, day.day, h, m);
}

/// True if the schedule has not ended yet (user can still book).
bool isScheduleStillUpcoming(Map<String, dynamic> event) {
  final key = _eventDateKey(event);
  if (key == null) return false;
  final parts = key.split('-');
  if (parts.length != 3) return false;
  final day = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final eventDayStart = DateTime(day.year, day.month, day.day);
  if (eventDayStart.isBefore(todayStart)) return false;
  if (eventDayStart.isAfter(todayStart)) return true;
  final endT = event['end_time']?.toString();
  final startT = event['start_time']?.toString();
  late final DateTime cutoff;
  if (endT != null && endT.trim().isNotEmpty) {
    cutoff = _timeOnDay(day, endT);
  } else if (startT != null && startT.trim().isNotEmpty) {
    cutoff = _timeOnDay(day, startT).add(const Duration(hours: 1));
  } else {
    cutoff = DateTime(day.year, day.month, day.day, 23, 59, 59);
  }
  return now.isBefore(cutoff);
}

String _appointmentMarker(Map<String, dynamic> event) {
  final id = event['id']?.toString();
  if (id != null && id.isNotEmpty) return 'rhu_cal:$id';
  final key = _eventDateKey(event) ?? '';
  final title = (event['title'] as String?)?.trim() ?? '';
  return 'rhu_cal:${key}_$title';
}

/// Unique per schedule + family member (or self) for duplicate booking check.
String _bookingFingerprint(String eventId, String? familyMemberId) {
  return 'rhu_book:$eventId:${familyMemberId ?? 'self'}';
}

int _ageFromDob(DateTime dob) {
  final now = DateTime.now();
  var a = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) a--;
  return a;
}

String _sexLabelDb(String? sex) {
  switch (sex) {
    case 'female':
      return 'Babae';
    case 'male':
      return 'Lalaki';
    default:
      return 'Iba pa';
  }
}

bool _personMatchesGroup(String group, int age, String sex, bool? pregnant) {
  switch (group) {
    case 'buntis':
      return sex == 'female' && pregnant == true;
    case 'bata':
      return age >= 0 && age <= 9;
    case 'adolescent':
      return age >= 10 && age <= 19;
    case 'adult':
      return age >= 20 && age <= 59;
    case 'elderly':
      return age >= 60;
    default:
      return false;
  }
}

List<String> _audienceGroupsForEvent(Map<String, dynamic> event) {
  var g = _groupTypesFromRow(event);
  if (g.isEmpty) {
    final one = event['group_type'] as String?;
    if (one != null && _groupLabel.containsKey(one)) g = [one];
  }
  if (g.isEmpty) g = ['adult'];
  return g;
}

bool _isEligibleForEvent(Map<String, dynamic> event, int age, String sex, bool? pregnant) {
  final groups = _audienceGroupsForEvent(event);
  if (!groups.any((gr) => _personMatchesGroup(gr, age, sex, pregnant))) return false;
  final amin = event['age_range_min'];
  final amax = event['age_range_max'];
  final int? minA = amin is int ? amin : int.tryParse(amin?.toString() ?? '');
  final int? maxA = amax is int ? amax : int.tryParse(amax?.toString() ?? '');
  if (minA != null && age < minA) return false;
  if (maxA != null && age > maxA) return false;
  return true;
}

class _BookablePerson {
  const _BookablePerson({
    required this.familyMemberId,
    required this.displayLabel,
    required this.subtitle,
    required this.age,
    required this.sex,
    this.pregnancyStatus,
    this.isAccountHolderRow = false,
  });

  /// null = account holder not in family_members (profile only)
  final String? familyMemberId;
  final String displayLabel;
  final String subtitle;
  final int age;
  final String sex;
  final bool? pregnancyStatus;
  final bool isAccountHolderRow;
}

Future<String?> _ensureFamilyIdForUser(String uid) async {
  final client = SupabaseService.client;
  String? familyId;

  try {
    final mem = await client
        .from('family_members')
        .select('family_id')
        .eq('user_id', uid)
        .maybeSingle();
    if (mem != null && mem['family_id'] != null) {
      familyId = mem['family_id'] as String;
    }
  } catch (_) {}

  if (familyId == null) {
    try {
      final fam = await client
          .from('families')
          .select('id')
          .eq('decision_maker_user_id', uid)
          .maybeSingle();
      familyId = fam?['id'] as String?;
    } catch (_) {}
  }

  if (familyId == null) {
    try {
      final createdId =
          await client.rpc('create_my_family', params: {'family_name': null});
      if (createdId is String) {
        familyId = createdId;
      } else if (createdId != null) {
        familyId = createdId.toString();
      }
    } catch (_) {}
  }

  return familyId;
}

Future<List<_BookablePerson>> _loadBookablePeople(String uid) async {
  final client = SupabaseService.client;
  final List<_BookablePerson> out = [];
  final familyId = await _ensureFamilyIdForUser(uid);

  var hasLinkedSelf = false;
  if (familyId != null) {
    try {
      final res = await client.from('family_members').select().eq('family_id', familyId);
      final rows = List<Map<String, dynamic>>.from(res as List);
      rows.sort((a, b) {
        final na = (a['name'] as String?) ?? '';
        final nb = (b['name'] as String?) ?? '';
        return na.toLowerCase().compareTo(nb.toLowerCase());
      });
      for (final r in rows) {
        final mid = r['id'] as String?;
        if (mid == null) continue;
        final dobRaw = r['date_of_birth']?.toString().split('T').first;
        final dob = dobRaw != null ? DateTime.tryParse(dobRaw) : null;
        if (dob == null) continue;
        final age = _ageFromDob(dob);
        final sex = (r['sex'] as String?) ?? 'other';
        final preg = r['pregnancy_status'] as bool?;
        final nm = (r['name'] as String?)?.trim();
        final name = nm != null && nm.isNotEmpty ? nm : 'Miyembro';
        final linked = r['user_id'] == uid;
        if (linked) hasLinkedSelf = true;
        out.add(_BookablePerson(
          familyMemberId: mid,
          displayLabel: linked ? 'Ako ($name)' : name,
          subtitle: '$age taong gulang · ${_sexLabelDb(sex)}',
          age: age,
          sex: sex,
          pregnancyStatus: preg,
          isAccountHolderRow: linked,
        ));
      }
    } catch (_) {}
  }

  if (!hasLinkedSelf) {
    try {
      final prof = await client.from('profiles').select('full_name, age, sex, birth_date').eq('user_id', uid).maybeSingle();
      if (prof != null) {
        var age = (prof['age'] as int?) ?? 25;
        final bd = prof['birth_date']?.toString().split('T').first;
        if (bd != null) {
          final d = DateTime.tryParse(bd);
          if (d != null) age = _ageFromDob(d);
        }
        final name = (prof['full_name'] as String?)?.trim();
        final label = name != null && name.isNotEmpty ? 'Ako ($name)' : 'Ako';
        final sex = (prof['sex'] as String?) ?? 'other';
        out.insert(
          0,
          _BookablePerson(
            familyMemberId: null,
            displayLabel: label,
            subtitle: '$age taong gulang · ${_sexLabelDb(sex)} (iyong profile)',
            age: age,
            sex: sex,
            pregnancyStatus: null,
            isAccountHolderRow: true,
          ),
        );
      }
    } catch (_) {}
  }

  return out;
}

/// Opens bottom sheet: service info + matching calendar schedules; tap sched for full details.
Future<void> showServiceSchedulesFlow(
  BuildContext context, {
  required String serviceName,
  String? description,
  required bool isFree,
  required String priceLabel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ServiceSchedulesSheet(
      serviceName: serviceName,
      description: description,
      isFree: isFree,
      priceLabel: priceLabel,
    ),
  );
}

/// Opens the full schedule detail (time, facility, description) including booking.
Future<void> showScheduleDetailForBooking(
  BuildContext context, {
  required Map<String, dynamic> event,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ScheduleDetailSheet(event: event),
  );
}

class _ServiceSchedulesSheet extends StatefulWidget {
  const _ServiceSchedulesSheet({
    required this.serviceName,
    this.description,
    required this.isFree,
    required this.priceLabel,
  });

  final String serviceName;
  final String? description;
  final bool isFree;
  final String priceLabel;

  @override
  State<_ServiceSchedulesSheet> createState() => _ServiceSchedulesSheetState();
}

class _ServiceSchedulesSheetState extends State<_ServiceSchedulesSheet> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await SupabaseService.client
          .from('calendar_events')
          .select(
              'id, event_date, title, description, start_time, end_time, facility, group_types, group_type, age_range_min, age_range_max')
          .order('event_date', ascending: true);
      final list = List<Map<String, dynamic>>.from(res as List);
      final norm = widget.serviceName.trim().toLowerCase();
      final matched = list.where((r) {
        final t = (r['title'] as String?)?.trim().toLowerCase() ?? '';
        return t == norm;
      }).toList();
      final today = DateTime.now();
      final todayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      int key(String? d) {
        if (d == null) return 0;
        return d.split('T').first.compareTo(todayKey);
      }

      matched.sort((a, b) {
        final da = (a['event_date'] as String?)?.split('T').first ?? '';
        final db = (b['event_date'] as String?)?.split('T').first ?? '';
        final fa = key(a['event_date']?.toString());
        final fb = key(b['event_date']?.toString());
        if (fa >= 0 && fb < 0) return -1;
        if (fa < 0 && fb >= 0) return 1;
        if (fa >= 0 && fb >= 0) return da.compareTo(db);
        return db.compareTo(da);
      });
      if (!mounted) return;
      setState(() {
        _events = matched;
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

  void _openScheduleDetail(Map<String, dynamic> e) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ScheduleDetailSheet(event: e),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
                  children: [
                    Text(
                      widget.serviceName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.isFree
                            ? AppTheme.accentTeal.withValues(alpha: 0.15)
                            : AppTheme.textTertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.priceLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: widget.isFree ? AppTheme.accentTeal : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    if (widget.description != null && widget.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Detalye ng serbisyo',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.description!.trim(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.event_available_outlined,
                            size: 22, color: AppTheme.primaryBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Mga iskedyul',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mga petsa at oras kung kailan nakaiskedyul ang serbisyong ito.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      )
                    else if (_events.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Walang nakaiskedyul na kaganapan para sa serbisyong ito. Tingnan ang Kalendaryo para sa iba pang petsa.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                                height: 1.35,
                              ),
                        ),
                      )
                    else
                      ..._events.map((e) {
                        final dateStr = _formatDate(e['event_date']?.toString());
                        final timeStr = _formatTimeRange(
                          e['start_time']?.toString(),
                          e['end_time']?.toString(),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: AppTheme.bannerLight,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: () => _openScheduleDetail(e),
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.calendar_today_outlined,
                                          size: 22, color: AppTheme.primaryBlue),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            dateStr.isEmpty ? 'Petsa' : dateStr,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: AppTheme.textPrimary,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.schedule_outlined,
                                                  size: 16, color: AppTheme.textSecondary),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  timeStr,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: AppTheme.textSecondary,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right,
                                        color: AppTheme.textTertiary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Isara'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScheduleDetailSheet extends StatefulWidget {
  const _ScheduleDetailSheet({required this.event});

  final Map<String, dynamic> event;

  @override
  State<_ScheduleDetailSheet> createState() => _ScheduleDetailSheetState();
}

String _eventBookingId(Map<String, dynamic> event) {
  final id = event['id']?.toString();
  if (id != null && id.isNotEmpty) return id;
  return '${_eventDateKey(event) ?? ''}_${(event['title'] as String?) ?? ''}';
}

class _ScheduleDetailSheetState extends State<_ScheduleDetailSheet> {
  bool _booking = false;
  bool _loadingMembers = false;

  Future<void> _startBookFlow() async {
    final client = SupabaseService.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mag-sign in muna para makapag-book ng appointment.')),
        );
      }
      return;
    }
    setState(() => _loadingMembers = true);
    try {
      final all = await _loadBookablePeople(uid);
      final eligible = all
          .where((p) => _isEligibleForEvent(widget.event, p.age, p.sex, p.pregnancyStatus))
          .toList();
      if (!mounted) return;
      setState(() => _loadingMembers = false);
      if (eligible.isEmpty) {
        final g = _audienceGroupsForEvent(widget.event);
        final labels = g.map((x) => _groupLabel[x] ?? x).join(', ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Walang miyembro na angkop sa iskedyul na ito (Para sa: $labels). '
              'Siguraduhing tama ang edad at impormasyon sa Mga Miyembro ng Pamilya.',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }
      final chosen = await showModalBottomSheet<_BookablePerson>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _MemberPickerSheet(
          people: eligible,
          audienceLabels: _audienceGroupsForEvent(widget.event)
              .map((x) => _groupLabel[x] ?? x)
              .toList(),
          event: widget.event,
          userId: uid,
        ),
      );
      if (chosen != null && mounted) await _bookAppointment(chosen);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hindi ma-load ang pamilya: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  Future<void> _bookAppointment(_BookablePerson person) async {
    final event = widget.event;
    final client = SupabaseService.client;
    final uid = client.auth.currentUser!.id;
    final dateRaw = _eventDateKey(event);
    if (dateRaw == null) return;
    final eid = _eventBookingId(event);
    final fp = _bookingFingerprint(eid, person.familyMemberId);
    final marker = _appointmentMarker(event);
    setState(() => _booking = true);
    try {
      final dup = await client
          .from('appointments')
          .select('id')
          .eq('user_id', uid)
          .ilike('description', '%$fp%');
      final dupList = List<Map<String, dynamic>>.from(dup as List);
      if (dupList.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Naka-book na si ${person.displayLabel} para sa iskedyul na ito.',
              ),
            ),
          );
        }
        return;
      }
      final title = (event['title'] as String?)?.trim() ?? 'Appointment';
      final timeStr = _formatTimeRange(
        event['start_time']?.toString(),
        event['end_time']?.toString(),
      );
      final facility = (event['facility'] as String?)?.trim();
      final desc = (event['description'] as String?)?.trim();
      final buf = StringBuffer()
        ..writeln(fp)
        ..writeln(marker)
        ..writeln('Para kay: ${person.displayLabel}')
        ..writeln('Oras: $timeStr');
      if (facility != null && facility.isNotEmpty) {
        buf.writeln('Lokasyon: $facility');
      }
      if (desc != null && desc.isNotEmpty) {
        buf.writeln(desc);
      }
      final inserted = await client.from('appointments').insert({
        'user_id': uid,
        'family_member_id': person.familyMemberId,
        'event_date': dateRaw,
        'title': title,
        'description': buf.toString().trim(),
        'status': 'scheduled',
      }).select('id').single();

      final appointmentId = inserted['id']?.toString();
      if (appointmentId != null && appointmentId.isNotEmpty) {
        // Schedule local reminders (1 week / 1 day / 1 hour before).
        try {
          // dateRaw is stored as date string; event has start_time.
          final dateKey = dateRaw.toString().split('T').first;
          final day = DateTime.tryParse(dateKey);
          final startRaw = event['start_time']?.toString();
          if (day != null && startRaw != null && startRaw.isNotEmpty) {
            final parts = startRaw.split(':');
            final h = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
            final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
            final scheduleStart = DateTime(day.year, day.month, day.day, h, m);

            String bodyForAppointment() {
              final dateStr =
                  '${scheduleStart.year}-${scheduleStart.month.toString().padLeft(2, '0')}-${scheduleStart.day.toString().padLeft(2, '0')}';
              final hour12 = scheduleStart.hour == 0
                  ? 12
                  : (scheduleStart.hour > 12 ? scheduleStart.hour - 12 : scheduleStart.hour);
              final minute = scheduleStart.minute.toString().padLeft(2, '0');
              final period = scheduleStart.hour >= 12 ? 'PM' : 'AM';
              final facilityStr =
                  (facility != null && facility.isNotEmpty) ? ' sa $facility' : '';
              return '${person.displayLabel} ay may appointment: $title$facilityStr sa $dateStr, $hour12:$minute $period.';
            }

            final body = bodyForAppointment();
            await NotificationService.scheduleAppointmentReminder(
              appointmentId: appointmentId,
              scheduledAt: scheduleStart.subtract(const Duration(days: 7)),
              title: 'Paalala: Appointment',
              body: body,
              reminderKey: 'lead_7d',
            );
            await NotificationService.scheduleAppointmentReminder(
              appointmentId: appointmentId,
              scheduledAt: scheduleStart.subtract(const Duration(days: 1)),
              title: 'Paalala: Appointment',
              body: body,
              reminderKey: 'lead_1d',
            );
            await NotificationService.scheduleAppointmentReminder(
              appointmentId: appointmentId,
              scheduledAt: scheduleStart.subtract(const Duration(hours: 1)),
              title: 'Paalala: Appointment',
              body: body,
              reminderKey: 'lead_1h',
            );
          }
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Naidagdag ang appointment kay ${person.displayLabel}.',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hindi na-save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final bottom = MediaQuery.of(context).padding.bottom;
    final dateStr = _formatDate(event['event_date']?.toString());
    final timeStr = _formatTimeRange(
      event['start_time']?.toString(),
      event['end_time']?.toString(),
    );
    final facility = (event['facility'] as String?)?.trim();
    final desc = (event['description'] as String?)?.trim();
    final groups = _groupTypesFromRow(event);
    final amin = event['age_range_min'];
    final amax = event['age_range_max'];
    final int? ageMin = amin is int ? amin : int.tryParse(amin?.toString() ?? '');
    final int? ageMax = amax is int ? amax : int.tryParse(amax?.toString() ?? '');
    String? ageNote;
    if (ageMin != null || ageMax != null) {
      if (ageMin != null && ageMax != null) {
        ageNote = 'Tiyak na edad: $ageMin–$ageMax taong gulang';
      } else if (ageMin != null) {
        ageNote = 'Tiyak na edad: $ageMin taong gulang pataas';
      } else {
        ageNote = 'Tiyak na edad: hanggang $ageMax taong gulang';
      }
    }
    final canBook = isScheduleStillUpcoming(event);
    final loggedIn = SupabaseService.client.auth.currentUser != null;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                (event['title'] as String?) ?? 'Iskedyul',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
              _scheduleDetailRow(
                context,
                Icons.calendar_today_outlined,
                'Petsa',
                dateStr.isEmpty ? '—' : dateStr,
              ),
              const SizedBox(height: 12),
              _scheduleDetailRow(
                context,
                Icons.schedule_outlined,
                'Oras',
                timeStr,
              ),
              if (facility != null && facility.isNotEmpty) ...[
                const SizedBox(height: 12),
                _scheduleDetailRow(
                  context,
                  Icons.location_on_outlined,
                  'Pasilidad / lokasyon',
                  facility,
                ),
              ],
              if (groups.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Para sa',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textTertiary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: groups
                      .map(
                        (g) => Chip(
                          label: Text(_groupLabel[g] ?? g),
                          backgroundColor: AppTheme.accentTeal.withValues(alpha: 0.12),
                          side: BorderSide.none,
                          labelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (ageNote != null) ...[
                const SizedBox(height: 8),
                Text(
                  ageNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Deskripsyon',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                desc != null && desc.isNotEmpty
                    ? desc
                    : 'Walang karagdagang deskripsyon.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.45,
                    ),
              ),
              if (canBook) ...[
                const SizedBox(height: 20),
                if (!loggedIn)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Mag-sign in para maidagdag ito sa iyong kalendaryo bilang appointment.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                    ),
                  ),
                FilledButton(
                  onPressed: (_booking || _loadingMembers)
                      ? null
                      : () {
                          if (!loggedIn) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mag-sign in muna sa app para makapag-book.'),
                              ),
                            );
                            return;
                          }
                          _startBookFlow();
                        },
                  child: _loadingMembers
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Kinukuha ang miyembro...'),
                          ],
                        )
                      : _booking
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text('Sine-save...'),
                              ],
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_available_outlined, size: 22),
                                SizedBox(width: 8),
                                Text('Mag-book ng appointment'),
                              ],
                            ),
                ),
              ] else ...[
                const SizedBox(height: 16),
                Text(
                  'Natapos na ang iskedyul na ito — hindi na maaaring mag-book ng bagong appointment.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Isara'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _scheduleDetailRow(
  BuildContext context,
  IconData icon,
  String label,
  String value,
) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 22, color: AppTheme.primaryBlue),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _MemberPickerSheet extends StatefulWidget {
  const _MemberPickerSheet({
    required this.people,
    required this.audienceLabels,
    required this.event,
    required this.userId,
  });

  final List<_BookablePerson> people;
  final List<String> audienceLabels;
  final Map<String, dynamic> event;
  final String userId;

  @override
  State<_MemberPickerSheet> createState() => _MemberPickerSheetState();
}

class _MemberPickerSheetState extends State<_MemberPickerSheet> {
  int _selected = 0;
  bool _refreshing = false;
  late List<_BookablePerson> _people;

  @override
  void initState() {
    super.initState();
    _people = List<_BookablePerson>.from(widget.people);
  }

  Future<void> _refreshEligiblePeople({String? preferMemberId}) async {
    setState(() => _refreshing = true);
    try {
      final all = await _loadBookablePeople(widget.userId);
      final eligible = all
          .where((p) => _isEligibleForEvent(widget.event, p.age, p.sex, p.pregnancyStatus))
          .toList();
      if (!mounted) return;
      setState(() {
        _people = eligible;
        if (_people.isEmpty) {
          _selected = 0;
        } else if (preferMemberId != null) {
          final idx = _people.indexWhere((p) => p.familyMemberId == preferMemberId);
          _selected = idx >= 0 ? idx : 0;
        } else {
          _selected = _selected.clamp(0, _people.length - 1);
        }
      });
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _showAddMemberDialog() async {
    final nameCtrl = TextEditingController();
    DateTime dob = DateTime.now().subtract(const Duration(days: 365 * 20));
    String sex = 'female';
    bool? pregnant = null;

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setD) {
            return AlertDialog(
              title: const Text('Magdagdag ng miyembro'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pangalan (optional)',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Petsa ng kapanganakan'),
                      subtitle: Text(_formatDate(dob.toIso8601String())),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: dob,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setD(() => dob = picked);
                        },
                        child: const Text('Piliin'),
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: sex,
                      decoration: const InputDecoration(labelText: 'Kasarian'),
                      items: const [
                        DropdownMenuItem(value: 'female', child: Text('Babae')),
                        DropdownMenuItem(value: 'male', child: Text('Lalaki')),
                        DropdownMenuItem(value: 'other', child: Text('Iba pa')),
                      ],
                      onChanged: (v) {
                        setD(() {
                          sex = v ?? 'female';
                          if (sex != 'female') pregnant = null;
                        });
                      },
                    ),
                    if (sex == 'female') ...[
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Buntis'),
                        value: pregnant == true,
                        onChanged: (v) => setD(() => pregnant = v ? true : false),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    try {
      final familyId = await _ensureFamilyIdForUser(widget.userId);
      if (familyId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hindi makita ang pamilya.')),
          );
        }
        return;
      }
      final res = await SupabaseService.client
          .from('family_members')
          .insert({
            'family_id': familyId,
            'name': nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
            'date_of_birth': dob.toIso8601String(),
            'sex': sex,
            'pregnancy_status': sex == 'female' ? pregnant : null,
            'comorbidities': <String>[],
          })
          .select('id')
          .single();
      final newId = (res as Map)['id']?.toString();
      await _refreshEligiblePeople(preferMemberId: newId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hindi na-save ang miyembro: $e')),
        );
      }
    } finally {
      nameCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Para kanino ang appointment?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                ),
              ),
              TextButton(
                onPressed: _refreshing ? null : _showAddMemberDialog,
                child: const Text('Pamahalaan'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ipinapakita lamang ang mga miyembrong angkop sa edad/grupo ng iskedyul:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.audienceLabels
                .map(
                  (l) => Chip(
                    label: Text(l, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    backgroundColor: AppTheme.accentTeal.withValues(alpha: 0.12),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: _refreshing
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              shrinkWrap: true,
              itemCount: _people.length,
              itemBuilder: (context, i) {
                final p = _people[i];
                return RadioListTile<int>(
                  value: i,
                  groupValue: _selected,
                  onChanged: (v) => setState(() => _selected = v ?? 0),
                  title: Text(
                    p.displayLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(p.subtitle),
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kanselahin'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _people.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(_people[_selected]),
                  child: const Text('Ituloy'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
