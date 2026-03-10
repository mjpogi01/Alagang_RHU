import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

/// Shared header styled like the home app bar:
/// gradient background with soft circles, plus-sign logo, app name,
/// and notification/profile icons.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.leading,
    this.trailing,
    this.height,
  });

  /// Optional leading widget (e.g. heart icon on Home).
  final Widget? leading;

  /// Optional trailing widget (e.g. bell on Home, menu on Serbisyo).
  final Widget? trailing;

  /// Header height; defaults to scaled 128.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final identityBarHeight = height ?? AppTheme.scale(context, 80);
    final scale = AppTheme.scale(context, 1.0);

    return SizedBox(
      width: double.infinity,
      height: identityBarHeight,
      child: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.bgGradientStart,
                  AppTheme.bgGradientMid,
                  AppTheme.bgGradientEnd,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Soft circles to match home app bar style
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -20,
            left: -40,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -16,
            right: 40,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Foreground content row: plus logo, title, notifications, profile
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.scale(context, AppTheme.spacingLg),
              vertical: AppTheme.scale(context, AppTheme.spacingMd),
            ),
            child: Row(
              children: [
                Container(
                  width: scale * 40,
                  height: scale * 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    size: scale * 22,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: scale * 10),
                Text(
                  AppStrings.appName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: scale * 20,
                      ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeaderCircleIcon(
                      icon: Icons.notifications_outlined,
                      showDot: true,
                      scale: scale,
                    ),
                    SizedBox(width: AppTheme.scale(context, AppTheme.spacingSm)),
                    _HeaderCircleIcon(
                      icon: Icons.person_outline,
                      scale: scale,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCircleIcon extends StatelessWidget {
  const _HeaderCircleIcon({
    required this.icon,
    required this.scale,
    this.showDot = false,
  });

  final IconData icon;
  final double scale;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: scale * 40,
              height: scale * 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: scale * 22,
                color: Colors.white,
              ),
            ),
            if (showDot)
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.notificationBadge,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
