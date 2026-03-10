import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';
import '../services/supabase_service.dart';
import '../utils/phone_auth_helper.dart';
import 'login_screen.dart';

/// Sign-up page matching Primary Care Services / Alagang RHU theme.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;
  String? _selectedSex;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _contactEmailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _sexToDbValue(String? label) {
    if (label == null) return null;
    if (label == AppStrings.sexMale) return 'male';
    if (label == AppStrings.sexFemale) return 'female';
    return 'other';
  }

  void _goToStep2() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _currentStep = 1);
    }
  }

  Future<void> _completeSignUp() async {
    if (!(_formKeyStep2.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      // 1. Create auth account using phone-as-email (n09xxxxxxxxx@gmail.com).
      final signInEmail = phoneToSignInEmail(_emailController.text.trim());
      final response = await SupabaseService.client.auth.signUp(
        email: signInEmail,
        password: _passwordController.text,
        data: {'full_name': _nameController.text.trim()},
      );
      final userId = response.user?.id ?? SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account could not be created.'), backgroundColor: Colors.red),
        );
        return;
      }

      // 2. Save profile (age, sex, phone from step 1, contact email, address)
      final age = int.tryParse(_ageController.text.trim());
      final normalizedPhone = normalizePhone(_emailController.text.trim());
      await SupabaseService.client.from('profiles').upsert({
        'user_id': userId,
        'full_name': _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        'email': signInEmail,
        'phone': normalizedPhone ?? _emailController.text.trim(),
        'contact_email': _contactEmailController.text.trim().isEmpty ? null : _contactEmailController.text.trim(),
        'age': age,
        'sex': _sexToDbValue(_selectedSex),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      // 3. Create family (user becomes decision maker) – non-blocking: if it fails, user is still signed in
      try {
        await SupabaseService.client.rpc('create_my_family', params: {'family_name': null});
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created. You can add a family later from More.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      if (!mounted) return;
      // If we have a session, pop back to root so AuthGate shows AppShell (home)
      final hasSession = response.session != null ||
          SupabaseService.client.auth.currentSession != null;
      if (hasSession) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade700),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade700),
      );
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('SignUp error: $e\n$st');
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
                : (msg.length > 80 ? 'Something went wrong. Try again.' : msg),
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
            child: _currentStep == 0 ? _buildFormContent(context) : _buildStep2Content(context),
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

  Widget _buildStep2Content(BuildContext context) {
    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.signUpStep2Title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 18,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppTheme.scale(context, 4)),
          Text(
            AppStrings.signUpStep2Subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          Text(
            AppStrings.age,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Hal. 25',
              prefixIcon: Icon(Icons.cake_outlined, size: 22, color: AppTheme.textTertiary),
              filled: true,
              fillColor: AppTheme.searchBarBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.spacingRadiusSm),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ilagay ang iyong edad.';
              final n = int.tryParse(v.trim());
              if (n == null || n < 1 || n > 150) return 'Ilagay ang wastong edad.';
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            AppStrings.sex,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          DropdownButtonFormField<String>(
            value: _selectedSex,
            decoration: InputDecoration(
              hintText: AppStrings.sexHint,
              prefixIcon: Icon(Icons.wc_outlined, size: 22, color: AppTheme.textTertiary),
              filled: true,
              fillColor: AppTheme.searchBarBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.spacingRadiusSm),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
            ),
            items: [
              DropdownMenuItem(value: AppStrings.sexMale, child: Text(AppStrings.sexMale)),
              DropdownMenuItem(value: AppStrings.sexFemale, child: Text(AppStrings.sexFemale)),
            ],
            onChanged: (value) => setState(() => _selectedSex = value),
            validator: (v) => v == null || v.isEmpty ? 'Piliin ang kasarian.' : null,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            AppStrings.emailLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          TextFormField(
            controller: _contactEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: AppStrings.emailHint,
              prefixIcon: Icon(Icons.email_outlined, size: 22, color: AppTheme.textTertiary),
              filled: true,
              fillColor: AppTheme.searchBarBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.spacingRadiusSm),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final email = v.trim();
              if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(email)) {
                return 'Ilagay ang wastong email.';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            AppStrings.addressLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: AppStrings.addressHint,
              prefixIcon: Icon(Icons.location_on_outlined, size: 22, color: AppTheme.textTertiary),
              filled: true,
              fillColor: AppTheme.searchBarBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.spacingRadiusSm),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Ilagay ang address.' : null,
          ),
          const SizedBox(height: AppTheme.spacingXl),
          SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _completeSignUp,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.person_add, size: 20, color: Colors.white),
              label: Text(
                _isLoading ? 'Finishing...' : AppStrings.signUpButton,
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
              onPressed: _isLoading ? null : () => setState(() => _currentStep = 0),
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
              AppStrings.signUpTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 18,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              AppStrings.nameLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: AppStrings.nameHint,
                prefixIcon: Icon(Icons.person_outline, size: 22, color: AppTheme.textTertiary),
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
              AppStrings.phoneSignInLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _emailController,
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
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              AppStrings.confirmPasswordLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                hintText: AppStrings.confirmPasswordHint,
                prefixIcon: Icon(Icons.lock_outline, size: 22, color: AppTheme.textTertiary),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
            const SizedBox(height: AppTheme.spacingXl),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _goToStep2,
                icon: const Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                label: Text(
                  AppStrings.continueButton,
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
                  AppStrings.hasAccount,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: Text(
                    AppStrings.loginButton,
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
