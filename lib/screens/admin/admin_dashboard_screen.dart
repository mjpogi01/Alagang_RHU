import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'admin_analytics_screen.dart';
import 'admin_bulletin_screen.dart';
import 'admin_calendar_events_screen.dart';
import 'admin_families_screen.dart';
import 'admin_healthcare_providers_screen.dart';
import 'admin_learning_resources_screen.dart';
import 'admin_primary_care_services_screen.dart';
import 'admin_slideshow_screen.dart';
import 'admin_users_screen.dart';
import 'admin_ui.dart';

/// Admin dashboard: menu to all admin features.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, this.hideAppBar = false});

  final bool hideAppBar;

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    if (hideAppBar) return body;
    return Scaffold(
      backgroundColor: AdminUI.bg,
      appBar: AdminAppBar(
        showBack: false,
        title: 'Alagang RHU',
        subtitle: 'Admin Portal',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AdminUI.border,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_none,
                            color: AdminUI.textSecondary),
                      ),
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AdminUI.red,
                            borderRadius: BorderRadius.circular(99),
                            border:
                                Border.all(color: AdminUI.surface, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const _AdminAvatar(initials: 'AD'),
              ],
            ),
          ),
        ],
      ),
      body: body,
    );
  }

  static String _formatDate(DateTime d) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppTheme.scale(context, AppTheme.spacingLg),
        AppTheme.scale(context, AppTheme.spacingLg),
        AppTheme.scale(context, AppTheme.spacingLg),
        AppTheme.scale(context, AppTheme.spacingXxl) +
            AppTheme.floatingNavBarClearance,
      ),
      children: [
        Text(
          'Good morning, Admin',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AdminUI.textPrimary,
                  letterSpacing: -0.5,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDate(DateTime.now()),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AdminUI.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),

          // Three stat cards in one row (equal height)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Expanded(
                  child: _StatCard(
                    label: 'Total Users',
                    value: '1,284',
                    change: 12,
                    icon: Icons.people_outline,
                    color: AdminUI.textTertiary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Family Members',
                    value: '3,891',
                    change: 8,
                    icon: Icons.people_outline,
                    color: AdminUI.emerald,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Facilities',
                    value: '24',
                    change: 4,
                    icon: Icons.local_hospital_outlined,
                    color: AdminUI.amber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // User Activity chart
          AdminCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'User Activity',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AdminUI.textPrimary,
                          ),
                    ),
                    Text(
                      'Last 7 days',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AdminUI.indigo,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final heights = [45.0, 72.0, 58.0, 89.0, 65.0, 94.0, 78.0];
                    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    final isWeekend = i >= 5;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: heights[i] * 0.8,
                              decoration: BoxDecoration(
                                color: isWeekend ? AdminUI.indigo : AdminUI.border,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              labels[i],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: AdminUI.textTertiary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Recent Activity
          AdminCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AdminUI.textPrimary,
                      ),
                ),
                const SizedBox(height: 12),
                _RecentActivityItem(
                  title: 'New user registered',
                  subtitle: 'Maria Santos joined',
                  time: '2m ago',
                  icon: Icons.person_outline,
                  color: AdminUI.indigo,
                ),
                _RecentActivityItem(
                  title: 'Post published',
                  subtitle: 'Vaccination Schedule updated',
                  time: '1h ago',
                  icon: Icons.description_outlined,
                  color: AdminUI.emerald,
                ),
                _RecentActivityItem(
                  title: 'Event added',
                  subtitle: 'Health Fair added for Jul 2',
                  time: '3h ago',
                  icon: Icons.event_outlined,
                  color: AdminUI.amber,
                ),
                _RecentActivityItem(
                  title: 'Provider added',
                  subtitle: 'Dr. Cruz joined the network',
                  time: '5h ago',
                  icon: Icons.local_hospital_outlined,
                  color: AdminUI.blue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'Manage',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AdminUI.textPrimary,
                ),
          ),
          const SizedBox(height: 12),

          _AdminTile(
            title: 'Mga Pamilya at Miyembro',
            subtitle: 'Tingnan ang mga pamilya at miyembro nito',
            icon: Icons.family_restroom,
            color: AdminUI.emerald,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminFamiliesScreen()),
            ),
          ),
          _AdminTile(
            title: 'Analytics',
            subtitle: 'Mga istatistika at ulat',
            icon: Icons.analytics_outlined,
            color: AdminUI.violet,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()),
            ),
          ),
          _AdminTile(
            title: 'Mga Account ng User',
            subtitle: 'Tingnan at burahin ang mga account',
            icon: Icons.people_outline,
            color: AdminUI.rose,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
            ),
          ),
          _AdminTile(
            title: 'Slideshow',
            subtitle: 'I-edit ang mga nilalaman ng slideshow',
            icon: Icons.slideshow_outlined,
            color: AdminUI.amber,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminSlideshowScreen()),
            ),
          ),
          _AdminTile(
            title: 'Bulletin Board',
            subtitle: 'I-edit ang mga post (estilo TikTok)',
            icon: Icons.campaign_outlined,
            color: AdminUI.amber,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminBulletinScreen()),
            ),
          ),
          _AdminTile(
            title: 'Mga Healthcare Provider',
            subtitle: 'Magdagdag o mag-alis ng mga pasilidad',
            icon: Icons.local_hospital_outlined,
            color: AdminUI.emerald,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const AdminHealthcareProvidersScreen()),
            ),
          ),
          _AdminTile(
            title: 'Primary Care Services',
            subtitle: 'I-edit ang mga kategorya at serbisyo sa directory',
            icon: Icons.medical_services_outlined,
            color: AdminUI.teal,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const AdminPrimaryCareServicesScreen()),
            ),
          ),
          _AdminTile(
            title: 'Mga Event sa Kalendaryo',
            subtitle: 'Magtakda ng mga event sa kalendaryo',
            icon: Icons.event_outlined,
            color: AdminUI.blue,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminCalendarEventsScreen()),
            ),
          ),
          _AdminTile(
            title: 'Mga Learning Resource at Module',
            subtitle: 'Gumawa ng mga materyales para sa mga user',
            icon: Icons.menu_book_outlined,
            color: AdminUI.rose,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const AdminLearningResourcesScreen()),
            ),
          ),
        ],
      );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdminCard(
        padding: const EdgeInsets.all(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AdminUI.radiusLg),
          child: Row(
            children: [
              AdminUI.iconPill(icon: icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AdminUI.textPrimary,
                            letterSpacing: -0.2,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AdminUI.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AdminUI.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AdminUI.indigo.withOpacity(0.13),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AdminUI.indigo.withOpacity(0.22), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AdminUI.indigo,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.change,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int? change;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: AdminCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AdminUI.iconPill(icon: icon, color: color, size: 18),
                if (change != null)
                  Text(
                    '${change! > 0 ? '+' : ''}$change%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: change! > 0 ? AdminUI.emerald : AdminUI.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                  ),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AdminUI.textPrimary,
                    letterSpacing: -1,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AdminUI.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityItem extends StatelessWidget {
  const _RecentActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          AdminUI.iconPill(icon: icon, color: color, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AdminUI.textPrimary,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AdminUI.textTertiary,
                      ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AdminUI.textTertiary,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}
