import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import 'service_directory_screen.dart';
import 'healthcare_providers_screen.dart';
import 'placeholder_screens.dart';
import 'calendar_screen.dart';

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
                        onTap: () {},
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
