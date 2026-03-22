import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'family_members_screen.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'service_schedules_flow.dart';

/// Status/age groups for health events; each has a color code on the calendar.
enum HealthEventGroup {
  buntis(AppTheme.buntisPink, 'Buntis'),
  bata(AppTheme.pediatricGreen, 'Bata (0–9 taong gulang)'),
  adolescent(AppTheme.adolescentBlue, 'Kabataan (10–19 taong gulang)'),
  adult(AppTheme.adultOrange, 'Nasa hustong gulang (20–59 taong gulang)'),
  elderly(AppTheme.elderlyPurple, 'Nakatatanda (60 pataas)');

  const HealthEventGroup(this.color, this.label);
  final Color color;
  final String label;
}

/// A health event on a specific date with details.
class CalendarHealthEvent {
  const CalendarHealthEvent({
    required this.group,
    required this.title,
    this.description,
    this.time,
    this.facility,
    /// Custom age range from admin (e.g. "Edad: 5–12 taong gulang"); shown once per sched.
    this.ageRangeNote,
    /// Supabase row id for admin events; used to dedupe upcoming list.
    this.calendarEventId,
    /// Short merged audience line for upcoming (e.g. "Buntis · Bata").
    this.audienceSummary,
  });

  final HealthEventGroup group;
  final String title;
  final String? description;
  /// Optional time string (e.g. "9:00 AM") from calendar_events.start_time.
  final String? time;
  /// Optional facility/location from calendar_events.facility.
  final String? facility;
  final String? ageRangeNote;
  final String? calendarEventId;
  final String? audienceSummary;
}

const List<String> _tagalogMonthNames = [
  'Enero',
  'Pebrero',
  'Marso',
  'Abril',
  'Mayo',
  'Hunyo',
  'Hulyo',
  'Agosto',
  'Setyembre',
  'Oktubre',
  'Nobyembre',
  'Disyembre',
];

const List<String> _tagalogMonthShortNames = [
  'Ene',
  'Peb',
  'Mar',
  'Abr',
  'May',
  'Hun',
  'Hul',
  'Ago',
  'Set',
  'Okt',
  'Nob',
  'Dis',
];

const List<String> _tagalogWeekdayLabels = [
  'LGO',
  'LUN',
  'MAR',
  'MIY',
  'HUW',
  'BIY',
  'SAB',
];

String _formatTagalogDate(DateTime day) {
  return '${_tagalogMonthNames[day.month - 1]} ${day.day}, ${day.year}';
}

String _weekdayLabelForDate(DateTime date) {
  return _tagalogWeekdayLabels[date.weekday % 7];
}

String _formatClockTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

String _formatTagalogDateTime(DateTime value) {
  return '${_tagalogMonthNames[value.month - 1]} ${value.day}, ${value.year} | ${_formatClockTime(value)}';
}

enum _FamilyCalendarTab { kalendaryo, miyembro, abiso }

enum _CalendarAudienceFilter { lahat, buntis, bata, kabataan, adult, elderly }

extension _CalendarAudienceFilterX on _CalendarAudienceFilter {
  String get label {
    switch (this) {
      case _CalendarAudienceFilter.lahat:
        return 'Lahat';
      case _CalendarAudienceFilter.buntis:
        return 'Buntis';
      case _CalendarAudienceFilter.bata:
        return 'Bata';
      case _CalendarAudienceFilter.kabataan:
        return 'Kabataan';
      case _CalendarAudienceFilter.adult:
        return 'Nasa hustong gulang';
      case _CalendarAudienceFilter.elderly:
        return 'Nakatatanda';
    }
  }

  HealthEventGroup? get group {
    switch (this) {
      case _CalendarAudienceFilter.lahat:
        return null;
      case _CalendarAudienceFilter.buntis:
        return HealthEventGroup.buntis;
      case _CalendarAudienceFilter.bata:
        return HealthEventGroup.bata;
      case _CalendarAudienceFilter.kabataan:
        return HealthEventGroup.adolescent;
      case _CalendarAudienceFilter.adult:
        return HealthEventGroup.adult;
      case _CalendarAudienceFilter.elderly:
        return HealthEventGroup.elderly;
    }
  }
}

enum _NoticeFilter { lahat, appointments, announcement }

enum _NoticeSource { appointmentReminder, adminEvent }

extension _NoticeFilterX on _NoticeFilter {
  String get label {
    switch (this) {
      case _NoticeFilter.lahat:
        return 'Lahat';
      case _NoticeFilter.appointments:
        return 'Appointments';
      case _NoticeFilter.announcement:
        return 'Announcement';
    }
  }

  Color get color {
    switch (this) {
      case _NoticeFilter.lahat:
        return AppTheme.primaryBlue;
      case _NoticeFilter.appointments:
        return AppTheme.adolescentBlue;
      case _NoticeFilter.announcement:
        return AppTheme.accentTeal;
    }
  }
}

class _UpcomingScheduleItem {
  const _UpcomingScheduleItem({
    required this.personName,
    required this.relationLabel,
    required this.title,
    required this.dateTime,
    required this.group,
    required this.statusLabel,
    required this.statusColor,
    required this.actionLabel,
  });

  final String personName;
  final String relationLabel;
  final String title;
  final DateTime dateTime;
  final HealthEventGroup group;
  final String statusLabel;
  final Color statusColor;
  final String actionLabel;
}

class _FamilyMemberOverview {
  const _FamilyMemberOverview({
    required this.name,
    required this.profileLabel,
    required this.detailLine,
    required this.group,
  });

  final String name;
  final String profileLabel;
  final String detailLine;
  final HealthEventGroup group;
}

class _AlertNoticeItem {
  const _AlertNoticeItem({
    required this.filter,
    required this.title,
    required this.description,
    required this.timeLabel,
    required this.icon,
    required this.accentColor,
    required this.actionLabel,
    required this.calendarEventId,
    required this.source,
    required this.appointmentId,
    required this.reminderType,
    required this.isRead,
    required this.scheduledAt,
  });

  final _NoticeFilter filter;
  final String title;
  final String description;
  final String timeLabel;
  final IconData icon;
  final Color accentColor;
  final String actionLabel;
  final String? calendarEventId;
  final _NoticeSource source;
  final String? appointmentId;
  final String reminderType;
  final bool isRead;
  final DateTime scheduledAt;
}

