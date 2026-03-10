import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.icon,
  });

  final String title;
  final IconData? icon;

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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon ?? Icons.construction,
                    size: 64,
                    color: AppTheme.textTertiary,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'Malapit nang magagamit.',
                    style: Theme.of(context).textTheme.bodyMedium,
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

Widget serbisyoPlaceholder() => PlaceholderScreen(
      title: AppStrings.serviceDirectoryTitle,
      icon: Icons.medical_services,
    );
Widget bulletinPlaceholder() => PlaceholderScreen(
      title: AppStrings.bulletinTitle,
      icon: Icons.campaign,
    );
Widget resourcesPlaceholder() => PlaceholderScreen(
      title: AppStrings.resourcesTitle,
      icon: Icons.menu_book,
    );
Widget morePlaceholder() => PlaceholderScreen(
      title: AppStrings.moreTitle,
      icon: Icons.more_horiz,
    );
