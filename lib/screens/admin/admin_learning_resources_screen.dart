import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Admin: create and manage learning resources and modules for users.
class AdminLearningResourcesScreen extends StatelessWidget {
  const AdminLearningResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        title: const Text('Mga Learning Resource at Module'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined, size: 64, color: AppTheme.textTertiary),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'Gumawa at pamahalaan ang mga materyales para sa mga user',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Mga module, PDF, video, at pagsusulit',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
