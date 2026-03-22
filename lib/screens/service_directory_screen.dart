import 'package:flutter/material.dart';
import '../models/family_member.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'calendar_screen.dart';
import 'service_schedules_flow.dart';

enum _ServiceDirectoryTab { lahat, itinatampok }

/// Primary Care Services page styled to match the reference layout.
/// [familyMembers] optional; when provided, "Itinatampok" tab shows services tailored to them.
class ServiceDirectoryScreen extends StatefulWidget {
  const ServiceDirectoryScreen({
    super.key,
    this.showHeader = true, // kept for backwards compatibility (ignored)
    this.scrollController,
    this.familyMembers,
  });

  final bool showHeader;
  final ScrollController? scrollController;
  /// When non-null, featured tab shows services tailored to these members.
  final List<FamilyMember>? familyMembers;

  @override
  State<ServiceDirectoryScreen> createState() => _ServiceDirectoryScreenState();
}

/// Icon name from DB -> IconData for service directory.
const Map<String, IconData> _serviceDirectoryIconMap = {
  'group_outlined': Icons.group_outlined,
  'monitor_heart_outlined': Icons.monitor_heart_outlined,
  'favorite_border': Icons.favorite_border,
  'timelapse_outlined': Icons.timelapse_outlined,
  'vaccines_outlined': Icons.vaccines_outlined,
  'description_outlined': Icons.description_outlined,
  'local_hospital_outlined': Icons.local_hospital_outlined,
  'healing_outlined': Icons.healing_outlined,
};

class _ServiceDirectoryScreenState extends State<ServiceDirectoryScreen> {
  _ServiceDirectoryTab _selectedTab = _ServiceDirectoryTab.lahat;

  static const Color _bodyBackground = Color(0xFFF3F4F8);

  List<_ServiceCategory> _categories = const [];
  bool _loading = true;
  bool _fromSupabase = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Featured/recommended tab: DB-backed family members + matching calendar events.
  final List<FamilyMember> _familyMembersForRecommendations = [];
  bool _familyLoading = false;
  String? _familyError;

  bool _recommendedLoading = false;
  String? _recommendedError;
  List<Map<String, dynamic>> _recommendedEvents = [];

