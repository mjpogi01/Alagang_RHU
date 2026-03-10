import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'admin_analytics_screen.dart';
import 'admin_bulletin_screen.dart';
import 'admin_calendar_events_screen.dart';
import 'admin_families_screen.dart';
import 'admin_healthcare_providers_screen.dart';
import 'admin_learning_resources_screen.dart';
import 'admin_slideshow_screen.dart';
import 'admin_users_screen.dart';

/// Admin dashboard: menu to all admin features.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        title: const Text('Admin'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppTheme.scale(context, AppTheme.spacingLg),
          AppTheme.scale(context, AppTheme.spacingMd),
          AppTheme.scale(context, AppTheme.spacingLg),
          AppTheme.scale(context, AppTheme.spacingXxl) +
              AppTheme.floatingNavBarClearance,
        ),
        children: [
          _AdminTile(
            title: 'Mga Pamilya at Miyembro',
            subtitle: 'Tingnan ang mga pamilya at miyembro nito',
            icon: Icons.family_restroom,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AdminFamiliesScreen(),
              ),
            ),
          ),
          _AdminTile(
            title: 'Analytics',
            subtitle: 'Mga istatistika at ulat',
            icon: Icons.analytics_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AdminAnalyticsScreen(),
              ),
            ),
          ),
          _AdminTile(
            title: 'Mga Account ng User',
            subtitle: 'Tingnan at burahin ang mga account',
            icon: Icons.people_outline,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AdminUsersScreen(),
              ),
            ),
          ),
          _AdminTile(
            title: 'Slideshow',
            subtitle: 'I-edit ang mga nilalaman ng slideshow',
            icon: Icons.slideshow_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AdminSlideshowScreen(),
              ),
            ),
          ),
          _AdminTile(
            title: 'Bulletin Board',
            subtitle: 'I-edit ang mga post (estilo TikTok)',
            icon: Icons.campaign_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AdminBulletinScreen(),
              ),
            ),
          ),
          _AdminTile(
            title: 'Mga Healthcare Provider',
            subtitle: 'Magdagdag o mag-alis ng mga pasilidad',
            icon: Icons.local_hospital_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AdminHealthcareProvidersScreen(),
              ),
            ),
          ),
          _AdminTile(
            title: 'Mga Event sa Kalendaryo',
            subtitle: 'Magtakda ng mga event sa kalendaryo',
            icon: Icons.event_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AdminCalendarEventsScreen(),
              ),
            ),
          ),
          _AdminTile(
            title: 'Mga Learning Resource at Module',
            subtitle: 'Gumawa ng mga materyales para sa mga user',
            icon: Icons.menu_book_outlined,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AdminLearningResourcesScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.spacingRadiusMd),
        side: BorderSide(color: AppTheme.borderLight),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.spacingRadiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppTheme.spacingRadiusSm),
                ),
                child: Icon(icon, color: AppTheme.primaryBlue, size: 26),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
