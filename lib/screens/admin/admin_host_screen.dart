import 'package:flutter/material.dart';
import 'admin_ui.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_bulletin_screen.dart';
import 'admin_healthcare_providers_screen.dart';
import 'admin_primary_care_services_screen.dart';
import 'admin_learning_resources_screen.dart';
import 'admin_calendar_events_screen.dart';
import 'admin_slideshow_screen.dart';

/// Admin host: top app bar + tabbed body + bottom nav bar (dark grey, pink pill for selected).
class AdminHostScreen extends StatefulWidget {
  const AdminHostScreen({super.key});

  @override
  State<AdminHostScreen> createState() => _AdminHostScreenState();
}

class _AdminHostScreenState extends State<AdminHostScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminUI.bg,
      appBar: AdminAppBar(
        showBack: true,
        title: 'Alagang RHU',
        subtitle: 'Admin Portal',
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AdminUI.indigo.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.favorite_border, color: AdminUI.indigo, size: 20),
            ),
          ),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none, color: AdminUI.textSecondary),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AdminUI.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: AdminUI.surface, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _AdminHostAvatar(
              initials: 'AD',
              onTap: () => _showBackToAppMenu(context),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          AdminDashboardScreen(hideAppBar: true),
          AdminPrimaryCareServicesScreen(hideAppBar: true),
          AdminHealthcareProvidersScreen(hideAppBar: true),
          AdminCalendarEventsScreen(hideAppBar: true),
          AdminBulletinScreen(hideAppBar: true),
          AdminUsersScreen(hideAppBar: true),
          AdminLearningResourcesScreen(hideAppBar: true),
        ],
      ),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 5) {
            _showMoreTabs(context);
          }
        },
      ),
    );
  }

  void _showMoreTabs(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (sheetContext) {
        Widget buildPill({
          required String label,
          required IconData icon,
          required VoidCallback onTap,
        }) {
          return GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AdminUI.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D4ED8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        final bottomPadding = MediaQuery.of(context).padding.bottom;
        // Position the floating buttons just above the nav bar, regardless of device.
        return IgnorePointer(
          ignoring: false,
          child: Stack(
            children: [
              Positioned(
                right: 16,
                bottom: bottomPadding + 72, // ~nav height + small gap
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      buildPill(
                        label: 'Users',
                        icon: Icons.people_outline,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          setState(() => _currentIndex = 5);
                        },
                      ),
                      const SizedBox(height: 10),
                      buildPill(
                        label: 'Learning Resources',
                        icon: Icons.menu_book_outlined,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          setState(() => _currentIndex = 6);
                        },
                      ),
                      const SizedBox(height: 10),
                      buildPill(
                        label: 'Slideshow',
                        icon: Icons.slideshow_outlined,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AdminSlideshowScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void _showBackToAppMenu(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AdminUI.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline, color: AdminUI.indigo),
              title: const Text('Back to app'),
              subtitle: const Text('Return to Alagang RHU as user'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _AdminHostAvatar extends StatelessWidget {
  const _AdminHostAvatar({required this.initials, this.onTap});

  final String initials;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AdminUI.navBarPillFg.withOpacity(0.2),
        borderRadius: BorderRadius.circular(99),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AdminUI.navBarPillFg,
        ),
      ),
    );
    if (onTap == null) return avatar;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: avatar,
    );
  }
}