  static const List<_ServiceCategory> _defaultCategories = [
    _ServiceCategory(
      title: 'Mga Serbisyong Pangkomunidad',
      serviceCountLabel: '3 serbisyo',
      color: Color(0xFFFFCCBC),
      icon: Icons.group_outlined,
      items: [
        _ServiceItem(name: 'Mga Serbisyo para sa Pagsusulong ng Kalusugan'),
        _ServiceItem(name: 'Mga Serbisyo para sa Pagsubaybay sa mga Sakit'),
        _ServiceItem(name: 'Mga Serbisyo para sa Proteksiyong Pangkalusugan'),
      ],
    ),
    _ServiceCategory(
      title: 'Mga Serbisyo para sa Indibidwal',
      serviceCountLabel: '4 serbisyo',
      color: Color(0xFFBBDEFB),
      icon: Icons.monitor_heart_outlined,
      items: [
        _ServiceItem(name: 'Konsultasyong Panlabas'),
        _ServiceItem(name: 'Mga Serbisyo sa Laboratoryo at Pagsusuri'),
        _ServiceItem(name: 'Mga Serbisyo sa Ngipin at Kalusugan ng Bibig'),
        _ServiceItem(name: 'Iba Pang Serbisyong Pangkalusugan para sa Indibidwal'),
      ],
    ),
    _ServiceCategory(
      title: 'Pangangalaga sa Ina at Bagong Silang',
      serviceCountLabel: '3 serbisyo',
      color: Color(0xFFF8BBD0),
      icon: Icons.favorite_border,
      items: [
        _ServiceItem(name: 'Mga Serbisyo sa Pangangalaga Bago Manganak'),
        _ServiceItem(name: 'Pangangalaga sa Panganganak at Pagkatapos Manganak'),
        _ServiceItem(name: 'Pagsusuri at Pagsubaybay sa Bagong Silang'),
      ],
    ),
    _ServiceCategory(
      title: 'Mga Serbisyo sa Nutrisyon',
      serviceCountLabel: '2 serbisyo',
      color: Color(0xFFFFF59D),
      icon: Icons.timelapse_outlined,
      items: [
        _ServiceItem(name: 'Pagsusuri sa Nutrisyon at Pagpapayo'),
        _ServiceItem(name: 'Mga Programa sa Suplementasyon'),
      ],
    ),
    _ServiceCategory(
      title: 'Mga Serbisyo sa Pagbabakuna',
      serviceCountLabel: '3 serbisyo',
      color: Color(0xFFB2DFDB),
      icon: Icons.vaccines_outlined,
      items: [
        _ServiceItem(name: 'Pagbabakuna sa mga Bata'),
        _ServiceItem(name: 'Pagbabakuna sa mga Nasa Hustong Gulang at Nakatatanda'),
        _ServiceItem(name: 'Pagbabakuna sa mga Espesyal na Kampanya'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadFamilyMembersAndRecommendedEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    try {
      final client = SupabaseService.client;
      final catRes = await client
          .from('primary_care_categories')
          .select()
          .order('sort_order', ascending: true);
      final svcRes = await client.from('primary_care_services').select();
      final allCats = List<Map<String, dynamic>>.from(catRes as List);
      final allSvcs = List<Map<String, dynamic>>.from(svcRes as List);
      // Exclude archived (migration 010 adds archived_at)
      final catList = allCats.where((c) => c['archived_at'] == null).toList()
        ..sort((a, b) => ((a['sort_order'] as int?) ?? 0).compareTo((b['sort_order'] as int?) ?? 0));
      final svcList = allSvcs.where((s) => s['archived_at'] == null).toList();
      if (catList.isEmpty) {
        if (mounted) setState(() {
          _categories = _defaultCategories;
          _fromSupabase = false;
          _loading = false;
        });
        return;
      }
      final categories = <_ServiceCategory>[];
      for (final cat in catList) {
        final id = cat['id'] as String?;
        final title = cat['title'] as String? ?? '';
        final colorHex = (cat['color_hex'] as String?) ?? 'BBDEFB';
        final iconName = cat['icon_name'] as String? ?? 'monitor_heart_outlined';
        final color = _colorFromHex(colorHex);
        final icon = _serviceDirectoryIconMap[iconName] ?? Icons.medical_services_outlined;
        final items = <_ServiceItem>[];
        if (id != null) {
          final forCat = svcList
              .where((s) => s['category_id'] == id)
              .toList()
            ..sort((a, b) =>
                ((a['sort_order'] as int?) ?? 0).compareTo((b['sort_order'] as int?) ?? 0));
          for (final s in forCat) {
            final name = s['name'] as String?;
            if (name != null && name.isNotEmpty) {
              num? price;
              final p = s['price'];
              if (p != null) {
                if (p is num) {
                  price = p > 0 ? p : null;
                } else {
                  final n = num.tryParse(p.toString().trim());
                  price = (n != null && n > 0) ? n : null;
                }
              }
              final desc = s['description'] as String?;
              items.add(_ServiceItem(
                name: name,
                description: desc != null && desc.trim().isNotEmpty ? desc.trim() : null,
                price: price,
              ));
            }
          }
        }
        categories.add(_ServiceCategory(
          title: title,
          serviceCountLabel: '${items.length} serbisyo',
          color: color,
          icon: icon,
          items: items,
        ));
      }
      if (mounted) setState(() {
        _categories = categories;
        _fromSupabase = true;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _categories = _defaultCategories;
        _fromSupabase = false;
        _loading = false;
      });
    }
  }

  static Color _colorFromHex(String hex) {
    String h = hex.trim();
    if (h.startsWith('#')) h = h.substring(1);
    if (h.length == 6) h = 'FF$h';
    return Color(int.tryParse(h, radix: 16) ?? 0xFFBBDEFB);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Gradient background with soft spheres (same as home).
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
                  child: Container(
                    color: _bodyBackground,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildBody(context),
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
                    'Mga Serbisyo sa\nPangunahing Pangangalaga',
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
              const SizedBox(width: 48), // balance spacing right side
            ],
          ),
          SizedBox(height: AppTheme.scale(context, AppTheme.spacingLg)),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher(BuildContext context) {
    final scale = AppTheme.scale(context, 1.0);
    return Row(
      children: [
        Expanded(
          child: _buildTabSwitchItem(
            context,
            tab: _ServiceDirectoryTab.lahat,
            label: 'Lahat ng Serbisyo',
            icon: Icons.apps_outlined,
            iconColor: AppTheme.accentTeal,
          ),
        ),
        SizedBox(width: scale * 8),
        Expanded(
          child: _buildTabSwitchItem(
            context,
            tab: _ServiceDirectoryTab.itinatampok,
            label: 'Itinatampok',
            icon: Icons.star_outline_rounded,
            iconColor: const Color(0xFFE4B400),
          ),
        ),
      ],
    );
  }

  Widget _buildTabSwitchItem(
    BuildContext context, {
    required _ServiceDirectoryTab tab,
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

  Widget _buildBody(BuildContext context) {
    final controller = widget.scrollController ?? ScrollController();
    return Scrollbar(
      thumbVisibility: false,
      controller: controller,
      child: SingleChildScrollView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(
          AppTheme.scale(context, AppTheme.spacingLg),
          0,
          AppTheme.scale(context, AppTheme.spacingLg),
          AppTheme.scale(context, AppTheme.spacingXxl) +
              AppTheme.floatingNavBarClearance,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _selectedTab == _ServiceDirectoryTab.lahat
              ? KeyedSubtree(
                  key: const ValueKey('lahat'),
                  child: _buildAllServicesContent(context),
                )
              : KeyedSubtree(
                  key: const ValueKey('itatampok'),
                  child: _buildFeaturedServicesContent(context),
                ),
        ),
      ),
    );
  }

  Widget _buildAllServicesContent(BuildContext context) {
    final filtered = _applySearch(_categories);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchBar(context),
        SizedBox(height: AppTheme.scale(context, AppTheme.spacingLg)),
        Text(
          'Mga Kategorya ng Serbisyo',
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
        if (_searchQuery.trim().isNotEmpty && filtered.isEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: AppTheme.scale(context, AppTheme.spacingSm),
            ),
            child: Text(
              'Walang serbisyong tugma sa hinanap.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
          )
        else
          ...filtered.map((c) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: AppTheme.scale(context, AppTheme.spacingMd),
            ),
            child: _ServiceCategoryCard(category: c),
          );
        }),
      ],
    );
  }

