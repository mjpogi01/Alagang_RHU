import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'admin_ui.dart';

/// Admin: view families and their members.
class AdminFamiliesScreen extends StatelessWidget {
  const AdminFamiliesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminUI.bg,
      appBar: const AdminAppBar(title: 'Mga Pamilya at Miyembro'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.family_restroom,
                  size: 64, color: AdminUI.textTertiary),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'Listahan ng mga pamilya at miyembro',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AdminUI.textSecondary,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Ikokonekta sa Supabase (families, family_members)',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AdminUI.textTertiary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
