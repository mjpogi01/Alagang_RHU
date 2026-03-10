import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../utils/auth_deep_link.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
  });

  /// The address where the confirmation email was sent.
  final String email;

  static const String _gmailUrl = 'https://mail.google.com';

  Future<void> _openGmail(BuildContext context) async {
    // Try to open the default email app first (e.g. Gmail) using a mailto: link.
    // If that fails (no email app), fall back to Gmail in the browser.
    final emailUri = Uri(scheme: 'mailto');
    final webUri = Uri.parse(_gmailUrl);
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Gmail. Check your email app manually.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Gmail. Check your email app manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = AppTheme.scaleFactor(context);
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (AuthDeepLink.justConfirmedEmail) {
          // User came back via confirmation link; go back to root so AuthGate
          // can show the EmailConfirmedScreen (even if no session tokens).
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        }

        return Scaffold(
          backgroundColor: AppTheme.surfaceWhite,
          body: SafeArea(
            child: Column(
              children: [
                // Header with gradient (matches app style)
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.scale(context, 24),
                      vertical: AppTheme.scale(context, 32),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: AppTheme.scale(context, 24)),
                        Icon(
                          Icons.mark_email_unread_rounded,
                          size: 72 * scale,
                          color: AppTheme.primaryBlue.withValues(alpha: 0.9),
                        ),
                        SizedBox(height: AppTheme.scale(context, 24)),
                        Text(
                          AppStrings.verifyEmailTitle,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppTheme.scale(context, 12)),
                        Text(
                          AppStrings.verifyEmailSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppTheme.scale(context, 8)),
                        Text(
                          email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppTheme.scale(context, 40)),
                        FilledButton.icon(
                          onPressed: () => _openGmail(context),
                          icon: const Icon(Icons.mail_outline_rounded, size: 22),
                          label: Text(
                            AppStrings.checkEmail,
                            style: TextStyle(
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: AppTheme.scale(context, 16),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.spacingRadiusMd,
                              ),
                            ),
                            elevation: 0,
                          ),
                        ),
                        SizedBox(height: AppTheme.scale(context, 16)),
                        TextButton(
                          onPressed: () {
                            // Back to welcome screen so user can log in after verifying
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          child: Text(
                            AppStrings.goBack,
                            style: TextStyle(
                              fontSize: 14 * scale,
                              color: AppTheme.textSecondary,
                            ),
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
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final headerH = AppTheme.scale(context, 100);
    return Container(
      width: double.infinity,
      height: headerH,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.headerBlueLight,
            AppTheme.headerBlue,
            AppTheme.primaryBlue,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -15,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Center(
            child: Text(
              AppStrings.appName,
              style: AppTheme.appTitleStyle(
                color: Colors.white,
                fontSize: 22,
                context: context,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