  /// Category indices (default): 0=Pangkomunidad, 1=Indibidwal, 2=Ina/Bagong Silang, 3=Nutrisyon, 4=Pagbabakuna.
  /// When data is from Supabase, returns all categories for featured tab.
  List<_ServiceCategory> _categoriesForFamily(List<FamilyMember> members) {
    if (members.isEmpty) return [];
    if (_fromSupabase || _categories.length != 5) return List.from(_categories);
    final indices = <int>{};
    for (final m in members) {
      final age = m.age;
      final pregnant = m.pregnancyStatus == true;
      final hasComorbidities = m.comorbidities.isNotEmpty &&
          !m.comorbidities.any((c) => c.toLowerCase() == 'wala');
      if (pregnant) {
        indices.addAll([2, 3]); // Ina at Bagong Silang, Nutrisyon
      }
      if (age <= 2) {
        indices.addAll([2, 3, 4]); // Bagong silang, Nutrisyon, Pagbabakuna
      } else if (age <= 17) {
        indices.addAll([0, 3, 4]); // Pangkomunidad, Nutrisyon, Pagbabakuna
      } else if (age >= 60) {
        indices.addAll([1, 4]); // Indibidwal, Pagbabakuna nakatatanda
      } else {
        indices.addAll([1, 3, 4]); // Indibidwal, Nutrisyon, Pagbabakuna
      }
      if (hasComorbidities) indices.add(1); // Lab, konsultasyon
    }
    final sorted = indices.toList()..sort();
    return sorted.map((i) => _categories[i]).toList();
  }