/// Pixel-faithful recreation of traditional Philippine wall calendar:
/// thick dark blue border, red JANUARY banner (white text), thin blue grid, red Sundays.
/// Health events shown on dates with color-coded markers by status/age.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    this.showAppBar = true,
    this.scrollController,
    this.backgroundColor,
    this.initialTabIndex,
    this.openAddFamilyMemberModalOnStart = false,
  });

  final bool showAppBar;
  final ScrollController? scrollController;
  final Color? backgroundColor;
  /// 0=Kalendaryo, 1=Mga Miyembro, 2=Mga Abiso.
  final int? initialTabIndex;
  /// If true, switches to Members tab and opens the add-member modal.
  final bool openAddFamilyMemberModalOnStart;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ScrollController _internalScrollController = ScrollController();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  _FamilyCalendarTab _selectedTab = _FamilyCalendarTab.kalendaryo;
  _CalendarAudienceFilter _selectedAudienceFilter =
      _CalendarAudienceFilter.lahat;
  _NoticeFilter _selectedNoticeFilter = _NoticeFilter.lahat;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<String, List<CalendarHealthEvent>> _eventsByDate = {};
  List<_AlertNoticeItem> _upcomingNotifications = [];
  bool _loading = true;
  String? _error;
  bool _abisoMarkedRead = false;

  bool _membersLoading = false;
  String? _membersError;
  List<Map<String, dynamic>> _familyMembersRows = [];

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

  @override
  void initState() {
    super.initState();
    if (widget.initialTabIndex != null) {
      final idx = widget.initialTabIndex!;
      if (idx == 1) _selectedTab = _FamilyCalendarTab.miyembro;
      if (idx == 2) _selectedTab = _FamilyCalendarTab.abiso;
    }
    _loadCalendarData();
    _loadFamilyMembers();
    if (widget.openAddFamilyMemberModalOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        setState(() => _selectedTab = _FamilyCalendarTab.miyembro);
        await _showAddFamilyMemberDialog();
      });
    }
  }

  Future<void> _loadFamilyMembers() async {
    final client = SupabaseService.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    setState(() {
      _membersLoading = true;
      _membersError = null;
    });
    try {
      final familyId = await _ensureFamilyIdForUser(uid);
      if (familyId == null) {
        if (!mounted) return;
        setState(() {
          _membersLoading = false;
          _membersError = 'Hindi makuha ang pamilya.';
        });
        return;
      }
      final res = await client
          .from('family_members')
          .select(
              'id, user_id, name, date_of_birth, sex, pregnancy_status, comorbidities')
          .eq('family_id', familyId)
          .order('date_of_birth', ascending: true);
      final rows = List<Map<String, dynamic>>.from(res as List);
      if (!mounted) return;
      setState(() {
        _familyMembersRows = rows;
        _membersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _membersLoading = false;
        _membersError = e.toString();
      });
    }
  }

  Future<void> _showAddFamilyMemberDialog() async {
    final client = SupabaseService.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mag-sign in muna para makapagdagdag ng miyembro.')),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    DateTime dob = DateTime.now().subtract(const Duration(days: 365 * 20));
    String sex = 'female';
    bool? pregnant = null;

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          return AlertDialog(
            title: const Text('Magdagdag ng miyembro'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Pangalan (optional)'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Petsa ng kapanganakan'),
                    subtitle: Text(_formatTagalogDate(dob)),
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
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
            ],
          );
        },
      ),
    );

    if (ok != true) {
      nameCtrl.dispose();
      return;
    }

    try {
      final familyId = await _ensureFamilyIdForUser(uid);
      if (familyId == null) throw Exception('No family id');
      await client.from('family_members').insert({
        'family_id': familyId,
        'name': nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
        'date_of_birth': dob.toIso8601String(),
        'sex': sex,
        'pregnancy_status': sex == 'female' ? pregnant : null,
        'comorbidities': <String>[],
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Naidagdag ang miyembro ng pamilya.')),
      );
      await _loadFamilyMembers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hindi na-save ang miyembro: $e')),
      );
    } finally {
      nameCtrl.dispose();
    }
  }

  Future<void> _showEditFamilyMemberDialog(Map<String, dynamic> existing) async {
    final client = SupabaseService.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;

    final memberId = existing['id']?.toString();
    if (memberId == null || memberId.isEmpty) return;

    final nameCtrl = TextEditingController(text: (existing['name'] as String?)?.trim() ?? '');
    DateTime dob = DateTime.now().subtract(const Duration(days: 365 * 20));
    final dobRaw = existing['date_of_birth']?.toString().split('T').first;
    if (dobRaw != null) {
      final parsed = DateTime.tryParse(dobRaw);
      if (parsed != null) dob = parsed;
    }
    String sex = (existing['sex'] as String?) ?? 'female';
    bool? pregnant = existing['pregnancy_status'] as bool?;
    if (sex != 'female') pregnant = null;

    bool deleteRequested = false;

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          return AlertDialog(
            title: const Text('I-edit ang miyembro'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Pangalan (optional)'),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Petsa ng kapanganakan'),
                    subtitle: Text(_formatTagalogDate(dob)),
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
              TextButton(
                onPressed: () {
                  deleteRequested = true;
                  Navigator.of(ctx).pop(true);
                },
                style: TextButton.styleFrom(foregroundColor: AppTheme.accentEmergency),
                child: const Text('Delete'),
              ),
              FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
            ],
          );
        },
      ),
    );

    if (ok != true) {
      nameCtrl.dispose();
      return;
    }

    try {
      if (deleteRequested) {
        await client.from('family_members').delete().eq('id', memberId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Na-delete ang miyembro ng pamilya.')),
        );
        await _loadFamilyMembers();
        return;
      }

      await client.from('family_members').update({
        'name': nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
        'date_of_birth': dob.toIso8601String(),
        'sex': sex,
        'pregnancy_status': sex == 'female' ? pregnant : null,
      }).eq('id', memberId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Na-update ang miyembro ng pamilya.')),
      );
      await _loadFamilyMembers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hindi na-save ang miyembro: $e')),
      );
    } finally {
      nameCtrl.dispose();
    }
  }

  /// Loads user appointments and system calendar_events (admin-created schedules).
  Future<void> _loadCalendarData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final Map<String, List<CalendarHealthEvent>> byDate = {};
    final List<_AlertNoticeItem> upcomingNotifications = [];
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;

      DateTime? dateFromKey(String dateKey) {
        final parts = dateKey.split('-');
        if (parts.length != 3) return null;
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y == null || m == null || d == null) return null;
        return DateTime(y, m, d);
      }

      DateTime timeOnDay(DateTime day, String dbTime) {
        final parts = dbTime.split(':');
        final h = int.tryParse(parts[0]) ?? 0;
        final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        return DateTime(day.year, day.month, day.day, h, m);
      }

      // Used to compute age-group markers for booked appointments.
      Map<String, ({DateTime dob, String sex, bool? preg, String name})>
          familyMemberMetaById = {};
      int? profileAge;
      String? profileSex;
      String? profileFullName;

      if (userId != null) {
        // Batch-load family_members for age-group mapping.
        final familyId = await _ensureFamilyIdForUser(userId);
        if (familyId != null) {
          final fmRes = await client
              .from('family_members')
              .select('id, name, date_of_birth, sex, pregnancy_status')
              .eq('family_id', familyId);
          final fmList =
              List<Map<String, dynamic>>.from((fmRes as dynamic) as List);
          for (final r in fmList) {
            final id = r['id']?.toString() ?? '';
            if (id.isEmpty) continue;
            final dobRaw = r['date_of_birth']?.toString().split('T').first;
            final dob = dobRaw != null ? DateTime.tryParse(dobRaw) : null;
            if (dob == null) continue;
            final sex = (r['sex'] as String?) ?? 'other';
            final preg = r['pregnancy_status'] as bool?;
            final name = (r['name'] as String?) ?? 'Miyembro ng pamilya';
            familyMemberMetaById[id] = (dob: dob, sex: sex, preg: preg, name: name);
          }
        }

        // For appointments booked for "self" (family_member_id == null),
        // fall back to profiles age/sex/name.
        try {
          final profRes = await client
              .from('profiles')
              .select('age, sex, full_name')
              .eq('user_id', userId)
              .maybeSingle();
          profileAge = profRes?['age'] as int?;
          profileSex = profRes?['sex'] as String?;
          profileFullName = profRes?['full_name'] as String?;
        } catch (_) {}

        final appointmentsRes = await client
            .from('appointments')
            .select('id, event_date, title, description, status, family_member_id')
            .eq('user_id', userId)
            .order('event_date', ascending: true);
        final appointmentsList =
            List<Map<String, dynamic>>.from(appointmentsRes as List);

        final apptTemps = <({
          String dateKey,
          String title,
          String? description,
          String appointmentId,
          HealthEventGroup group,
          String? calendarEventId,
          String? familyMemberId,
          String memberLabel,
        })>[];
        final calEventIds = <String>{};

        for (final row in appointmentsList) {
          final status = row['status'] as String?;
          if (status == 'cancelled') continue;

          final dateKey = row['event_date'] is String
              ? row['event_date'] as String
              : _dateKeyFromDateTime(row['event_date']);
          if (dateKey.isEmpty) continue;

          final appointmentId = row['id']?.toString() ?? '';
          if (appointmentId.isEmpty) continue;

          final memberId = row['family_member_id']?.toString();
          final rawDesc = row['description'] as String?;
          final calendarEventId =
              _rhuCalIdFromAppointmentDescription(rawDesc);
          if (calendarEventId != null && calendarEventId.isNotEmpty) {
            calEventIds.add(calendarEventId);
          }

          final group = _appointmentGroupForRow(
            memberId: memberId,
            familyMemberMetaById: familyMemberMetaById,
            profileAge: profileAge,
            profileSex: profileSex,
          );

          final memberLabel = memberId != null && memberId.isNotEmpty
              ? (familyMemberMetaById[memberId]?.name ??
                  'Miyembro ng pamilya')
              : (profileFullName ?? 'Ikaw');

          apptTemps.add((
            dateKey: dateKey,
            title: row['title'] as String? ?? 'Serbisyo',
            description: _cleanAppointmentDescriptionForUi(rawDesc),
            appointmentId: appointmentId,
            group: group,
            calendarEventId: calendarEventId,
            familyMemberId: memberId,
            memberLabel: memberLabel,
          ));
        }

        // Load schedule metadata from the referenced calendar_events.
        final calMetaById = <String, Map<String, dynamic>>{};
        if (calEventIds.isNotEmpty) {
          // Avoid PostgREST `.in(...)` filter compatibility issues across
          // supabase_flutter versions; just fetch and filter by ids locally.
          final calRes = await client
              .from('calendar_events')
              .select(
                'id, start_time, facility',
              );
          final calList =
              List<Map<String, dynamic>>.from((calRes as dynamic) as List);
          for (final r in calList) {
            final id = r['id']?.toString() ?? '';
            if (id.isEmpty) continue;
            if (!calEventIds.contains(id)) continue;
            calMetaById[id] = r;
          }
        }

        final now = DateTime.now();
        final horizon = now.add(const Duration(days: 7));

        // Build calendar events map + upcoming notification list.
        for (final appt in apptTemps) {
          final cal =
              appt.calendarEventId == null ? null : calMetaById[appt.calendarEventId];
          final startTimeRaw = cal?['start_time']?.toString();
          final facility = cal?['facility'] as String?;

          final timeStr = (startTimeRaw != null && startTimeRaw.isNotEmpty)
              ? _formatEventTimeFromDb(startTimeRaw)
              : null;

          byDate.putIfAbsent(appt.dateKey, () => []).add(CalendarHealthEvent(
                group: appt.group,
                title: appt.title,
                description: appt.description,
                time: timeStr,
                facility: facility,
                calendarEventId: appt.calendarEventId,
              ));

          if (appt.calendarEventId == null) continue;
          final day = dateFromKey(appt.dateKey);
          if (day == null || startTimeRaw == null || startTimeRaw.isEmpty) {
            continue;
          }

          final scheduleStart = timeOnDay(day, startTimeRaw);

          final baseTitle = 'Paalala: Appointment';
          final timeLabel = _formatEventTimeFromDb(startTimeRaw);
          final dateLabel = _formatTagalogDate(day);
          final facilityLabel =
              (facility != null && facility.trim().isNotEmpty) ? facility.trim() : null;
          final whereLine =
              facilityLabel == null ? '' : ' sa $facilityLabel';
          final desc = '${appt.memberLabel} ay may appointment: ${appt.title}$whereLine sa $dateLabel, $timeLabel.';

          void addLeadNotification({
            required _NoticeFilter filter,
            required String reminderType,
            required Duration lead,
            required String timeLabel,
            required IconData icon,
          }) {
            final sendAt = scheduleStart.subtract(lead);
            if (sendAt.isBefore(now)) return;
            if (sendAt.isAfter(horizon)) return;

            upcomingNotifications.add(_AlertNoticeItem(
              filter: filter,
              title: baseTitle,
              description: desc,
              timeLabel: timeLabel,
              icon: icon,
              accentColor: appt.group.color,
              actionLabel: 'Tingnan',
              calendarEventId: appt.calendarEventId,
              source: _NoticeSource.appointmentReminder,
              appointmentId: appt.appointmentId,
              reminderType: reminderType,
              isRead: false,
              scheduledAt: sendAt,
            ));
          }

          addLeadNotification(
            filter: _NoticeFilter.appointments,
            reminderType: 'lead_7d',
            lead: const Duration(days: 7),
            timeLabel: '1 linggo bago',
            icon: Icons.calendar_view_week_outlined,
          );
          addLeadNotification(
            filter: _NoticeFilter.appointments,
            reminderType: 'lead_1d',
            lead: const Duration(days: 1),
            timeLabel: '1 araw bago',
            icon: Icons.calendar_month_outlined,
          );
          addLeadNotification(
            filter: _NoticeFilter.appointments,
            reminderType: 'lead_1h',
            lead: const Duration(hours: 1),
            timeLabel: '1 oras bago',
            icon: Icons.access_time_outlined,
          );
        }
      }

        // ===== Admin-created event reminders (send_notifications = true) =====
        // Abiso page should also show reminders for newly posted schedules
        // even if the user hasn't booked the appointment yet.
        final appointmentReminderKeys = <String>{};
        for (final n in upcomingNotifications) {
          if (n.source != _NoticeSource.appointmentReminder) continue;
          if (n.calendarEventId == null) continue;
          appointmentReminderKeys.add('${n.calendarEventId}|${n.reminderType}');
        }

        final candidates = <({int age, String sex, bool? preg, String label})>[];
        if (profileAge != null && profileSex != null) {
          candidates.add((
            age: profileAge,
            sex: profileSex,
            preg: null,
            label: profileFullName ?? 'Ikaw',
          ));
        }
        for (final meta in familyMemberMetaById.values) {
          candidates.add((
            age: _ageFromDob(meta.dob),
            sex: meta.sex,
            preg: meta.preg,
            label: meta.name,
          ));
        }

        int? parseNullableInt(dynamic v) {
          if (v == null) return null;
          if (v is int) return v;
          return int.tryParse(v.toString());
        }

        bool candidateMatchesGroupKey(
          String groupKey,
          int age,
          String sex,
          bool? preg,
        ) {
          switch (groupKey) {
            case 'buntis':
              return sex == 'female' && preg == true;
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

        List<String> groupsFromCalendarEventRow(Map<String, dynamic> ev) {
          final rawGt = ev['group_types'];
          if (rawGt is List) {
            return rawGt.map((x) => x.toString()).toList();
          }
          if (rawGt is String) {
            return rawGt
                .trim()
                .replaceAll('{', '')
                .replaceAll('}', '')
                .split(',')
                .map((x) => x.trim())
                .where((x) => x.isNotEmpty)
                .toList();
          }
          final one = ev['group_type'] as String?;
          if (one != null && one.trim().isNotEmpty) return [one.trim()];
          return const [];
        }

        Color accentColorFromGroupKey(String g) {
          switch (g) {
            case 'buntis':
              return HealthEventGroup.buntis.color;
            case 'bata':
              return HealthEventGroup.bata.color;
            case 'adolescent':
              return HealthEventGroup.adolescent.color;
            case 'adult':
              return HealthEventGroup.adult.color;
            case 'elderly':
              return HealthEventGroup.elderly.color;
            default:
              return AppTheme.accentTeal;
          }
        }

        if (candidates.isNotEmpty) {
          final adminNow = DateTime.now();
          final startDate = DateTime(adminNow.year, adminNow.month, adminNow.day);
          final endDate = startDate.add(const Duration(days: 30));
          final startKey = _dateKeyFromDateTime(startDate);
          final endKey = _dateKeyFromDateTime(endDate);

          final adminRes = await client
              .from('calendar_events')
              .select(
                'id, event_date, title, start_time, facility, send_announcement, announcement_title, announcement_body, group_types, group_type, age_range_min, age_range_max',
              )
              .eq('send_announcement', true)
              .gte('event_date', startKey)
              .lte('event_date', endKey);

          final adminList =
              List<Map<String, dynamic>>.from((adminRes as dynamic) as List);

          for (final ev in adminList) {
            final eventId = ev['id']?.toString() ?? '';
            if (eventId.isEmpty) continue;

            final eventDateRaw = ev['event_date'];
            final eventDateKey =
                eventDateRaw is String ? eventDateRaw : _dateKeyFromDateTime(eventDateRaw);
            final day = dateFromKey(eventDateKey);
            if (day == null) continue;
            if (day.isBefore(startDate)) continue;

            final startTimeRaw = ev['start_time']?.toString();
            if (startTimeRaw == null || startTimeRaw.isEmpty) continue;

            // For announcements we don't need lead-time scheduleStart logic.

            final ageMin = parseNullableInt(ev['age_range_min']);
            final ageMax = parseNullableInt(ev['age_range_max']);

            final groupKeys = groupsFromCalendarEventRow(ev);
            if (groupKeys.isEmpty) continue;

            final eligibleLabels = <String>{};
            for (final c in candidates) {
              if (ageMin != null && c.age < ageMin) continue;
              if (ageMax != null && c.age > ageMax) continue;

              if (groupKeys.any((g) =>
                  candidateMatchesGroupKey(g, c.age, c.sex, c.preg))) {
                eligibleLabels.add(c.label);
              }
            }
            if (eligibleLabels.isEmpty) continue;

            final annTitle = (ev['announcement_title'] as String?)?.trim();
            final annBody = (ev['announcement_body'] as String?)?.trim();
            final baseTitle = (annTitle != null && annTitle.isNotEmpty)
                ? annTitle
                : (ev['title'] as String?)?.trim() ?? 'Bagong iskedyul';

            final facilityLabel = (ev['facility'] as String?)?.trim();
            final whereLine = (facilityLabel != null && facilityLabel.isNotEmpty)
                ? ' sa $facilityLabel'
                : '';
            final dateLabel = _formatTagalogDate(day);
            final timeLabel = _formatEventTimeFromDb(startTimeRaw);

            final scheduleLine = 'Iskedyul: $dateLabel, $timeLabel$whereLine';
            final audienceLine = 'Para sa: ${eligibleLabels.join(', ')}';
            final description = (annBody != null && annBody.isNotEmpty)
                ? '$annBody\n\n$scheduleLine\n$audienceLine'
                : '$scheduleLine\n$audienceLine';

            final accentColor =
                accentColorFromGroupKey(groupKeys.first);

            // Add one "announcement" notice per event (not a lead-time reminder).
            upcomingNotifications.add(_AlertNoticeItem(
              filter: _NoticeFilter.announcement,
              title: baseTitle,
              description: description,
              timeLabel: 'Announcement',
              icon: Icons.campaign_outlined,
              accentColor: accentColor,
              actionLabel: 'Tingnan',
              calendarEventId: eventId,
              source: _NoticeSource.adminEvent,
              appointmentId: null,
              reminderType: 'announcement',
              isRead: false,
              // Use "now" so it surfaces as a newly posted item.
              scheduledAt: adminNow,
            ));
          }
        }

      upcomingNotifications.sort(
        (a, b) => a.scheduledAt.compareTo(b.scheduledAt),
      );

      // Apply read/unread state (appointment reminders + admin event reminders).
      if (userId != null && upcomingNotifications.isNotEmpty) {
        final apReadRes = await client
            .from('appointment_reminder_notification_reads')
            .select('appointment_id, reminder_type')
            .eq('user_id', userId);
        final apReadRows =
            List<Map<String, dynamic>>.from((apReadRes as dynamic) as List);
        final apReadKeys = <String>{};
        for (final r in apReadRows) {
          final aid = r['appointment_id']?.toString() ?? '';
          final rt = r['reminder_type']?.toString() ?? '';
          if (aid.isEmpty || rt.isEmpty) continue;
          apReadKeys.add('$aid|$rt');
        }

        final adminReadRes = await client
            .from('admin_calendar_event_notification_reads')
            .select('calendar_event_id')
            .eq('user_id', userId);
        final adminReadRows = List<Map<String, dynamic>>.from(
            (adminReadRes as dynamic) as List);
        final adminReadIds = <String>{};
        for (final r in adminReadRows) {
          final id = r['calendar_event_id']?.toString() ?? '';
          if (id.isEmpty) continue;
          adminReadIds.add(id);
        }

        final noticesWithRead = upcomingNotifications.map((n) {
          final isRead = n.source == _NoticeSource.appointmentReminder
              ? (n.appointmentId == null
                  ? false
                  : apReadKeys
                      .contains('${n.appointmentId}|${n.reminderType}'))
              : (n.calendarEventId != null &&
                  adminReadIds.contains(n.calendarEventId));

          return _AlertNoticeItem(
            filter: n.filter,
            source: n.source,
            title: n.title,
            description: n.description,
            timeLabel: n.timeLabel,
            icon: n.icon,
            accentColor: n.accentColor,
            actionLabel: n.actionLabel,
            calendarEventId: n.calendarEventId,
            appointmentId: n.appointmentId,
            reminderType: n.reminderType,
            isRead: isRead,
            scheduledAt: n.scheduledAt,
          );
        }).toList();

        if (!mounted) return;
        setState(() {
          _eventsByDate = byDate;
          _upcomingNotifications = noticesWithRead;
          _loading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _eventsByDate = byDate;
        _upcomingNotifications = upcomingNotifications;
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

  HealthEventGroup _appointmentGroupForRow({
    required String? memberId,
    required Map<String, ({DateTime dob, String sex, bool? preg, String name})>
        familyMemberMetaById,
    required int? profileAge,
    required String? profileSex,
  }) {
    if (memberId != null && memberId.isNotEmpty) {
      final meta = familyMemberMetaById[memberId];
      if (meta != null) {
        // If the member is pregnant female, mark as buntis.
        if (meta.sex == 'female' && meta.preg == true) {
          return HealthEventGroup.buntis;
        }
        final age = _ageFromDob(meta.dob);
        return _groupFromAge(age);
      }
    }

    // Fallback to the signed-in user's profile.
    final age = profileAge ?? 25;
    final sex = profileSex ?? 'other';
    if (sex == 'female') {
      // We don't store pregnancy for self here; buntis depends on member pregnancy_status.
      // So we fall back to age group.
    }
    return _groupFromAge(age);
  }

  static String _formatEventTimeFromDb(String dbTime) {
    final parts = dbTime.split(':');
    if (parts.isEmpty) return dbTime;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:${m.toString().padLeft(2, '0')} $period';
  }

  static String? _rhuCalIdFromAppointmentDescription(String? desc) {
    if (desc == null) return null;
    final match = RegExp(r'rhu_cal:([0-9a-fA-F\\-]{36})', multiLine: true)
        .firstMatch(desc.trim());
    return match?.group(1);
  }

  String? _cleanAppointmentDescriptionForUi(String? desc) {
    if (desc == null) return null;
    final lines = desc
        .split('\n')
        .map((s) => s.trim())
        .where((line) =>
            line.isNotEmpty &&
            !line.startsWith('rhu_book:') &&
            !line.startsWith('rhu_cal:'))
        .toList();
    if (lines.isEmpty) return null;
    return lines.join('\n');
  }

  static String _dateKeyFromDateTime(dynamic v) {
    if (v == null) return '';
    if (v is String) return v.split('T').first;
    if (v is DateTime) {
      return '${v.year}-${v.month.toString().padLeft(2, '0')}-${v.day.toString().padLeft(2, '0')}';
    }
    return '';
  }

  List<CalendarHealthEvent> _getEventsForDay(DateTime day) {
    final key =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return _eventsByDate[key] ?? [];
  }

  List<CalendarHealthEvent> _getVisibleEventsForDay(DateTime day) {
    final events = _getEventsForDay(day);
    final group = _selectedAudienceFilter.group;
    if (group == null) return events;
    return events.where((event) => event.group == group).toList();
  }

  List<_UpcomingScheduleItem> get _upcomingSchedules {
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final List<({DateTime date, CalendarHealthEvent event})> items = [];
    for (final entry in _eventsByDate.entries) {
      final key = entry.key;
      if (key.compareTo(todayKey) < 0) continue;
      final parts = key.split('-');
      if (parts.length != 3) continue;
      final date = DateTime(
        int.tryParse(parts[0]) ?? now.year,
        int.tryParse(parts[1]) ?? now.month,
        int.tryParse(parts[2]) ?? now.day,
        9,
        0,
      );
      final handledCal = <String>{};
      for (final ev in entry.value) {
        if (ev.calendarEventId != null) {
          if (handledCal.contains(ev.calendarEventId!)) continue;
          handledCal.add(ev.calendarEventId!);
          final same = entry.value.where((x) => x.calendarEventId == ev.calendarEventId).toList();
          if (same.length > 1) {
            final parts = same
                .map((x) => x.group.label.split('(').first.trim())
                .toSet()
                .toList();
            items.add((
              date: date,
              event: CalendarHealthEvent(
                group: ev.group,
                title: ev.title,
                description: ev.description,
                time: ev.time,
                facility: ev.facility,
                ageRangeNote: ev.ageRangeNote,
                calendarEventId: ev.calendarEventId,
                audienceSummary: parts.join(' · '),
              ),
            ));
          } else {
            items.add((date: date, event: ev));
          }
        } else {
          items.add((date: date, event: ev));
        }
      }
    }
    items.sort((a, b) => a.date.compareTo(b.date));
    return items.take(20).map((item) {
      final isToday = item.date.year == now.year &&
          item.date.month == now.month &&
          item.date.day == now.day;
      final daysDiff = item.date.difference(DateTime(now.year, now.month, now.day)).inDays;
      String statusLabel;
      Color statusColor;
      if (isToday) {
        statusLabel = 'Ngayon';
        statusColor = AppTheme.adultOrange;
      } else if (daysDiff < 0) {
        statusLabel = 'Nalagpasan';
        statusColor = AppTheme.accentEmergency;
      } else if (daysDiff <= 7) {
        statusLabel = daysDiff == 1 ? 'Bukas' : 'Paparating ($daysDiff araw)';
        statusColor = AppTheme.adolescentBlue;
      } else {
        statusLabel = 'Paparating';
        statusColor = item.event.group.color;
      }
      return _UpcomingScheduleItem(
        personName: item.event.title,
        relationLabel:
            item.event.audienceSummary ?? item.event.group.label,
        title: item.event.title,
        dateTime: item.date,
        group: item.event.group,
        statusLabel: statusLabel,
        statusColor: statusColor,
        actionLabel: 'Tingnan',
      );
    }).toList();
  }

  List<_UpcomingScheduleItem> get _visibleUpcomingSchedules {
    final group = _selectedAudienceFilter.group;
    if (group == null) return _upcomingSchedules;
    return _upcomingSchedules.where((item) => item.group == group).toList();
  }

  int _ageFromDob(DateTime dob) {
    final now = DateTime.now();
    int a = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      a--;
    }
    return a;
  }

  HealthEventGroup _groupFromAge(int age) {
    if (age <= 9) return HealthEventGroup.bata;
    if (age <= 19) return HealthEventGroup.adolescent;
    if (age <= 59) return HealthEventGroup.adult;
    return HealthEventGroup.elderly;
  }

  String _sexLabel(String sex) {
    switch (sex) {
      case 'female':
        return 'Babae';
      case 'male':
        return 'Lalaki';
      default:
        return 'Iba pa';
    }
  }

  String _tagalogDob(DateTime d) {
    return '${_tagalogMonthNames[d.month - 1]} ${d.day}, ${d.year}';
  }

  List<_AlertNoticeItem> get _alertNotices => _upcomingNotifications;

  List<_AlertNoticeItem> get _visibleAlertNotices {
    final all = _alertNotices;
    if (_selectedNoticeFilter == _NoticeFilter.lahat) return all;
    return all.where((item) => item.filter == _selectedNoticeFilter).toList();
  }

  @override
  void dispose() {
    _internalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);

    if (!widget.showAppBar) {
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? const Color(0xFFF5F5F5),
        body: body,
      );
    }

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
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.scale(context, AppTheme.spacingLg),
                    0,
                    AppTheme.scale(context, AppTheme.spacingLg),
                    0,
                  ),
                  child: _buildTabSwitcher(context),
                ),
                Container(
                  height: AppTheme.scale(context, AppTheme.spacingLg),
                  color: _bodyBackground,
                ),
                Expanded(
                  child: Container(color: _bodyBackground, child: body),
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
                    'Kalendaryo ng\nKalusugang Pampamilya',
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
    final controller = widget.scrollController ?? _internalScrollController;
    final bottomPadding = widget.showAppBar
        ? AppTheme.scale(context, AppTheme.spacingXxl) +
              AppTheme.floatingNavBarClearance
        : AppTheme.scale(context, AppTheme.spacingLg);

    return Container(
      color: const Color(0xFFF3F4F8),
      child: Scrollbar(
        controller: controller,
        thumbVisibility: false,
        child: RefreshIndicator(
          onRefresh: _loadCalendarData,
          child: SingleChildScrollView(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.showAppBar)
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
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.scale(context, AppTheme.spacingLg),
                    AppTheme.scale(context, AppTheme.spacingMd),
                    AppTheme.scale(context, AppTheme.spacingLg),
                    AppTheme.scale(context, AppTheme.spacingLg),
                  ),
                  child: _buildTabSwitcher(context),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.scale(context, AppTheme.spacingLg),
                  AppTheme.scale(context, AppTheme.spacingMd),
                  AppTheme.scale(context, AppTheme.spacingLg),
                  0,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _buildSelectedTabContent(context),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(BuildContext context) {
    switch (_selectedTab) {
      case _FamilyCalendarTab.kalendaryo:
        return KeyedSubtree(
          key: const ValueKey('calendar-tab'),
          child: _buildCalendarTabContent(context),
        );
      case _FamilyCalendarTab.miyembro:
        return KeyedSubtree(
          key: const ValueKey('members-tab'),
          child: _buildMembersTabContent(context),
        );
      case _FamilyCalendarTab.abiso:
        return KeyedSubtree(
          key: const ValueKey('alerts-tab'),
          child: _buildAlertsTabContent(context),
        );
    }
  }

  Widget _buildTabSwitcher(BuildContext context) {
    final scale = AppTheme.scale(context, 1.0);
    return Row(
      children: [
        Expanded(
          child: _buildTabSwitchItem(
            context,
            tab: _FamilyCalendarTab.kalendaryo,
            label: 'Kalendaryo',
            icon: Icons.calendar_month_outlined,
            iconColor: AppTheme.adultOrange,
          ),
        ),
        SizedBox(width: scale * 8),
        Expanded(
          child: _buildTabSwitchItem(
            context,
            tab: _FamilyCalendarTab.miyembro,
            label: 'Mga Miyembro',
            icon: Icons.group_add_outlined,
            iconColor: const Color(0xFF2E5FA8),
          ),
        ),
        SizedBox(width: scale * 8),
        Expanded(
          child: _buildTabSwitchItem(
            context,
            tab: _FamilyCalendarTab.abiso,
            label: 'Mga Abiso',
            icon: Icons.notifications_active_outlined,
            iconColor: const Color(0xFFE4B400),
          ),
        ),
      ],
    );
  }

  static const Color _bodyBackground = Color(0xFFF3F4F8);

  Widget _buildTabSwitchItem(
    BuildContext context, {
    required _FamilyCalendarTab tab,
    required String label,
    required IconData icon,
    required Color iconColor,
  }) {
    final selected = _selectedTab == tab;
    final scale = AppTheme.scale(context, 1.0);
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(vertical: scale * 12),
        decoration: BoxDecoration(
          color: selected ? _bodyBackground : Colors.transparent,
          borderRadius: selected
              ? const BorderRadius.vertical(top: Radius.circular(18))
              : BorderRadius.circular(18),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
          : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: scale * 24),
            SizedBox(height: scale * 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? AppTheme.primaryBlue : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarTabContent(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Kinakarga ang kalendaryo...'),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.scale(context, AppTheme.spacingLg)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.accentEmergency),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadCalendarData,
                child: const Text('Subukang muli'),
              ),
            ],
          ),
        ),
      );
    }
    final schedules = _visibleUpcomingSchedules;
    return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
        _buildCalendarFiltersRow(context),
        SizedBox(height: AppTheme.scale(context, AppTheme.spacingMd)),
            _buildTraditionalCalendar(context),
        SizedBox(height: AppTheme.scale(context, AppTheme.spacingMd)),
        _buildContentTitle(
          context,
          title: 'Mga Paparating na Iskedyul',
          subtitle: '${schedules.length} kabuuang iskedyul',
        ),
        SizedBox(height: AppTheme.scale(context, AppTheme.spacingSm)),
        if (schedules.isEmpty)
          _buildEmptyState(
            context,
            message: 'Walang paparating na iskedyul para sa napiling salaan.',
            icon: Icons.event_busy_outlined,
          )
        else
          ...schedules.asMap().entries.map((entry) {
            final isLast = entry.key == schedules.length - 1;
            return Padding(
              padding: EdgeInsets.only(
                bottom: isLast
                    ? 0
                    : AppTheme.scale(context, AppTheme.spacingSm),
              ),
              child: _buildUpcomingScheduleCard(context, entry.value),
            );
          }),
      ],
    );
  }

  Widget _buildMembersTabContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _buildContentTitle(
                context,
                title: 'Mga Miyembro ng Pamilya',
                subtitle:
                    'Impormasyon, planong pangkalusugan, at susunod na gawaing pangkalusugan ng bawat miyembro',
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: _showAddFamilyMemberDialog,
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Pamahalaan'),
            ),
          ],
        ),
        SizedBox(height: AppTheme.scale(context, AppTheme.spacingSm)),
        if (_membersLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_membersError != null)
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppTheme.scale(context, AppTheme.spacingMd),
            ),
            child: Text(
              _membersError!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.accentEmergency),
            ),
          )
        else if (_familyMembersRows.isEmpty)
          _buildEmptyState(
            context,
            message: 'Wala pang miyembro ng pamilya. Pindutin ang Pamahalaan para magdagdag.',
            icon: Icons.people_outline_rounded,
          )
        else
          ..._familyMembersRows.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final isLast = i == _familyMembersRows.length - 1;
            final name = (r['name'] as String?)?.trim();
            final sexDb = (r['sex'] as String?) ?? 'other';
            final preg = r['pregnancy_status'] as bool?;
            final dobRaw = r['date_of_birth']?.toString().split('T').first;
            final dob = dobRaw != null ? DateTime.tryParse(dobRaw) : null;
            final age = dob != null ? _ageFromDob(dob) : 0;
            final group = (sexDb == 'female' && preg == true)
                ? HealthEventGroup.buntis
                : _groupFromAge(age);
            final profileLabel =
                '${group.label.split('(').first.trim()} | $age taon';
            final detailLine =
                '${_sexLabel(sexDb)}${dob != null ? ' | ${_tagalogDob(dob)}' : ''}';
            return Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppTheme.scale(context, AppTheme.spacingSm),
              ),
              child: _buildFamilyMemberCard(
                context,
                _FamilyMemberOverview(
                  name: name == null || name.isEmpty ? 'Miyembro ng pamilya' : name,
                  profileLabel: profileLabel,
                  detailLine: detailLine,
                  group: group,
                ),
                onTap: () => _showEditFamilyMemberDialog(r),
                showPlanButton: false,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAlertsTabContent(BuildContext context) {
    final notices = _visibleAlertNotices;

    if (!_abisoMarkedRead && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _markAdminEventsAsRead();
        await _markAppointmentRemindersAsRead(_upcomingNotifications);
        if (!mounted) return;
        setState(() => _abisoMarkedRead = true);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildContentTitle(
          context,
          title: 'Mga Abiso',
          subtitle: 'Mga paalala at abiso para sa iskedyul',
        ),
        SizedBox(height: AppTheme.scale(context, AppTheme.spacingSm)),
        _buildNoticeFilterChips(context),
        SizedBox(height: AppTheme.scale(context, AppTheme.spacingMd)),
        if (notices.isEmpty)
          _buildEmptyState(
            context,
            message: 'Walang abiso para sa napiling salaan.',
            icon: Icons.notifications_off_outlined,
          )
        else
          ...notices.asMap().entries.map((entry) {
            final isLast = entry.key == notices.length - 1;
            return Padding(
              padding: EdgeInsets.only(
                bottom: isLast
                    ? 0
                    : AppTheme.scale(context, AppTheme.spacingSm),
              ),
              child: _buildAlertCard(
                context,
                entry.value,
                onTap: () => _openNoticeSchedule(entry.value),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _openNoticeSchedule(_AlertNoticeItem item) async {
    await _markSingleReminderAsRead(item);
    final calendarEventId = item.calendarEventId;
    if (calendarEventId == null || calendarEventId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Walang detalye ng iskedyul.')),
      );
      return;
    }

    try {
      final res = await SupabaseService.client
          .from('calendar_events')
          .select(
            'id, event_date, title, description, start_time, end_time, facility, group_types, group_type, age_range_min, age_range_max',
          )
          .eq('id', calendarEventId)
          .maybeSingle();

      if (res == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hindi ma-load ang iskedyul.')),
        );
        return;
      }

      if (!mounted) return;
      await showScheduleDetailForBooking(
        context,
        event: Map<String, dynamic>.from(res as Map),
      );
      await _loadCalendarData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hindi ma-load ang detalye: $e')),
      );
    }
  }

  Future<void> _markSingleReminderAsRead(_AlertNoticeItem item) async {
    if (item.isRead) return;
    final uid = SupabaseService.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      if (item.source == _NoticeSource.appointmentReminder) {
        if (item.appointmentId == null) return;
        await SupabaseService.client
            .from('appointment_reminder_notification_reads')
            .insert({
              'user_id': uid,
              'appointment_id': item.appointmentId,
              'reminder_type': item.reminderType,
            });
      } else {
        if (item.calendarEventId == null) return;
        await SupabaseService.client
            .from('admin_calendar_event_notification_reads')
            .insert({
              'user_id': uid,
              'calendar_event_id': item.calendarEventId,
            });
      }
    } catch (_) {
      // Ignore duplicates; reload will reflect updated state.
    }
  }

  Future<void> _markAppointmentRemindersAsRead(
    List<_AlertNoticeItem> notices,
  ) async {
    if (notices.isEmpty) return;
    final uid = SupabaseService.client.auth.currentUser?.id;
    if (uid == null) return;

    final unread = notices
        .where((n) =>
            n.source == _NoticeSource.appointmentReminder &&
            !n.isRead &&
            n.appointmentId != null)
        .toList();
    if (unread.isEmpty) return;

    try {
      final rows = unread
          .map((n) => <String, dynamic>{
                'user_id': uid,
                'appointment_id': n.appointmentId,
                'reminder_type': n.reminderType,
              })
          .toList();
      await SupabaseService.client
          .from('appointment_reminder_notification_reads')
          .insert(rows);
    } catch (_) {
      // Ignore insertion errors; UI will correct on next reload.
    }

    if (!mounted) return;
    final unreadKeys =
        unread.map((n) => '${n.appointmentId}|${n.reminderType}').toSet();
    setState(() {
      _upcomingNotifications = _upcomingNotifications.map((n) {
        final key = '${n.appointmentId}|${n.reminderType}';
        if (!unreadKeys.contains(key)) return n;
        if (n.isRead) return n;
        return _AlertNoticeItem(
          filter: n.filter,
          source: n.source,
          title: n.title,
          description: n.description,
          timeLabel: n.timeLabel,
          icon: n.icon,
          accentColor: n.accentColor,
          actionLabel: n.actionLabel,
          calendarEventId: n.calendarEventId,
          appointmentId: n.appointmentId,
          reminderType: n.reminderType,
          isRead: true,
          scheduledAt: n.scheduledAt,
        );
      }).toList();
    });
  }

  Future<void> _markAdminEventsAsRead() async {
    final uid = SupabaseService.client.auth.currentUser?.id;
    if (uid == null) return;

    final unreadAdmin = _upcomingNotifications
        .where((n) =>
            n.source == _NoticeSource.adminEvent &&
            !n.isRead &&
            n.calendarEventId != null)
        .toList();
    if (unreadAdmin.isEmpty) return;

    final ids = unreadAdmin
        .map((n) => n.calendarEventId)
        .whereType<String>()
        .toSet();

    // Only insert what isn't already read.
    final readRes = await SupabaseService.client
        .from('admin_calendar_event_notification_reads')
        .select('calendar_event_id')
        .eq('user_id', uid);
    final readRows = List<Map<String, dynamic>>.from(
      (readRes as dynamic) as List,
    );
    final readIds = <String>{};
    for (final r in readRows) {
      final id = r['calendar_event_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      readIds.add(id);
    }

    final missing = ids.where((id) => !readIds.contains(id)).toList();
    if (missing.isNotEmpty) {
      try {
        await SupabaseService.client
            .from('admin_calendar_event_notification_reads')
            .insert(
              missing
                  .map((id) => <String, dynamic>{
                        'user_id': uid,
                        'calendar_event_id': id,
                      })
                  .toList(),
            );
      } catch (_) {
        // ignore duplicates
      }
    }

    // Update UI immediately.
    if (!mounted) return;
    setState(() {
      _upcomingNotifications = _upcomingNotifications.map((n) {
        if (n.source != _NoticeSource.adminEvent) return n;
        if (n.calendarEventId == null) return n;
        if (!ids.contains(n.calendarEventId)) return n;
        if (n.isRead) return n;
        return _AlertNoticeItem(
          filter: n.filter,
          source: n.source,
          title: n.title,
          description: n.description,
          timeLabel: n.timeLabel,
          icon: n.icon,
          accentColor: n.accentColor,
          actionLabel: n.actionLabel,
          calendarEventId: n.calendarEventId,
          appointmentId: n.appointmentId,
          reminderType: n.reminderType,
          isRead: true,
          scheduledAt: n.scheduledAt,
        );
      }).toList();
    });
  }

  Widget _buildSimpleDropdown<T>({
    required BuildContext context,
    required T value,
    required List<T> items,
    required String Function(T) label,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.scale(context, AppTheme.spacingMd),
        vertical: AppTheme.scale(context, AppTheme.spacingXs),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(10),
          dropdownColor: Colors.white,
          items: items
              .map((e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text(
                      label(e),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCalendarFiltersRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSimpleDropdown<_CalendarAudienceFilter>(
            context: context,
            value: _selectedAudienceFilter,
            items: _CalendarAudienceFilter.values.toList(),
            label: (f) => f.label,
            onChanged: (v) {
              if (v != null) setState(() => _selectedAudienceFilter = v);
            },
          ),
        ),
        SizedBox(width: AppTheme.scale(context, AppTheme.spacingSm)),
        Expanded(
          child: _buildSimpleDropdown<CalendarFormat>(
            context: context,
            value: _calendarFormat,
            items: const [CalendarFormat.month, CalendarFormat.week],
            label: (f) =>
                f == CalendarFormat.month ? 'Buwanan' : 'Lingguhan',
            onChanged: (v) {
              if (v != null) setState(() => _calendarFormat = v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContentTitle(
    BuildContext context, {
    required String title,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: AppTheme.scale(context, AppTheme.spacingXs)),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNoticeFilterChips(BuildContext context) {
    final scale = AppTheme.scale(context, 1.0);
    return Wrap(
      spacing: scale * 6,
      runSpacing: scale * 6,
      children: _NoticeFilter.values.map((filter) {
        final selected = _selectedNoticeFilter == filter;
        return ChoiceChip(
          label: Text(filter.label),
          selected: selected,
          onSelected: (_) => setState(() => _selectedNoticeFilter = filter),
          labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: selected ? filter.color : AppTheme.textPrimary,
          ),
          backgroundColor: Colors.white,
          selectedColor: filter.color.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(
              color: selected
                  ? filter.color
                  : filter.color.withValues(alpha: 0.35),
            ),
          ),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  Widget _buildUpcomingScheduleCard(
    BuildContext context,
    _UpcomingScheduleItem item,
  ) {
    final scale = AppTheme.scale(context, 1.0);
    return IntrinsicHeight(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.group.color.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: item.group.color.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: scale * 6,
              decoration: BoxDecoration(
                color: item.group.color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(scale * 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18 * scale,
                      backgroundColor: item.group.color.withValues(alpha: 0.18),
                      child: Text(
                        item.personName[0],
                        style: TextStyle(
                          color: item.group.color,
                          fontWeight: FontWeight.w700,
                          fontSize: scale * 14,
                        ),
                      ),
                    ),
                    SizedBox(width: scale * 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                          SizedBox(height: scale * 2),
                          Text(
                            '${item.personName} · ${item.relationLabel}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: item.group.color,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: scale * 4),
                          Text(
                            _formatTagalogDateTime(item.dateTime),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: scale * 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildStatusBadge(
                          context,
                          item.statusLabel,
                          item.statusColor,
                        ),
                        SizedBox(height: scale * 16),
                        Text(
                          '${item.actionLabel} >',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyMemberCard(
    BuildContext context,
    _FamilyMemberOverview member, {
    VoidCallback? onTap,
    bool showPlanButton = true,
  }) {
    final scale = AppTheme.scale(context, 1.0);
    final accent = member.group.color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.all(scale * 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent.withValues(alpha: 0.26), Colors.white],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20 * scale,
                    backgroundColor: accent.withValues(alpha: 0.22),
                    child: Text(
                      member.name[0],
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontSize: scale * 15,
                      ),
                    ),
                  ),
                  SizedBox(width: scale * 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        SizedBox(height: scale * 2),
                        Text(
                          member.profileLabel,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        SizedBox(height: scale * 2),
                        Text(
                          member.detailLine,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: scale * 8),
                  if (onTap != null)
                    Icon(Icons.edit_outlined,
                        size: 18, color: AppTheme.textTertiary),
                ],
              ),
              if (showPlanButton) ...[
                SizedBox(height: scale * 8),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: _openFamilyMembersScreen,
                    child: const Text(
                      'TINGNAN ANG PLANONG PANGKALUSUGAN',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    _AlertNoticeItem item, {
    VoidCallback? onTap,
  }) {
    final scale = AppTheme.scale(context, 1.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.accentColor.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: item.accentColor.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: scale * 6,
                  decoration: BoxDecoration(
                    color: item.accentColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(scale * 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: scale * 38,
                          height: scale * 38,
                          decoration: BoxDecoration(
                            color: item.accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            color: item.accentColor,
                            size: scale * 20,
                          ),
                        ),
                        SizedBox(width: scale * 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                              ),
                              SizedBox(height: scale * 4),
                              Text(
                                item.description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                      height: 1.35,
                                    ),
                              ),
                              SizedBox(height: scale * 6),
                              Text(
                                item.timeLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppTheme.textTertiary),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: scale * 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildStatusBadge(
                              context,
                          item.source == _NoticeSource.appointmentReminder
                              ? (item.isRead
                                  ? 'Appointments'
                                  : 'Appointments · Bago')
                              : (item.isRead ? 'Announcement' : 'Announcement · Bago'),
                          item.source == _NoticeSource.appointmentReminder
                              ? AppTheme.adolescentBlue
                              : AppTheme.accentTeal,
                            ),
                            SizedBox(height: scale * 16),
                            Text(
                              '${item.actionLabel} >',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
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
  }

  Widget _buildStatusBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String message,
    required IconData icon,
  }) {
    final scale = AppTheme.scale(context, 1.0);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: scale * 20),
      child: Column(
        children: [
          Icon(icon, size: scale * 34, color: AppTheme.textTertiary),
          SizedBox(height: scale * 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  void _openFamilyMembersScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FamilyMembersScreen()));
  }

  Widget _buildTraditionalCalendar(BuildContext context) {
    final scale = AppTheme.scale(context, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.calendarBorderDark, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCalendarHeader(context),
          Container(height: 1, color: AppTheme.calendarBannerRedLine),
          TableCalendar<int>(
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) =>
                _selectedDay != null && isSameDay(_selectedDay, d),
            calendarFormat: _calendarFormat,
            eventLoader: (_) => [],
            headerVisible: false,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            daysOfWeekHeight: 32 * scale,
            rowHeight: 58 * scale,
            daysOfWeekStyle: DaysOfWeekStyle(
              dowTextFormatter: (date, locale) => _weekdayLabelForDate(date),
              weekdayStyle: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w700,
                color: AppTheme.calendarBorderDark,
              ),
              weekendStyle: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w700,
                color: AppTheme.calendarSundayRed,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.calendarBorderThin,
                    width: 1,
                  ),
                ),
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: true,
              defaultTextStyle: TextStyle(
                fontSize: 24 * scale,
                fontWeight: FontWeight.w700,
                color: AppTheme.calendarBorderDark,
              ),
              weekendTextStyle: TextStyle(
                fontSize: 24 * scale,
                fontWeight: FontWeight.w700,
                color: AppTheme.calendarSundayRed,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppTheme.calendarBorderThin,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                fontSize: 24 * scale,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              todayDecoration: BoxDecoration(
                color: AppTheme.calendarBorderThin.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                fontSize: 24 * scale,
                fontWeight: FontWeight.w700,
                color: AppTheme.calendarBorderDark,
              ),
              cellMargin: EdgeInsets.zero,
              cellPadding: EdgeInsets.symmetric(
                horizontal: 2 * scale,
                vertical: 2 * scale,
              ),
              markersMaxCount: 0,
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) =>
                  _buildDayCell(context, day, false, false, scale),
              selectedBuilder: (context, day, focusedDay) =>
                  _buildDayCell(context, day, true, false, scale),
              todayBuilder: (context, day, focusedDay) =>
                  _buildDayCell(context, day, false, true, scale),
              outsideBuilder: (context, day, focusedDay) => _buildDayCell(
                context,
                day,
                false,
                false,
                scale,
                isOutside: true,
              ),
            ),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = selected;
              });
              _showEventsModal(context, selected);
            },
            onPageChanged: (focused) {
              setState(() => _focusedDay = focused);
            },
          ),
          if (_calendarFormat == CalendarFormat.month) ...[
            Container(height: 1, color: AppTheme.calendarBorderThin),
          Padding(
            padding: EdgeInsets.all(10 * scale),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _focusedDay = DateTime(
                            _focusedDay.year,
                            _focusedDay.month - 1,
                          );
                      });
                    },
                    child: _buildMiniCalendar(
                        context,
                        DateTime(_focusedDay.year, _focusedDay.month - 1),
                        scale,
                      ),
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _focusedDay = DateTime(
                            _focusedDay.year,
                            _focusedDay.month + 1,
                          );
                      });
                    },
                    child: _buildMiniCalendar(
                        context,
                        DateTime(_focusedDay.year, _focusedDay.month + 1),
                        scale,
                      ),
                  ),
                ),
              ],
            ),
          ),
          ],
          Container(height: 1, color: AppTheme.calendarBorderThin),
          _buildCalendarLegend(context, scale),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    bool selected,
    bool today,
    double scale, {
    bool isOutside = false,
  }) {
    final isSunday = day.weekday == DateTime.sunday;
    final dateColor = isSunday
        ? AppTheme.calendarSundayRed
        : AppTheme.calendarBorderDark;
    final textColor = isOutside
        ? AppTheme.calendarBorderThin.withValues(alpha: 0.5)
        : (selected ? Colors.white : dateColor);
    final dayEvents = isOutside
        ? <CalendarHealthEvent>[]
        : _getVisibleEventsForDay(day);
    // One small circle per age group that has an event on this day (legend order).
    final groupSet = dayEvents.map((e) => e.group).toSet();
    final groupsForDots = HealthEventGroup.values
        .where((g) => groupSet.contains(g))
        .toList();

    Widget number = Text(
      '${day.day}',
      style: TextStyle(
        fontSize: 24 * scale,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    );
    if (selected) {
      number = Container(
        width: 32 * scale,
        height: 32 * scale,
        decoration: BoxDecoration(
          color: AppTheme.calendarBorderThin,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: number,
      );
    } else {
      number = Center(child: number);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.calendarBorderThin, width: 1),
        ),
      padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 2 * scale),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          number,
          if (groupsForDots.isNotEmpty) ...[
            SizedBox(height: 3 * scale),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: groupsForDots.map((g) {
                return Container(
                  width: 7 * scale,
                  height: 7 * scale,
                  margin: EdgeInsets.symmetric(horizontal: 1.5 * scale),
                  decoration: BoxDecoration(
                    color: g.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.calendarBorderThin.withValues(alpha: 0.6),
                      width: 0.5,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Opens a modal dialog with events (and details) for the tapped date.
  void _showEventsModal(BuildContext context, DateTime day) {
    final scale = AppTheme.scale(context, 1.0);
    final events = _getVisibleEventsForDay(day);
    final dateStr = _formatTagalogDate(day);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.scale(context, AppTheme.spacingLg),
                  AppTheme.scale(context, AppTheme.spacingLg),
                  AppTheme.scale(context, AppTheme.spacingLg),
                  AppTheme.scale(context, AppTheme.spacingSm),
                ),
                child: Text(
                  'Mga iskedyul sa $dateStr',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.scale(context, AppTheme.spacingLg),
                    0,
                    AppTheme.scale(context, AppTheme.spacingLg),
                    AppTheme.scale(context, AppTheme.spacingMd),
                  ),
                  child: events.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: scale * 24),
                          child: Text(
                            'Walang nakaiskedyul sa araw na ito.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: events
                              .map(
                                (e) => Padding(
                                  padding: EdgeInsets.only(bottom: scale * 12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 12 * scale,
                                          height: 12 * scale,
                                        margin: EdgeInsets.only(top: 4 * scale),
                                          decoration: BoxDecoration(
                                            color: e.group.color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                            color: AppTheme.calendarBorderThin,
                                            width: 0.5,
                                          ),
                                          ),
                                        ),
                                        SizedBox(width: scale * 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                e.title,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.textPrimary,
                                                    ),
                                              ),
                                              if (e.description != null) ...[
                                                SizedBox(height: 2 * scale),
                                                Text(
                                                  e.description!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: AppTheme
                                                            .textSecondary,
                                                      ),
                                                ),
                                              ],
                                              if (e.time != null || e.facility != null) ...[
                                                SizedBox(height: 4 * scale),
                                                Wrap(
                                                  spacing: 12 * scale,
                                                  runSpacing: 2 * scale,
                                                  children: [
                                                    if (e.time != null)
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.schedule_outlined, size: 12 * scale, color: AppTheme.textSecondary),
                                                          SizedBox(width: 4 * scale),
                                                          Text(e.time!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                                                        ],
                                                      ),
                                                    if (e.facility != null)
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.location_on_outlined, size: 12 * scale, color: AppTheme.textSecondary),
                                                          SizedBox(width: 4 * scale),
                                                          Text(e.facility!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              ],
                                              SizedBox(height: 2 * scale),
                                              Text(
                                                e.group.label,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: e.group.color,
                                                    fontWeight: FontWeight.w600,
                                                    ),
                                              ),
                                              if (e.ageRangeNote != null) ...[
                                                SizedBox(height: 2 * scale),
                                                Text(
                                                  e.ageRangeNote!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: AppTheme.textSecondary,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.scale(context, AppTheme.spacingLg),
                  AppTheme.scale(context, AppTheme.spacingSm),
                  AppTheme.scale(context, AppTheme.spacingLg),
                  AppTheme.scale(context, AppTheme.spacingLg),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Isara'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Legend: status/age groups and their color codes for calendar markers.
  Widget _buildCalendarLegend(BuildContext context, double scale) {
    final visibleGroups = _selectedAudienceFilter.group != null
        ? [_selectedAudienceFilter.group!]
        : HealthEventGroup.values;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 8 * scale),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          spacing: 10 * scale,
          runSpacing: 6 * scale,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: visibleGroups
            .map(
              (g) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12 * scale,
              height: 12 * scale,
              decoration: BoxDecoration(
                color: g.color,
                shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.calendarBorderThin,
                        width: 0.5,
                      ),
              ),
            ),
            SizedBox(width: 4 * scale),
            Text(
              g.label,
              style: TextStyle(
                fontSize: 10 * scale,
                fontWeight: FontWeight.w600,
                color: AppTheme.calendarBorderDark,
              ),
            ),
          ],
              ),
            )
            .toList(),
        ),
      ),
    );
  }

  Widget _buildCalendarHeader(BuildContext context) {
    final year = _focusedDay.year;
    final monthName = _tagalogMonthNames[_focusedDay.month - 1].toUpperCase();
    final scale = AppTheme.scale(context, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 72 * scale,
              child: Center(
                child: Text(
                  '$year',
                  style: TextStyle(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.calendarBorderDark,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10 * scale),
                color: AppTheme.calendarBannerRed,
                child: Text(
                  monthName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17 * scale,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.calendarMonthBannerText,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 72 * scale,
              child: Center(
                child: Text(
                  '$year',
                  style: TextStyle(
                    fontSize: 15 * scale,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.calendarBorderDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniCalendar(
    BuildContext context,
    DateTime month,
    double scale,
  ) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    final weekDay = first.weekday % 7;
    final pad = weekDay % 7;

    final dayCells = <Widget>[];
    for (var i = 0; i < pad; i++) {
      dayCells.add(Container());
    }
    for (var d = 1; d <= last.day; d++) {
      final date = DateTime(month.year, month.month, d);
      final isSun = date.weekday == DateTime.sunday;
      dayCells.add(
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$d',
              style: TextStyle(
                fontSize: 10 * scale,
                fontWeight: FontWeight.w600,
                color: isSun
                    ? AppTheme.calendarSundayRed
                    : AppTheme.calendarBorderDark,
              ),
            ),
          ),
        ),
      );
    }

    // Always 6 rows of dates (7x6 = 42 cells) so both mini calendars have same height
    const dayRows = 6;
    const dayCellsTotal = dayRows * 7;
    while (dayCells.length < dayCellsTotal) {
      dayCells.add(Container());
    }

    final allCells = <Widget>[
      for (var i = 0; i < 7; i++)
        Center(
          child: Text(
            _tagalogWeekdayLabels[i],
            style: TextStyle(
              fontSize: 7 * scale,
              fontWeight: FontWeight.w700,
              color: i == 0
                  ? AppTheme.calendarSundayRed
                  : AppTheme.calendarBorderDark,
            ),
          ),
        ),
      ...dayCells,
    ];

    // 1 header row + 6 date rows = 7 rows total
    const totalRows = 1 + dayRows;
    final tableRows = <TableRow>[];
    for (var r = 0; r < totalRows; r++) {
      tableRows.add(
        TableRow(
          children: List.generate(7, (c) {
            final idx = r * 7 + c;
            return idx < allCells.length ? allCells[idx] : Container();
          }),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 4 * scale),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.calendarBorderThin, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 28 * scale,
                child: Center(
                  child: Text(
                    '${month.year}',
                    style: TextStyle(
                      fontSize: 9 * scale,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.calendarBorderDark,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  padding: EdgeInsets.symmetric(vertical: 4 * scale),
                  color: AppTheme.calendarBannerRed,
                  child: Text(
                    _tagalogMonthShortNames[month.month - 1].toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9 * scale,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.calendarMonthBannerText,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 28 * scale,
                child: Center(
                  child: Text(
                    '${month.year}',
                    style: TextStyle(
                      fontSize: 9 * scale,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.calendarBorderDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4 * scale),
          Table(
            columnWidths: {
              for (var i = 0; i < 7; i++) i: const FlexColumnWidth(1),
            },
            defaultColumnWidth: const FlexColumnWidth(1),
            children: tableRows,
          ),
        ],
      ),
    );
  }
}
