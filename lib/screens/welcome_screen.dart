import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// First screen: choose to log in or sign up.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final padH = AppTheme.scale(context, AppTheme.spacingLg);
    final padV = AppTheme.scale(context, AppTheme.spacingXl);
    return Scaffold(
      backgroundColor: AppTheme.surfaceWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            child: _buildModalCard(context),
          ),
        ),
      ),
    );
  }

  Widget _buildModalCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.spacingRadiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeaderInsideModal(context),
          Padding(
            padding: EdgeInsets.all(AppTheme.scale(context, AppTheme.spacingXl)),
            child: _buildChoiceContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInsideModal(BuildContext context) {
    final headerH = AppTheme.scale(context, 140);
    final pad = AppTheme.scale(context, AppTheme.spacingLg);
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: headerH,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              height: headerH,
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
            Positioned(
              top: -50,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: -30,
              left: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              right: 60,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
          left: 0,
          right: 0,
          bottom: pad,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    AppStrings.appName,
                    style: AppTheme.appTitleStyle(
                      color: Colors.white,
                      fontSize: 24,
                      context: context,
                      shadows: [
                        Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 1)),
                      ],
                    ),
                  ),
                SizedBox(height: AppTheme.scale(context, 4)),
                Text(
                  AppStrings.motto,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: AppTheme.scale(context, 13),
                        shadows: [
                          Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 2, offset: const Offset(0, 1)),
                        ],
                      ),
                ),
                SizedBox(height: AppTheme.scale(context, 2)),
                Text(
                  AppStrings.loginSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: AppTheme.scale(context, 12),
                        shadows: [
                          Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 2, offset: const Offset(0, 1)),
                        ],
                      ),
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

  Widget _buildChoiceContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Piliin ang gusto mong gawin',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 16,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          'Mag-log in kung may account ka na, o gumawa ng bagong account.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: AppTheme.spacingXl),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.login, size: 20, color: Colors.white),
            label: Text(
              AppStrings.loginButton,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.spacingRadiusSm),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SignUpScreen()),
              );
            },
            icon: Icon(Icons.person_add, size: 20, color: AppTheme.primaryBlue),
            label: Text(
              AppStrings.signUpButton,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              side: const BorderSide(color: AppTheme.primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.spacingRadiusSm),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