  /// Applies current search query to the given categories, returning only
  /// categories with at least one matching service (by name or description).
  List<_ServiceCategory> _applySearch(List<_ServiceCategory> source) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return source;
    final List<_ServiceCategory> result = [];
    for (final cat in source) {
      final matchingItems = cat.items.where((item) {
        final name = item.name.toLowerCase();
        final desc = item.description?.toLowerCase() ?? '';
        return name.contains(q) || desc.contains(q);
      }).toList();
      if (matchingItems.isEmpty) continue;
      result.add(
        _ServiceCategory(
          title: cat.title,
          serviceCountLabel: '${matchingItems.length} serbisyo',
          color: cat.color,
          icon: cat.icon,
          items: matchingItems,
        ),
      );
    }
    return result;
  }

  Future<void> _loadFamilyMembersAndRecommendedEvents() async {
    setState(() {
      _familyLoading = true;
      _recommendedLoading = true;
      _familyError = null;
      _recommendedError = null;
    });
    try {
      final familyMembers = widget.familyMembers;
      if (familyMembers != null) {
        _familyMembersForRecommendations
          ..clear()
          ..addAll(familyMembers);
      } else {
        final loaded = await _loadFamilyMembersFromSupabase();
        _familyMembersForRecommendations
          ..clear()
          ..addAll(loaded);
      }
      setState(() {
        _familyLoading = false;
      });

      final events = await _loadRecommendedEventsFromSupabase();
      setState(() {
        _recommendedEvents = events;
        _recommendedLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _familyLoading = false;
        _recommendedLoading = false;
        _familyError = e.toString();
        _recommendedError = e.toString();
      });
    }
  }

  Future<List<FamilyMember>> _loadFamilyMembersFromSupabase() async {
    final client = SupabaseService.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return [];

    final familyId = await _ensureFamilyIdForUser(uid);
    if (familyId == null) return [];

    final res = await client
        .from('family_members')
        .select(
          'id, name, date_of_birth, sex, pregnancy_status, comorbidities',
        )
        .eq('family_id', familyId)
        .order('date_of_birth', ascending: true);
    final rows = List<Map<String, dynamic>>.from(res as List);

    return rows.map((r) {
      final id = r['id']?.toString() ?? '';
      final name = r['name'] as String?;
      final dobRaw = r['date_of_birth']?.toString();
      final dob = dobRaw != null ? DateTime.parse(dobRaw.split('T').first) : DateTime.now();
      final sexDb = r['sex'] as String? ?? 'other';
      final sex = Sex.values.firstWhere((s) => s.name == sexDb, orElse: () => Sex.other);
      final preg = r['pregnancy_status'] as bool?;
      final comorbid =
          (r['comorbidities'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
      return FamilyMember(
        id: id,
        name: name,
        dateOfBirth: dob,
        sex: sex,
        pregnancyStatus: preg,
        comorbidities: comorbid,
      );
    }).toList();
  }

  Future<String?> _ensureFamilyIdForUser(String uid) async {
    final client = SupabaseService.client;

    try {
      final mem = await client
          .from('family_members')
          .select('family_id')
          .eq('user_id', uid)
          .maybeSingle();
      if (mem != null && mem['family_id'] != null) {
        return mem['family_id'] as String;
      }
    } catch (_) {}

    try {
      final fam = await client
          .from('families')
          .select('id')
          .eq('decision_maker_user_id', uid)
          .maybeSingle();
      if (fam != null && fam['id'] != null) {
        return fam['id'] as String;
      }
    } catch (_) {}

    try {
      final createdId =
          await client.rpc('create_my_family', params: {'family_name': null});
      if (createdId is String) return createdId;
      return createdId?.toString();
    } catch (_) {}

    return null;
  }

  bool _isScheduleStillUpcoming(Map<String, dynamic> event) {
    final raw = event['event_date']?.toString();
    if (raw == null || raw.isEmpty) return false;
    final dateKey = raw.split('T').first;
    final parts = dateKey.split('-');
    if (parts.length != 3) return false;
    final day = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    if (day.isBefore(todayStart)) return false;
    if (day.isAfter(todayStart)) return true;

    final endT = event['end_time']?.toString();
    final startT = event['start_time']?.toString();

    DateTime cutoff;
    if (endT != null && endT.trim().isNotEmpty) {
      final h = int.tryParse(endT.split(':').first) ?? 0;
      final m = int.tryParse(endT.split(':').length > 1 ? endT.split(':')[1] : '0') ?? 0;
      cutoff = DateTime(day.year, day.month, day.day, h, m);
    } else if (startT != null && startT.trim().isNotEmpty) {
      final h = int.tryParse(startT.split(':').first) ?? 0;
      final m = int.tryParse(startT.split(':').length > 1 ? startT.split(':')[1] : '0') ?? 0;
      cutoff = DateTime(day.year, day.month, day.day, h, m).add(const Duration(hours: 1));
    } else {
      cutoff = DateTime(day.year, day.month, day.day, 23, 59, 59);
    }
    return now.isBefore(cutoff);
  }

  List<String> _eventGroupKeys(Map<String, dynamic> e) {
    final gt = e['group_types'];
    if (gt is List && gt.isNotEmpty) {
      return gt.map((x) => x.toString()).toList();
    }
    final g = e['group_type'] as String?;
    if (g == null || g.trim().isEmpty) return <String>['adult'];
    return <String>[g];
  }

  bool _memberMatchesGroupKey(FamilyMember m, String groupKey) {
    final age = m.age;
    switch (groupKey) {
      case 'buntis':
        return m.sex == Sex.female && m.pregnancyStatus == true;
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

  bool _isFamilyMemberEligibleForEvent(
    FamilyMember m,
    Map<String, dynamic> event,
  ) {
    final groups = _eventGroupKeys(event);
    if (!groups.any((g) => _memberMatchesGroupKey(m, g))) return false;

    final amin = event['age_range_min'];
    final amax = event['age_range_max'];
    final int? minA = amin is int ? amin : int.tryParse(amin?.toString() ?? '');
    final int? maxA = amax is int ? amax : int.tryParse(amax?.toString() ?? '');
    final age = m.age;

    if (minA != null && age < minA) return false;
    if (maxA != null && age > maxA) return false;
    return true;
  }

  Future<List<Map<String, dynamic>>> _loadRecommendedEventsFromSupabase() async {
    final client = SupabaseService.client;
    final eventsRes = await client
        .from('calendar_events')
        .select(
          'id, event_date, group_type, group_types, title, description, start_time, end_time, facility, age_range_min, age_range_max',
        )
        .order('event_date', ascending: true);
    final events = List<Map<String, dynamic>>.from(eventsRes as List);

    // Only keep events that are still upcoming and match at least one family member.
    final family = _familyMembersForRecommendations;
    final out = <Map<String, dynamic>>[];
    for (final e in events) {
      if (!_isScheduleStillUpcoming(e)) continue;
      final anyEligible = family.any((m) => _isFamilyMemberEligibleForEvent(m, e));
      if (!anyEligible) continue;
      out.add(e);
    }
    return out;
  }

  List<Map<String, dynamic>> _applySearchToEvents(
    List<Map<String, dynamic>> source,
  ) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((e) {
      final title = (e['title'] as String?)?.toLowerCase() ?? '';
      final desc = (e['description'] as String?)?.toLowerCase() ?? '';
      final facility = (e['facility'] as String?)?.toLowerCase() ?? '';
      return title.contains(q) || desc.contains(q) || facility.contains(q);
    }).toList();
  }

  Widget _buildFeaturedServicesContent(BuildContext context) {
    final members = widget.familyMembers ?? _familyMembersForRecommendations;

    if (_familyLoading || _recommendedLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchBar(context),
          SizedBox(height: AppTheme.scale(context, AppTheme.spacingLg)),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (members.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchBar(context),
          SizedBox(height: AppTheme.scale(context, AppTheme.spacingLg)),
          _buildFeaturedEmptyState(context),
        ],
      );
    }

    final events = _applySearchToEvents(_recommendedEvents);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchBar(context),
        SizedBox(height: AppTheme.scale(context, AppTheme.spacingLg)),
        Text(
          'Itinatampok na Iskedyul',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: AppTheme.scale(context, 12),
            fontWeight: FontWeight.w700,
            color: AppTheme.textTertiary,
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: AppTheme.scale(context, 4)),
        Text(
          'Batay sa edad ng mga miyembro ng inyong pamilya.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            height: 1.3,
          ),
        ),
        SizedBox(
          height: AppTheme.scale(context, AppTheme.sectionTitleToContent),
        ),
        if (_searchQuery.trim().isNotEmpty && events.isEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: AppTheme.scale(context, AppTheme.spacingSm),
            ),
            child: Text(
              'Walang iskedyul na tugma sa hinanap.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
          )
        else if (events.isEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: AppTheme.scale(context, AppTheme.spacingSm),
            ),
            child: Text(
              'Walang nakaiskedyul para sa kasalukuyang edad ng inyong pamilya.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
          )
        else
          ...events.asMap().entries.map((entry) {
            final e = entry.value;
            final isLast = entry.key == events.length - 1;
            return Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppTheme.scale(context, AppTheme.spacingMd),
              ),
              child: _RecommendedEventCard(
                event: e,
                onTap: () => showScheduleDetailForBooking(
                  context,
                  event: e,
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFeaturedEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppTheme.scale(context, AppTheme.spacingXl)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.spacingRadiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 56,
            color: AppTheme.textTertiary,
          ),
          SizedBox(height: AppTheme.scale(context, AppTheme.spacingMd)),
          Text(
            'Idagdag ang mga miyembro ng pamilya para makita ang mga serbisyong nakalaan para sa kanila.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          SizedBox(height: AppTheme.scale(context, AppTheme.spacingLg)),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CalendarScreen(
                      initialTabIndex: 1,
                      openAddFamilyMemberModalOnStart: true,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.person_add_outlined, size: 20),
              label: const Text('Puntahan ang Mga Miyembro ng Pamilya'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final scale = AppTheme.scale(context, 1.0);
    return Material(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(28),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Anong serbisyo ang kailangan mo?',
          hintStyle: TextStyle(
            color: AppTheme.textTertiary,
            fontSize: scale * 14,
          ),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textTertiary),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textTertiary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppTheme.scale(context, AppTheme.spacingLg),
            vertical: scale * 14,
          ),
        ),
      ),
    );
  }
}

