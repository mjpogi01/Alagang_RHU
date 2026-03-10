import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Admin: edit slideshow contents (home screen carousel).
class AdminSlideshowScreen extends StatelessWidget {
  const AdminSlideshowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        title: const Text('I-edit ang Slideshow'),
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
              Icon(Icons.slideshow_outlined, size: 64, color: AppTheme.textTertiary),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'Idagdag, i-edit, o mag-alis ng mga slide',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Ikokonekta sa table slideshow_slides',
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
