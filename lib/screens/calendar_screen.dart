import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'family_members_screen.dart';
import '../theme/app_theme.dart';

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
  });

  final HealthEventGroup group;
  final String title;
  final String? description;
}

/// Mock health events by date (replace with API/DB). Key: 'yyyy-MM-dd'.
Map<String, List<CalendarHealthEvent>> get _mockHealthEventsWithDetails {
  final now = DateTime.now();
  final year = now.year;
  final month = now.month;
  final m = month.toString().padLeft(2, '0');
  return {
    '$year-$m-05': [
      CalendarHealthEvent(
        group: HealthEventGroup.buntis,
        title: 'Pagsusuring prenatal (Buntis)',
        description: 'Lian RHU · 8:00 AM – 12:00 PM',
      ),
      CalendarHealthEvent(
        group: HealthEventGroup.bata,
        title: 'Pagbabakuna ng bata',
        description: 'Buwanang araw ng pagbabakuna sa RHU',
      ),
    ],
    '$year-$m-10': [
      CalendarHealthEvent(
        group: HealthEventGroup.adolescent,
        title: 'Klinika para sa kabataan',
        description: 'Lian RHU · Ayon sa takdang oras',
      ),
    ],
    '$year-$m-15': [
      CalendarHealthEvent(
        group: HealthEventGroup.buntis,
        title: 'Pagsusuring prenatal (Buntis)',
        description: 'Lian RHU · 8:00 AM – 12:00 PM',
      ),
    ],
    '$year-$m-20': [
      CalendarHealthEvent(
        group: HealthEventGroup.bata,
        title: 'Regular na konsultasyon ng bata',
        description: 'Istasyon ng Kalusugan ng Barangay',
      ),
      CalendarHealthEvent(
        group: HealthEventGroup.adult,
        title: 'Mga serbisyo sa pagpaplano ng pamilya',
        description: 'Lian RHU · Lunes hanggang Biyernes',
      ),
    ],
    '$year-$m-22': [
      CalendarHealthEvent(
        group: HealthEventGroup.elderly,
        title: 'Pagsusuri ng presyon ng dugo at kalusugan ng nakatatanda',
        description: 'Lian RHU · 9:00 AM',
      ),
    ],
    '$year-$m-25': [
      CalendarHealthEvent(
        group: HealthEventGroup.adult,
        title: 'Pagsubaybay sa TB-DOTS',
        description: 'Istasyon ng Kalusugan ng Barangay',
      ),
      CalendarHealthEvent(
        group: HealthEventGroup.elderly,
        title: 'Klinika para sa nakatatanda',
        description: 'Lian RHU · 10:00 AM',
      ),
    ],
    '$year-$m-28': [
      CalendarHealthEvent(
        group: HealthEventGroup.buntis,
        title: 'Pagsusuring prenatal (Buntis)',
        description: 'Lian RHU · 8:00 AM – 12:00 PM',
      ),
      CalendarHealthEvent(
        group: HealthEventGroup.adolescent,
        title: 'Pagbabakuna ng kabataan',
        description: 'Lian RHU · Ayon sa takdang oras',
      ),
    ],
  };
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

enum _NoticeFilter { lahat, paalala, rhu, seasonal, nalagpasan }

extension _NoticeFilterX on _NoticeFilter {
  String get label {
    switch (this) {
      case _NoticeFilter.lahat:
        return 'Lahat';
      case _NoticeFilter.paalala:
        return 'Paalala';
      case _NoticeFilter.rhu:
        return 'Abiso ng RHU';
      case _NoticeFilter.seasonal:
        return 'Pang-panahon';
      case _NoticeFilter.nalagpasan:
        return 'Nalagpasan';
    }
  }

  Color get color {
    switch (this) {
      case _NoticeFilter.lahat:
        return AppTheme.primaryBlue;
      case _NoticeFilter.paalala:
        return const Color(0xFF7EB8DA);
      case _NoticeFilter.rhu:
        return AppTheme.accentTeal;
      case _NoticeFilter.seasonal:
        return AppTheme.adultOrange;
      case _NoticeFilter.nalagpasan:
        return AppTheme.accentEmergency;
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

class _MemberCarePlanItem {
  const _MemberCarePlanItem({
    required this.title,
    required this.dateTime,
    required this.statusLabel,
    required this.statusColor,
  });

  final String title;
  final DateTime dateTime;
  final String statusLabel;
  final Color statusColor;
}

class _FamilyMemberOverview {
  const _FamilyMemberOverview({
    required this.name,
    required this.profileLabel,
    required this.detailLine,
    required this.group,
    required this.summaryBadge,
    required this.summaryBadgeColor,
    required this.highlights,
    required this.careItems,
  });

  final String name;
  final String profileLabel;
  final String detailLine;
  final HealthEventGroup group;
  final String summaryBadge;
  final Color summaryBadgeColor;
  final List<String> highlights;
  final List<_MemberCarePlanItem> careItems;
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
  });

  final _NoticeFilter filter;
  final String title;
  final String description;
  final String timeLabel;
  final IconData icon;
  final Color accentColor;
  final String actionLabel;
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
  });

  final bool showAppBar;
  final ScrollController? scrollController;
  final Color? backgroundColor;

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

  List<CalendarHealthEvent> _getEventsForDay(DateTime day) {
    final key =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return _mockHealthEventsWithDetails[key] ?? [];
  }

  List<CalendarHealthEvent> _getVisibleEventsForDay(DateTime day) {
    final events = _getEventsForDay(day);
    final group = _selectedAudienceFilter.group;
    if (group == null) return events;
    return events.where((event) => event.group == group).toList();
  }

  List<_UpcomingScheduleItem> get _upcomingSchedules {
    final now = DateTime.now();
    return [
      _UpcomingScheduleItem(
        personName: 'Pedro Pascual',
        relationLabel: 'Lolo',
        title: 'Bakunang Pneumococcal',
        dateTime: DateTime(now.year, now.month, 15, 9, 0),
        group: HealthEventGroup.elderly,
        statusLabel: 'Nalagpasan',
        statusColor: AppTheme.accentEmergency,
        actionLabel: 'Tingnan',
      ),
      _UpcomingScheduleItem(
        personName: 'Pedro Pascual',
        relationLabel: 'Lolo',
        title: 'Pagsusubaybay sa Presyon ng Dugo',
        dateTime: DateTime(now.year, now.month, 20, 10, 0),
        group: HealthEventGroup.elderly,
        statusLabel: 'Ngayon',
        statusColor: AppTheme.adultOrange,
        actionLabel: 'Tingnan',
      ),
      _UpcomingScheduleItem(
        personName: 'Sofia Pascual',
        relationLabel: 'Anak',
        title: 'Dagdag na bakuna laban sa tigdas',
        dateTime: DateTime(now.year, now.month, 25, 13, 0),
        group: HealthEventGroup.bata,
        statusLabel: 'Paparating (7 araw)',
        statusColor: AppTheme.adolescentBlue,
        actionLabel: 'Tingnan',
      ),
      _UpcomingScheduleItem(
        personName: 'Isabella Pascual',
        relationLabel: 'Anak',
        title: 'Bakunang HPV (Unang Dosis)',
        dateTime: DateTime(now.year, now.month, 28, 11, 0),
        group: HealthEventGroup.adolescent,
        statusLabel: 'Paparating (7 araw)',
        statusColor: AppTheme.adolescentBlue,
        actionLabel: 'Tingnan',
      ),
      _UpcomingScheduleItem(
        personName: 'Luis Pascual',
        relationLabel: 'Ama',
        title: 'Pagsusuri ng asukal sa dugo (FBS)',
        dateTime: DateTime(now.year, now.month, 26, 8, 0),
        group: HealthEventGroup.adult,
        statusLabel: 'Paparating',
        statusColor: AppTheme.elderlyPurple,
        actionLabel: 'Tingnan',
      ),
    ];
  }

  List<_UpcomingScheduleItem> get _visibleUpcomingSchedules {
    final group = _selectedAudienceFilter.group;
    if (group == null) return _upcomingSchedules;
    return _upcomingSchedules.where((item) => item.group == group).toList();
  }

  List<_FamilyMemberOverview> get _familyMemberOverviews {
    final now = DateTime.now();
    return [
      _FamilyMemberOverview(
        name: 'Pedro Pascual',
        profileLabel: 'Nakatatanda (60+) | 67 taon',
        detailLine: 'Lalaki | Ipinanganak Nobyembre 9, 1958',
        group: HealthEventGroup.elderly,
        summaryBadge: '1 nalagpasan',
        summaryBadgeColor: AppTheme.accentEmergency,
        highlights: const ['Pulmonya', 'Paparating'],
        careItems: [
          _MemberCarePlanItem(
            title: 'Bakunang Pneumococcal',
            dateTime: DateTime(now.year, now.month, 20, 10, 0),
            statusLabel: 'Nalagpasan',
            statusColor: AppTheme.accentEmergency,
          ),
          _MemberCarePlanItem(
            title: 'Pagsusubaybay sa Presyon ng Dugo',
            dateTime: DateTime(now.year, now.month, 30, 8, 0),
            statusLabel: 'Paparating',
            statusColor: AppTheme.elderlyPurple,
          ),
        ],
      ),
      _FamilyMemberOverview(
        name: 'Luis Pascual',
        profileLabel: 'Nasa hustong gulang (20-59) | 35 taon',
        detailLine: 'Lalaki | Hulyo 22, 1991',
        group: HealthEventGroup.adult,
        summaryBadge: '2 alerto',
        summaryBadgeColor: AppTheme.adultOrange,
        highlights: const ['FBS', 'BP'],
        careItems: [
          _MemberCarePlanItem(
            title: 'Pagsusubaybay sa Presyon ng Dugo',
            dateTime: DateTime(now.year, now.month, 20, 8, 0),
            statusLabel: 'Paparating',
            statusColor: AppTheme.elderlyPurple,
          ),
          _MemberCarePlanItem(
            title: 'Pagsusuri ng asukal sa dugo (FBS)',
            dateTime: DateTime(now.year, now.month, 26, 8, 0),
            statusLabel: 'Paparating',
            statusColor: AppTheme.elderlyPurple,
          ),
        ],
      ),
      _FamilyMemberOverview(
        name: 'Baby Sofia',
        profileLabel: 'Bata (0-9) | 2 taon',
        detailLine: 'Babae | Pebrero 25, ${now.year - 2}',
        group: HealthEventGroup.bata,
        summaryBadge: '2 sa 7 araw',
        summaryBadgeColor: AppTheme.adolescentBlue,
        highlights: const ['Bakuna', 'Dagdag na bakuna'],
        careItems: [
          _MemberCarePlanItem(
            title: 'Dagdag na bakuna laban sa tigdas',
            dateTime: DateTime(now.year, now.month, 25, 13, 0),
            statusLabel: 'Paparating',
            statusColor: AppTheme.adolescentBlue,
          ),
        ],
      ),
    ];
  }

  List<_AlertNoticeItem> get _alertNotices => [
    const _AlertNoticeItem(
      filter: _NoticeFilter.paalala,
      title: 'Bakuna ni Baby Sofia',
      description:
          'Hindi nakumpleto ang dagdag na bakuna laban sa tigdas ni Baby Sofia. Nais mo bang magpa-iskedyul muli?',
      timeLabel: 'Ngayon',
      icon: Icons.vaccines_outlined,
      accentColor: Color(0xFF3D74B6),
      actionLabel: 'Mag-iskedyul',
    ),
    const _AlertNoticeItem(
      filter: _NoticeFilter.paalala,
      title: 'Pagsusuri ng asukal sa dugo ni Luis',
      description:
          'Ang iyong pagsusuri ng asukal sa dugo (FBS) ay naka-iskedyul sa Miyerkules, Agosto 20, 2026, 7:00 ng umaga.',
      timeLabel: '2 araw bago',
      icon: Icons.water_drop_outlined,
      accentColor: Color(0xFF244A74),
      actionLabel: 'Tingnan',
    ),
    const _AlertNoticeItem(
      filter: _NoticeFilter.rhu,
      title: 'Misyong Medikal sa Lian RHU',
      description:
          'Misyong Medikal sa Lian RHU: Abril 25, 8:00 ng umaga hanggang 12:00 ng tanghali.',
      timeLabel: 'Kahapon',
      icon: Icons.local_hospital_outlined,
      accentColor: Color(0xFF2E8B57),
      actionLabel: 'Tingnan',
    ),
    const _AlertNoticeItem(
      filter: _NoticeFilter.seasonal,
      title: 'Alerto sa Panahon ng Tag-ulan',
      description:
          'Ngayong panahon ng tag-ulan, inaasahang dadami ang mga kaso ng dengue. Siguraduhing malinis ang kapaligiran upang makaiwas sa impeksiyon.',
      timeLabel: '3 araw na ang nakalipas',
      icon: Icons.cloud_outlined,
      accentColor: Color(0xFFF39C12),
      actionLabel: 'Tingnan',
    ),
    const _AlertNoticeItem(
      filter: _NoticeFilter.nalagpasan,
      title: 'Lampas na ang Iskedyul: Lolo Pedro',
      description:
          'Ang bakunang Pneumococcal ni Lolo Pedro ay dapat na maibigay noong isang buwan ngunit hindi natuloy.',
      timeLabel: 'Isang linggo na ang nakalipas',
      icon: Icons.error_outline,
      accentColor: AppTheme.accentEmergency,
      actionLabel: 'Mag-iskedyul',
    ),
  ];

  List<_AlertNoticeItem> get _visibleAlertNotices {
    if (_selectedNoticeFilter == _NoticeFilter.lahat) return _alertNotices;
    return _alertNotices
        .where((item) => item.filter == _selectedNoticeFilter)
        .toList();
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
        child: SingleChildScrollView(
          controller: controller,
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
              onPressed: _openFamilyMembersScreen,
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Pamahalaan'),
            ),
          ],
        ),
        SizedBox(height: AppTheme.scale(context, AppTheme.spacingSm)),
        ..._familyMemberOverviews.asMap().entries.map((entry) {
          final isLast = entry.key == _familyMemberOverviews.length - 1;
          return Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? 0 : AppTheme.scale(context, AppTheme.spacingSm),
            ),
            child: _buildFamilyMemberCard(context, entry.value),
          );
        }),
      ],
    );
  }

  Widget _buildAlertsTabContent(BuildContext context) {
    final notices = _visibleAlertNotices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildContentTitle(
          context,
          title: 'Mga Abiso',
          subtitle: 'Mga paalala, abiso ng RHU, at mga alertong pang-panahon',
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
              child: _buildAlertCard(context, entry.value),
            );
          }),
      ],
    );
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
    _FamilyMemberOverview member,
  ) {
    final scale = AppTheme.scale(context, 1.0);
    final accent = member.group.color;
    return Container(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: scale * 2),
                    Text(
                      member.profileLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: scale * 2),
                    Text(
                      member.detailLine,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: scale * 8),
              _buildStatusBadge(
                context,
                member.summaryBadge,
                member.summaryBadgeColor,
              ),
            ],
          ),
          if (member.highlights.isNotEmpty) ...[
            SizedBox(height: scale * 10),
            Wrap(
              spacing: scale * 6,
              runSpacing: scale * 6,
              children: member.highlights
                  .map(
                    (highlight) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: scale * 10,
                        vertical: scale * 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        highlight,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          SizedBox(height: scale * 10),
          Divider(color: accent.withValues(alpha: 0.28), height: 1),
          SizedBox(height: scale * 8),
          ...member.careItems.asMap().entries.map((entry) {
            final isLast = entry.key == member.careItems.length - 1;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : scale * 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          _formatTagalogDateTime(item.dateTime),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: scale * 8),
                  _buildStatusBadge(
                    context,
                    item.statusLabel,
                    item.statusColor,
                  ),
                ],
              ),
            );
          }),
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
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, _AlertNoticeItem item) {
    final scale = AppTheme.scale(context, 1.0);
    return IntrinsicHeight(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.accentColor.withValues(alpha: 0.18)),
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
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                          SizedBox(height: scale * 4),
                          Text(
                            item.description,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  height: 1.35,
                                ),
                          ),
                          SizedBox(height: scale * 6),
                          Text(
                            item.timeLabel,
                            style: Theme.of(context).textTheme.bodySmall
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
                          item.filter.label,
                          item.filter.color,
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
    final groupsForDots = dayEvents.map((e) => e.group).toSet().toList();

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
            SizedBox(height: 2 * scale),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: groupsForDots
                  .take(5)
                  .map(
                    (g) => Container(
                width: 6 * scale,
                height: 6 * scale,
                margin: EdgeInsets.symmetric(horizontal: 1 * scale),
                decoration: BoxDecoration(
                  color: g.color,
                  shape: BoxShape.circle,
                ),
                    ),
                  )
                  .toList(),
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
      child: Wrap(
        spacing: 10 * scale,
        runSpacing: 6 * scale,
        alignment: WrapAlignment.center,
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