class _RecommendedEventCard extends StatelessWidget {
  const _RecommendedEventCard({
    required this.event,
    required this.onTap,
  });

  final Map<String, dynamic> event;
  final VoidCallback onTap;

  static const Map<String, Color> _groupColor = {
    'buntis': AppTheme.buntisPink,
    'bata': AppTheme.pediatricGreen,
    'adolescent': AppTheme.adolescentBlue,
    'adult': AppTheme.adultOrange,
    'elderly': AppTheme.elderlyPurple,
  };

  static const Map<String, String> _groupLabel = {
    'buntis': 'Buntis',
    'bata': 'Bata',
    'adolescent': 'Kabataan',
    'adult': 'Nasa hustong gulang',
    'elderly': 'Nakatatanda',
  };

  static const List<String> _months = [
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

  static String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final s = raw.split('T').first;
    final parts = s.split('-');
    if (parts.length != 3) return s;
    final y = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 1;
    final d = int.tryParse(parts[2]) ?? 1;
    if (m < 1 || m > 12) return s;
    return '${_months[m - 1]} $d, $y';
  }

  static String _formatClock(String? dbTime) {
    if (dbTime == null || dbTime.trim().isEmpty) return '';
    final p = dbTime.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0;
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:${m.toString().padLeft(2, '0')} $period';
  }

