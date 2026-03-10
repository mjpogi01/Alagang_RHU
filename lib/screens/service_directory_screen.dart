import 'package:flutter/material.dart';
import '../models/family_member.dart';
import '../theme/app_theme.dart';
import 'family_members_screen.dart';

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

class _ServiceDirectoryScreenState extends State<ServiceDirectoryScreen> {
  _ServiceDirectoryTab _selectedTab = _ServiceDirectoryTab.lahat;

  static const Color _bodyBackground = Color(0xFFF3F4F8);

  final List<_ServiceCategory> _categories = const [
    _ServiceCategory(
      title: 'Mga Serbisyong Pangkomunidad',
      serviceCountLabel: '3 serbisyo',
      color: Color(0xFFFFCCBC),
      icon: Icons.group_outlined,
      items: [
        'Mga Serbisyo para sa Pagsusulong ng Kalusugan',
        'Mga Serbisyo para sa Pagsubaybay sa mga Sakit',
        'Mga Serbisyo para sa Proteksiyong Pangkalusugan',
      ],
    ),
    _ServiceCategory(
      title: 'Mga Serbisyo para sa Indibidwal',
      serviceCountLabel: '4 serbisyo',
      color: Color(0xFFBBDEFB),
      icon: Icons.monitor_heart_outlined,
      items: [
        'Konsultasyong Panlabas',
        'Mga Serbisyo sa Laboratoryo at Pagsusuri',
        'Mga Serbisyo sa Ngipin at Kalusugan ng Bibig',
        'Iba Pang Serbisyong Pangkalusugan para sa Indibidwal',
      ],
    ),
    _ServiceCategory(
      title: 'Pangangalaga sa Ina at Bagong Silang',
      serviceCountLabel: '3 serbisyo',
      color: Color(0xFFF8BBD0),
      icon: Icons.favorite_border,
      items: [
        'Mga Serbisyo sa Pangangalaga Bago Manganak',
        'Pangangalaga sa Panganganak at Pagkatapos Manganak',
        'Pagsusuri at Pagsubaybay sa Bagong Silang',
      ],
    ),
    _ServiceCategory(
      title: 'Mga Serbisyo sa Nutrisyon',
      serviceCountLabel: '2 serbisyo',
      color: Color(0xFFFFF59D),
      icon: Icons.timelapse_outlined,
      items: [
        'Pagsusuri sa Nutrisyon at Pagpapayo',
        'Mga Programa sa Suplementasyon',
      ],
    ),
    _ServiceCategory(
      title: 'Mga Serbisyo sa Pagbabakuna',
      serviceCountLabel: '3 serbisyo',
      color: Color(0xFFB2DFDB),
      icon: Icons.vaccines_outlined,
      items: [
        'Pagbabakuna sa mga Bata',
        'Pagbabakuna sa mga Nasa Hustong Gulang at Nakatatanda',
        'Pagbabakuna sa mga Espesyal na Kampanya',
      ],
    ),
  ];

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
        ..._categories.map((c) {
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

  /// Category indices: 0=Pangkomunidad, 1=Indibidwal, 2=Ina/Bagong Silang, 3=Nutrisyon, 4=Pagbabakuna.
  List<_ServiceCategory> _categoriesForFamily(List<FamilyMember> members) {
    if (members.isEmpty) return [];
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

  Widget _buildFeaturedServicesContent(BuildContext context) {
    final members = widget.familyMembers ?? [];
    final list = _categoriesForFamily(members);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchBar(context),
        SizedBox(height: AppTheme.scale(context, AppTheme.spacingLg)),
        Text(
          'Itinatampok na Serbisyo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: AppTheme.scale(context, 12),
            fontWeight: FontWeight.w700,
            color: AppTheme.textTertiary,
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: AppTheme.scale(context, 4)),
        Text(
          members.isEmpty
              ? 'Mga serbisyong nakalaan para sa mga miyembro ng inyong pamilya.'
              : 'Batay sa mga miyembro ng inyong pamilya.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            height: 1.3,
          ),
        ),
        SizedBox(
          height: AppTheme.scale(context, AppTheme.sectionTitleToContent),
        ),
        if (list.isEmpty)
          _buildFeaturedEmptyState(context)
        else
          ...list.map((c) {
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
                    builder: (_) => const FamilyMembersScreen(),
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
        decoration: InputDecoration(
          hintText: 'Anong serbisyo ang kailangan mo?',
          hintStyle: TextStyle(
            color: AppTheme.textTertiary,
            fontSize: scale * 14,
          ),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textTertiary),
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
  final List<String> items;
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
                        label: c.items[i],
                        color: AppTheme.accentTeal,
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
    required this.label,
    required this.color,
  });

  final int index;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scale = AppTheme.scale(context, 1.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: scale * 28,
          height: scale * 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
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
        SizedBox(width: AppTheme.scale(context, AppTheme.spacingMd)),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: scale * 10,
              horizontal: AppTheme.scale(context, AppTheme.spacingMd),
            ),
            decoration: BoxDecoration(
              color: AppTheme.bannerLight,
              borderRadius: BorderRadius.circular(AppTheme.spacingRadiusSm),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppTheme.scale(context, 13),
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
        SizedBox(width: AppTheme.scale(context, AppTheme.spacingSm)),
        Icon(
          Icons.chevron_right,
          size: scale * 20,
          color: AppTheme.textTertiary,
        ),
      ],
    );
  }
}
