import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../services/supabase_service.dart';
import '../utils/phone_auth_helper.dart';
import 'signup_screen.dart';

/// Login page matching Primary Care Services / Alagang RHU theme.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseService.client.auth
          .signInWithPassword(
            email: phoneToSignInEmail(_phoneController.text.trim()),
            password: _passwordController.text,
          )
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;

      final hasSession = response.session != null ||
          SupabaseService.client.auth.currentSession != null;
      if (!hasSession) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Sign in did not complete. Please try again.',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }

      // Pop back to root so AuthGate shows AppShell (home)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Connection timed out. Check your internet and try again.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade700),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      final isNetworkError = msg.contains('SocketException') ||
          msg.contains('Failed host lookup') ||
          msg.contains('No address associated with hostname') ||
          msg.contains('Connection refused') ||
          msg.contains('Network is unreachable');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNetworkError
                ? 'No internet or cannot reach server. Check connection and try again.'
                : msg,
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
            child: _buildFormContent(context),
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

  Widget _buildFormContent(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.loginTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 18,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              AppStrings.phoneSignInLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: validatePhoneForSignIn,
              decoration: InputDecoration(
                hintText: AppStrings.phoneSignInHint,
                prefixIcon: Icon(Icons.phone_outlined, size: 22, color: AppTheme.textTertiary),
                filled: true,
                fillColor: AppTheme.searchBarBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.spacingRadiusSm),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              AppStrings.passwordLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: AppStrings.passwordHint,
                prefixIcon: Icon(Icons.lock_outline, size: 22, color: AppTheme.textTertiary),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 22,
                    color: AppTheme.textTertiary,
                  ),
                ),
                filled: true,
                fillColor: AppTheme.searchBarBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.spacingRadiusSm),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: Text(
                  AppStrings.forgotPassword,
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _signIn,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                label: Text(
                  _isLoading ? 'Signing in...' : AppStrings.loginButton,
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
            if (Navigator.of(context).canPop()) ...[
              const SizedBox(height: AppTheme.spacingMd),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back, size: 20, color: AppTheme.primaryBlue),
                  label: Text(
                    AppStrings.goBack,
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
            const SizedBox(height: AppTheme.spacingXl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.noAccount,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const SignUpScreen(),
                      ),
                    );
                  },
                  child: Text(
                    AppStrings.signUpButton,
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}
