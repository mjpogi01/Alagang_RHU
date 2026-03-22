import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'admin_ui.dart';

/// Admin: analytics and reports.
class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key, this.hideAppBar = false});

  final bool hideAppBar;

  @override
  Widget build(BuildContext context) {
    final body = Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.analytics_outlined,
                  size: 64, color: AdminUI.textTertiary),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'Mga istatistika at ulat',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AdminUI.textSecondary,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Charts at metrics ay idadagdag dito',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AdminUI.textTertiary,
                    ),
              ),
            ],
          ),
        ),
      );
    if (hideAppBar) return body;
    return Scaffold(
      backgroundColor: AdminUI.bg,
      appBar: const AdminAppBar(title: 'Analytics'),
      body: body,
    );
  }
}
