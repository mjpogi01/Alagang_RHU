import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'l10n/app_strings.dart';
import 'screens/bulletin_board_screen.dart';
import 'screens/home_screen.dart';
import 'screens/placeholder_screens.dart';
import 'screens/more_screen.dart';
import 'screens/service_directory_screen.dart';

/// Root scaffold with bottom navigation (Home, Serbisyo, Bulletin, Resources, More).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const List<({String label, IconData icon, Widget screen})> _tabs = [
    (label: AppStrings.navHome, icon: Icons.home_rounded, screen: HomeScreen()),
    (label: AppStrings.navSerbisyo, icon: Icons.medical_services_outlined, screen: const ServiceDirectoryScreen()),
    (label: AppStrings.navBulletin, icon: Icons.campaign_outlined, screen: const BulletinBoardScreen()),
    (label: AppStrings.navResources, icon: Icons.menu_book_outlined, screen: PlaceholderScreen(title: AppStrings.resourcesTitle, icon: Icons.menu_book)),
    (label: AppStrings.navMore, icon: Icons.more_horiz, screen: const MoreScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: Stack(
        children: [
          // Full-height content: no overlay behind it, only the oval nav will sit on top
          IndexedStack(
            index: _currentIndex,
            children: _tabs.map((e) => e.screen).toList(),
          ),
          // Bottom nav: TikTok-style full-width bar on Bulletin tab, else oval
          Positioned(
            left: _currentIndex == 2 ? 0 : 20,
            right: _currentIndex == 2 ? 0 : 20,
            bottom: _currentIndex == 2 ? 0 : 24,
            child: _currentIndex == 2
                ? _buildTikTokStyleNav(context)
                : SafeArea(
                    top: false,
                    child: _buildOvalNav(context),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOvalNav(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: AppTheme.spacingSm, horizontal: AppTheme.spacingXs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) => _navItem(context, i)),
          ),
        ),
      ),
    );
  }

  Widget _buildTikTokStyleNav(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (i) => _navItemTikTok(context, i)),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int i) {
    final t = _tabs[i];
    final selected = i == _currentIndex;
    final activeColor = AppTheme.accentTeal;
    return InkWell(
      onTap: () => setState(() => _currentIndex = i),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm, vertical: AppTheme.spacingSm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? (t.icon == Icons.home_rounded
                      ? Icons.home_rounded
                      : _filledVariant(t.icon))
                  : t.icon,
              size: 24,
              color: selected ? activeColor : AppTheme.textTertiary,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              t.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? activeColor : AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItemTikTok(BuildContext context, int i) {
    final t = _tabs[i];
    final selected = i == _currentIndex;
    const activeColor = Colors.white;
    final inactiveColor = Colors.white.withValues(alpha: 0.5);
    final isCenter = i == 2; // Bulletin = center, can emphasize

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCenter)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected ? activeColor : inactiveColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  t.icon,
                  size: 20,
                  color: selected ? activeColor : inactiveColor,
                ),
              )
            else
              Icon(
                selected ? _filledVariant(t.icon) : t.icon,
                size: 26,
                color: selected ? activeColor : inactiveColor,
              ),
            SizedBox(height: isCenter ? 4 : 2),
            Text(
              t.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _filledVariant(IconData outlined) {
    if (outlined == Icons.medical_services_outlined) return Icons.medical_services;
    if (outlined == Icons.campaign_outlined) return Icons.campaign;
    if (outlined == Icons.menu_book_outlined) return Icons.menu_book;
    return outlined;
  }
}
