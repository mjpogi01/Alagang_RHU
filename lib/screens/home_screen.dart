import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import 'service_directory_screen.dart';
import 'healthcare_providers_screen.dart';
import 'placeholder_screens.dart';
import 'calendar_screen.dart';
import '../services/supabase_service.dart';

/// New home page: header, slideshow placeholder (Lian RHU / services), and 4 cards.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Gradient background with soft spheres (matches provided CSS design).
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
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        AppTheme.scale(context, AppTheme.spacingLg),
                        AppTheme.scale(context, AppTheme.spacingLg),
                        AppTheme.scale(context, AppTheme.spacingLg),
                        AppTheme.scale(context, AppTheme.spacingLg) +
                            AppTheme.floatingNavBarClearance,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSlideshowPlaceholder(context),
                          _buildSlideshowDots(context),
                          SizedBox(
                            height: AppTheme.scale(context, AppTheme.spacingXl),
                          ),
                          _buildSectionTitle(context),
                          SizedBox(
                            height: AppTheme.scale(context, AppTheme.spacingMd),
                          ),
                          _buildCardsGrid(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context) {
    return Text(
      'MGA PANGUNAHING SERBISYO',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
        fontSize: AppTheme.scale(context, 16),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scale = AppTheme.scale(context, 1.0);
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
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
            top: -50,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -30,
            left: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            right: 60,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
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
                  child: Icon(Icons.add, size: scale * 22, color: Colors.white),
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
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openAbisoFromHome(context),
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
                                Icons.notifications_outlined,
                                size: scale * 22,
                                color: Colors.white,
                              ),
                            ),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: FutureBuilder<int>(
                                future: _countUpcomingNotifications(),
                                builder: (context, snapshot) {
                                  final hasDot =
                                      (snapshot.data ?? 0) > 0;
                                  if (!hasDot) return const SizedBox.shrink();
                                  return Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.notificationBadge,
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: scale * AppTheme.spacingSm),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: scale * 40,
                          height: scale * 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_outline,
                            size: scale * 22,
                            color: Colors.white,
                          ),
                        ),
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

  void _openAbisoFromHome(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CalendarScreen(initialTabIndex: 2),
      ),
    );
  }

  Future<int> _countUpcomingNotifications() async {
    final uid = SupabaseService.client.auth.currentUser?.id;
    if (uid == null) return 0;

    int ageFromDob(DateTime dob) {
      final now = DateTime.now();
      var a = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
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
      return DateTime.tryParse(s.split('T').first);
    }

    int? parseNullableInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final horizon = now.add(const Duration(days: 30));

    // Profile (self).
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

    // Family members.
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

    // Upcoming admin events.
    final calRes = await SupabaseService.client
        .from('calendar_events')
        .select(
          'id, event_date, group_types, group_type, age_range_min, age_range_max, send_announcement',
        );
    final calList = List<Map<String, dynamic>>.from(
      (calRes as dynamic) as List,
    );

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
      final groupKeys = groups.isNotEmpty
          ? groups
          : (fallbackGroup != null ? [fallbackGroup] : <String>[]);
      if (groupKeys.isEmpty) continue;

      bool eventMatches = false;
      for (final p in persons) {
        if (ageMin != null && p.age < ageMin) continue;
        if (ageMax != null && p.age > ageMax) continue;

        if (groupKeys.any(
          (g) => personMatchesGroupKey(g, p.age, p.sex, p.preg),
        )) {
          eventMatches = true;
          break;
        }
      }

      if (!eventMatches) continue;

      final id = ev['id']?.toString() ?? '';
      if (id.isNotEmpty) matchedEventIds.add(id);
    }

    // Subtract already-read admin event notifications.
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

  /// Placeholder for slideshow (Lian RHU, services). Size proportionate to reference.
  Widget _buildSlideshowPlaceholder(BuildContext context) {
    final height = AppTheme.scale(context, 280);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppTheme.spacingRadiusMd),
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.bannerLight,
            borderRadius: BorderRadius.circular(AppTheme.spacingRadiusMd),
            border: Border.all(color: AppTheme.borderLight, width: 1),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.slideshow_outlined,
                  size: AppTheme.scale(context, 40),
                  color: AppTheme.textTertiary,
                ),
                SizedBox(height: AppTheme.scale(context, 8)),
                Text(
                  'Slideshow – Lian RHU & services',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textTertiary,
                    fontSize: AppTheme.scale(context, 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const int _slideshowDotCount = 3;

  Widget _buildSlideshowDots(BuildContext context, {int currentIndex = 0}) {
    final dotSize = AppTheme.scale(context, 8);
    final spacing = AppTheme.scale(context, 6);
    return Padding(
      padding: EdgeInsets.only(top: AppTheme.scale(context, 10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_slideshowDotCount, (i) {
          final active = i == currentIndex;
          return Container(
            margin: EdgeInsets.symmetric(horizontal: spacing / 2),
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? AppTheme.primaryBlue
                  : AppTheme.textTertiary.withValues(alpha: 0.35),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCardsGrid(BuildContext context) {
    final pad = AppTheme.scale(context, AppTheme.spacingMd);
    final cardHeight = AppTheme.scale(context, 170);
    final items = _CardItem.values;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: _buildCard(context, items[0]),
              ),
            ),
            SizedBox(width: pad),
            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: _buildCard(context, items[1]),
              ),
            ),
          ],
        ),
        SizedBox(height: pad),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: _buildCard(context, items[2]),
              ),
            ),
            SizedBox(width: pad),
            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: _buildCard(context, items[3]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, _CardItem item) {
    final data = item.data(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.spacingRadiusMd),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: () => item.onTap(context),
        borderRadius: BorderRadius.circular(AppTheme.spacingRadiusMd),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.spacingRadiusMd),
            border: Border.all(color: AppTheme.borderLight, width: 1),
          ),
          padding: EdgeInsets.all(AppTheme.scale(context, AppTheme.spacingMd)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: AppTheme.scale(context, 48),
                height: AppTheme.scale(context, 48),
                decoration: BoxDecoration(
                  color: data.iconBg,
                  borderRadius: BorderRadius.circular(AppTheme.spacingRadiusSm),
                ),
                child: Icon(
                  data.icon,
                  color: data.iconColor,
                  size: AppTheme.scale(context, 26),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: AppTheme.scale(context, AppTheme.spacingSm),
                  ),
                  child: Text(
                    data.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: AppTheme.scale(context, 14),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.chevron_right,
                  size: AppTheme.scale(context, 24),
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showCalendarSheet(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const CalendarScreen()));
}

