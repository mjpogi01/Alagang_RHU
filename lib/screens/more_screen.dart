import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../services/supabase_service.dart';
import '../widgets/app_header.dart';
import 'admin/admin_dashboard_screen.dart';
import 'family_members_screen.dart';

/// More tab screen.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingLg,
                  AppTheme.spacingLg,
                  AppTheme.spacingLg,
                  AppTheme.spacingLg + AppTheme.floatingNavBarClearance,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppTheme.spacingXl),
                    Text(
                      AppStrings.moreTitle,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'Piliin ang serbisyo.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingXxl),
                    _MoreTile(
                      title: AppStrings.familyMembersTitle,
                      subtitle: AppStrings.familyMembersSubtitle,
                      icon: Icons.people_outline,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FamilyMembersScreen(),
                        ),
                      ),
                    ),
                    _MoreTile(
                      title: 'Admin',
                      subtitle: 'Pamahalaan ang mga pamilya, user, slideshow, bulletin, at iba pa',
                      icon: Icons.admin_panel_settings_outlined,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AdminDashboardScreen(),
                        ),
                      ),
                    ),
                    _MoreTile(
                      title: AppStrings.signOut,
                      subtitle: AppStrings.signOutSubtitle,
                      icon: Icons.logout,
                      onTap: () async {
                        await SupabaseService.client.auth.signOut();
                        // AuthGate will rebuild and show WelcomeScreen
                      },
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
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
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
                  borderRadius: BorderRadius.circular(AppTheme.spacingRadiusSm),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
