import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Admin: edit bulletin board contents (TikTok-style posts).
class AdminBulletinScreen extends StatelessWidget {
  const AdminBulletinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        title: const Text('I-edit ang Bulletin Board'),
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
              Icon(Icons.campaign_outlined, size: 64, color: AppTheme.textTertiary),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'I-edit ang mga post (estilo TikTok)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Vertical feed: video/imahe, caption, order',
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
