import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Admin: add or remove healthcare providers/facilities.
class AdminHealthcareProvidersScreen extends StatelessWidget {
  const AdminHealthcareProvidersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      appBar: AppBar(
        title: const Text('Mga Healthcare Provider'),
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
              Icon(Icons.local_hospital_outlined, size: 64, color: AppTheme.textTertiary),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'Magdagdag o mag-alis ng mga pasilidad',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Ikokonekta sa healthcare_facilities o Supabase',
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
