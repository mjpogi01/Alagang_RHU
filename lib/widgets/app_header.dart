import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../services/supabase_service.dart';
import '../screens/calendar_screen.dart';

/// Shared header styled like the home app bar:
/// gradient background with soft circles, plus-sign logo, app name,
/// and notification/profile icons.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.leading,
    this.trailing,
    this.height,
    this.onNotificationsTap,
  });

  /// Optional leading widget (e.g. heart icon on Home).
  final Widget? leading;

  /// Optional trailing widget (e.g. bell on Home, menu on Serbisyo).
  final Widget? trailing;

  /// Header height; defaults to scaled 128.
  final double? height;

  /// Optional callback when the bell icon is tapped.
  /// Defaults to opening Calendar "Mga Abiso".
  final VoidCallback? onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final identityBarHeight = height ?? AppTheme.scale(context, 80);
    final scale = AppTheme.scale(context, 1.0);

    return SizedBox(
      width: double.infinity,
      height: identityBarHeight,
      child: Stack(
        children: [
          // Gradient background
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
          // Soft circles to match home app bar style
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -20,
            left: -40,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -16,
            right: 40,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Foreground content row: plus logo, title, notifications, profile
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.scale(context, AppTheme.spacingLg),
              vertical: AppTheme.scale(context, AppTheme.spacingMd),
            ),
            child: Row(
              children: [
                Container(
                  width: scale * 40,
                  height: scale * 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    size: scale * 22,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: scale * 10),
                Text(
                  AppStrings.appName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: scale * 20,
                      ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FutureBuilder<int>(
                      future: _countUpcomingNotificationsSoon(),
                      builder: (context, snapshot) {
                        final hasDot = (snapshot.data ?? 0) > 0;
                        return _HeaderCircleIcon(
                          icon: Icons.notifications_outlined,
                          showDot: hasDot,
                          scale: scale,
                          onTap: onNotificationsTap ??
                              () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CalendarScreen(initialTabIndex: 2),
                                    ),
                                  ),
                        );
                      },
                    ),
                    SizedBox(width: AppTheme.scale(context, AppTheme.spacingSm)),
                    _HeaderCircleIcon(
                      icon: Icons.person_outline,
                      scale: scale,
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

class _HeaderCircleIcon extends StatelessWidget {
  const _HeaderCircleIcon({
    required this.icon,
    required this.scale,
    this.showDot = false,
    this.onTap,
  });

  final IconData icon;
  final double scale;
  final bool showDot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: scale * 40,
              height: scale * 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: scale * 22,
                color: Colors.white,
              ),
            ),
            if (showDot)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.notificationBadge,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<int> _countUpcomingNotificationsSoon() async {
  final uid = SupabaseService.client.auth.currentUser?.id;
  if (uid == null) return 0;

  int ageFromDob(DateTime dob) {
    final now = DateTime.now();
    var a = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      a--;
    }
    return a;
  }

  bool personMatchesGroupKey(String groupKey, int age, String sex, bool? preg) {
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

  DateTime? parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString();
    if (s.isEmpty) return null;
    final justDate = s.split('T').first;
    return DateTime.tryParse(justDate);
  }

  int? parseNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final horizon = now.add(const Duration(days: 30));

  // Load user's own profile age/sex.
  int? profileAge;
  String? profileSex;
  final profRes = await SupabaseService.client
      .from('profiles')
      .select('age, sex')
      .eq('user_id', uid)
      .maybeSingle();
  profileAge = profRes?['age'] as int?;
  profileSex = profRes?['sex'] as String?;

  final persons = <({int age, String sex, bool? preg})>[];

  if (profileAge != null && profileSex != null) {
    persons.add((age: profileAge, sex: profileSex, preg: null));
  }

  // Load family members to determine age/pregnancy groups for eligibility.
  String? familyId;
  try {
    final fam = await SupabaseService.client
        .from('families')
        .select('id')
        .eq('decision_maker_user_id', uid)
        .maybeSingle();
    familyId = fam?['id'] as String?;
  } catch (_) {}

  if (familyId == null) {
    try {
      final mem = await SupabaseService.client
          .from('family_members')
          .select('family_id')
          .eq('user_id', uid)
          .maybeSingle();
      familyId = mem?['family_id'] as String?;
    } catch (_) {}
  }

  if (familyId != null) {
    final membersRes = await SupabaseService.client
        .from('family_members')
        .select('date_of_birth, sex, pregnancy_status')
        .eq('family_id', familyId);

    final members = List<Map<String, dynamic>>.from(
      (membersRes as dynamic) as List,
    );
    for (final m in members) {
      final dob = parseDate(m['date_of_birth']);
      if (dob == null) continue;
      final sex = (m['sex'] as String?) ?? 'other';
      final preg = m['pregnancy_status'] as bool?;
      persons.add((age: ageFromDob(dob), sex: sex, preg: preg));
    }
  }

  if (persons.isEmpty) return 0;

  // Count upcoming admin events (calendar_events) relevant to the user.
  final calRes = await SupabaseService.client
      .from('calendar_events')
      .select(
        'id, event_date, group_types, group_type, age_range_min, age_range_max, send_announcement',
      );

  final calList = List<Map<String, dynamic>>.from((calRes as dynamic) as List);
  final matchedEventIds = <String>{};

  for (final ev in calList) {
    final sendAnn = ev['send_announcement'] as bool? ?? false;
    if (!sendAnn) continue;

    final evDate = parseDate(ev['event_date']);
    if (evDate == null) continue;
    if (evDate.isBefore(startOfToday)) continue;
    if (evDate.isAfter(horizon)) continue;

    final ageMin = parseNullableInt(ev['age_range_min']);
    final ageMax = parseNullableInt(ev['age_range_max']);

    final rawGt = ev['group_types'];
    final List<String> groups = rawGt is List
        ? rawGt.map((x) => x.toString()).toList()
        : rawGt is String
            ? rawGt
                .trim()
                .replaceAll('{', '')
                .replaceAll('}', '')
                .split(',')
                .map((x) => x.trim())
                .where((x) => x.isNotEmpty)
                .toList()
            : <String>[];
    final fallbackGroup = ev['group_type'] as String?;
    final groupKeys =
        groups.isNotEmpty ? groups : (fallbackGroup != null ? [fallbackGroup] : <String>[]);
    if (groupKeys.isEmpty) continue;

    bool eventMatches = false;
    for (final p in persons) {
      if (ageMin != null && p.age < ageMin) continue;
      if (ageMax != null && p.age > ageMax) continue;

      if (groupKeys.any((g) => personMatchesGroupKey(g, p.age, p.sex, p.preg))) {
        eventMatches = true;
        break;
      }
    }

    if (eventMatches) {
      final id = ev['id']?.toString() ?? '';
      if (id.isNotEmpty) matchedEventIds.add(id);
    }
  }

  // Subtract already-read admin notifications for this user.
  final readRes = await SupabaseService.client
      .from('admin_calendar_event_notification_reads')
      .select('calendar_event_id')
      .eq('user_id', uid);
  final readRows =
      List<Map<String, dynamic>>.from((readRes as dynamic) as List);
  final readIds = <String>{};
  for (final r in readRows) {
    final id = r['calendar_event_id']?.toString() ?? '';
    if (id.isEmpty) continue;
    readIds.add(id);
  }

  int unreadCount = 0;
  for (final id in matchedEventIds) {
    if (!readIds.contains(id)) unreadCount++;
  }

  return unreadCount;
}