  static String _formatTimeRange(String? start, String? end) {
    final a = _formatClock(start);
    final b = _formatClock(end);
    if (a.isEmpty && b.isEmpty) return 'Walang itinakdang oras';
    if (b.isEmpty) return a;
    if (a.isEmpty) return b;
    return '$a – $b';
  }

  List<String> _groupKeys() {
    final gt = event['group_types'];
    if (gt is List && gt.isNotEmpty) {
      return gt.map((x) => x.toString()).toList();
    }
    final g = event['group_type'] as String?;
    if (g == null || g.trim().isEmpty) return const ['adult'];
    return [g];
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupKeys();
    final lead = groups.isNotEmpty ? groups.first : 'adult';
    final accent = _groupColor[lead] ?? AppTheme.adultOrange;
    final title = (event['title'] as String?)?.trim().isNotEmpty == true
        ? event['title'] as String
        : 'Iskedyul';
    final facility = (event['facility'] as String?)?.trim();
    final desc = (event['description'] as String?)?.trim();
    final dateStr = _formatDate(event['event_date']?.toString());
    final timeStr = _formatTimeRange(
      event['start_time']?.toString(),
      event['end_time']?.toString(),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dateStr.isEmpty ? 'Petsa' : dateStr,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeStr,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textTertiary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                ],
              ),
              if (facility != null && facility.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: AppTheme.textTertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        facility,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
              if (desc != null && desc.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
              if (groups.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: groups.take(3).map((g) {
                    final c = _groupColor[g] ?? accent;
                    return Chip(
                      label: Text(_groupLabel[g] ?? g,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: c)),
                      backgroundColor: c.withValues(alpha: 0.12),
                      side: BorderSide.none,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One service line: name, optional description, and optional price (null or 0 = free).
class _ServiceItem {
  const _ServiceItem({required this.name, this.description, this.price});

  final String name;
  final String? description;
  final num? price;

  bool get isFree => price == null || (price is num && price! <= 0);
  String get priceBadgeLabel {
    if (isFree) return 'Free';
    final p = price!;
    return '₱${p.toStringAsFixed(p.truncateToDouble() == p ? 0 : 2)}';
  }
}

class _ServiceCategory {
  const _ServiceCategory({
    required this.title,
    required this.serviceCountLabel,
    required this.color,
    required this.icon,
    required this.items,
  });

  final String title;
  final String serviceCountLabel;
  final Color color;
  final IconData icon;
  final List<_ServiceItem> items;
}

class _ServiceCategoryCard extends StatefulWidget {
  const _ServiceCategoryCard({required this.category});

  final _ServiceCategory category;

  @override
  State<_ServiceCategoryCard> createState() => _ServiceCategoryCardState();
}

class _ServiceCategoryCardState extends State<_ServiceCategoryCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final c = widget.category;
    final scale = AppTheme.scale(context, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.spacingRadiusMd * 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _expanded
              ? AppTheme.accentTeal.withValues(alpha: 0.7)
              : Colors.transparent,
          width: _expanded ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(
                AppTheme.spacingRadiusMd * 1.4,
              ),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: EdgeInsets.all(
                  AppTheme.scale(context, AppTheme.spacingLg),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: scale * 44,
                      height: scale * 44,
                      decoration: BoxDecoration(
                        color: c.color,
                        borderRadius: BorderRadius.circular(
                          AppTheme.spacingRadiusSm * 1.3,
                        ),
                      ),
                      child: Icon(
                        c.icon,
                        color: AppTheme.textPrimary,
                        size: scale * 24,
                      ),
                    ),
                    SizedBox(
                      width: AppTheme.scale(context, AppTheme.spacingMd),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: AppTheme.scale(context, 15),
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                          SizedBox(height: scale * 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppTheme.scale(
                                context,
                                AppTheme.spacingSm,
                              ),
                              vertical: scale * 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentTeal.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              c.serviceCountLabel,
                              style: TextStyle(
                                fontSize: AppTheme.scale(context, 11),
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accentTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: AppTheme.scale(context, AppTheme.spacingSm),
                    ),
                    Container(
                      width: scale * 32,
                      height: scale * 32,
                      decoration: BoxDecoration(
                        color: AppTheme.searchBarBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppTheme.textPrimary,
                        size: scale * 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.scale(context, AppTheme.spacingLg),
                AppTheme.scale(context, AppTheme.spacingMd),
                AppTheme.scale(context, AppTheme.spacingLg),
                AppTheme.scale(context, AppTheme.spacingLg),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < c.items.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == c.items.length - 1
                            ? 0
                            : AppTheme.scale(context, AppTheme.spacingSm),
                      ),
                      child: _ServiceItemRow(
                        index: i + 1,
                        item: c.items[i],
                        color: AppTheme.accentTeal,
                        onTap: () {
                          showServiceSchedulesFlow(
                            context,
                            serviceName: c.items[i].name,
                            description: c.items[i].description,
                            isFree: c.items[i].isFree,
                            priceLabel: c.items[i].priceBadgeLabel,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceItemRow extends StatelessWidget {
  const _ServiceItemRow({
    required this.index,
    required this.item,
    required this.color,
    required this.onTap,
  });

  final int index;
  final _ServiceItem item;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = AppTheme.scale(context, 1.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.spacingRadiusSm * 1.2),
        child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.spacingRadiusSm * 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: scale * 8,
          horizontal: AppTheme.scale(context, AppTheme.spacingSm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: scale * 28,
              height: scale * 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: Text(
                  index.toString(),
                  style: TextStyle(
                    fontSize: AppTheme.scale(context, 12),
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppTheme.scale(context, AppTheme.spacingSm)),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: scale * 10,
                  horizontal: AppTheme.scale(context, AppTheme.spacingMd),
                ),
                decoration: BoxDecoration(
                  color: AppTheme.bannerLight,
                  borderRadius:
                      BorderRadius.circular(AppTheme.spacingRadiusSm * 1.1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: AppTheme.scale(context, 13.5),
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                          if (item.description != null &&
                              item.description!.isNotEmpty) ...[
                            SizedBox(height: scale * 4),
                            Text(
                              item.description!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: AppTheme.scale(context, 12),
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(
                        width:
                            AppTheme.scale(context, AppTheme.spacingSm * 0.8)),
                    _ServicePriceBadge(
                      isFree: item.isFree,
                      label: item.priceBadgeLabel,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: AppTheme.scale(context, AppTheme.spacingSm)),
            Container(
              width: scale * 26,
              height: scale * 26,
              decoration: BoxDecoration(
                color: AppTheme.searchBarBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right,
                size: scale * 18,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    ),
      ),
    );
  }
}

class _ServicePriceBadge extends StatelessWidget {
  const _ServicePriceBadge({required this.isFree, required this.label});

  final bool isFree;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scale = AppTheme.scale(context, 1.0);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: scale * 8,
        vertical: scale * 4,
      ),
      decoration: BoxDecoration(
        color: isFree
            ? AppTheme.accentTeal.withValues(alpha: 0.15)
            : AppTheme.textTertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.spacingRadiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: scale * 11,
          fontWeight: FontWeight.w600,
          color: isFree ? AppTheme.accentTeal : AppTheme.textSecondary,
        ),
      ),
    );
  }
}