enum _CardItem { primaryCare, bulletin, healthcareProviders, calendar }

/// Light backgrounds for service card icons (matches design).
const Color _cardIconBgBlue = Color(0xFFE3F2FD);
const Color _cardIconBgOrange = Color(0xFFFFF3E0);
const Color _cardIconBgGreen = Color(0xFFE8F5E9);
const Color _cardIconBgYellow = Color(0xFFFFFDE7);

extension on _CardItem {
  ({String title, IconData icon, Color iconColor, Color iconBg}) data(
    BuildContext context,
  ) {
    switch (this) {
      case _CardItem.primaryCare:
        return (
          title: 'Serbisyong Pangprimaryang Pangkalusugan',
          icon: Icons.monitor_heart_outlined,
          iconColor: AppTheme.primaryBlue,
          iconBg: _cardIconBgBlue,
        );
      case _CardItem.bulletin:
        return (
          title: 'Health Bulletin Board',
          icon: Icons.school_outlined,
          iconColor: AppTheme.accentBulletin,
          iconBg: _cardIconBgOrange,
        );
      case _CardItem.healthcareProviders:
        return (
          title: 'Healthcare Provider Network',
          icon: Icons.people_outline,
          iconColor: AppTheme.accentBakuna,
          iconBg: _cardIconBgGreen,
        );
      case _CardItem.calendar:
        return (
          title: 'Kalendaryong Pampamilya',
          icon: Icons.calendar_today_outlined,
          iconColor: const Color(0xFFF9A825),
          iconBg: _cardIconBgYellow,
        );
    }
  }

  void onTap(BuildContext context) {
    switch (this) {
      case _CardItem.primaryCare:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ServiceDirectoryScreen()),
        );
        break;
      case _CardItem.bulletin:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlaceholderScreen(
              title: AppStrings.bulletinTitle,
              icon: Icons.campaign,
            ),
          ),
        );
        break;
      case _CardItem.healthcareProviders:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HealthcareProvidersScreen()),
        );
        break;
      case _CardItem.calendar:
        _showCalendarSheet(context);
        break;
    }
  }
}
