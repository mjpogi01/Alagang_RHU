import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../utils/auth_deep_link.dart';

/// Shown after the user opens the app from an email confirmation link.
/// Shows an animated check and a button to proceed to the app.
class EmailConfirmedScreen extends StatefulWidget {
  const EmailConfirmedScreen({
    super.key,
    required this.onProceed,
  });

  final VoidCallback onProceed;

  @override
  State<EmailConfirmedScreen> createState() => _EmailConfirmedScreenState();
}

class _EmailConfirmedScreenState extends State<EmailConfirmedScreen>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late AnimationController _checkController;
  late Animation<double> _circleScale;
  late Animation<double> _circleOpacity;
  late Animation<double> _checkScale;
  late Animation<double> _checkOpacity;
  late Animation<double> _checkStroke;

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _circleScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _circleController,
        curve: Curves.elasticOut,
      ),
    );
    _circleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeOut),
    );
    _checkScale = Tween<double>(begin: 0.3, end: 1).animate(
      CurvedAnimation(
        parent: _checkController,
        curve: Curves.easeOutBack,
      ),
    );
    _checkOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeOut),
    );
    _checkStroke = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeOut),
    );

    _circleController.forward();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _checkController.forward();
    });
  }

  @override
  void dispose() {
    _circleController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = AppTheme.scaleFactor(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.bgGradientStart,
              AppTheme.bgGradientMid,
              AppTheme.bgGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.scale(context, 24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: AppTheme.scale(context, 32)),
                  _AnimatedCheck(
                    circleScale: _circleScale,
                    circleOpacity: _circleOpacity,
                    checkScale: _checkScale,
                    checkOpacity: _checkOpacity,
                    checkStroke: _checkStroke,
                    size: AppTheme.scale(context, 120),
                  ),
                  SizedBox(height: AppTheme.scale(context, 32)),
                  Text(
                    AppStrings.emailConfirmedTitle,
                    style: AppTheme.appTitleStyle(
                      color: Colors.white,
                      fontSize: 26 * scale,
                      context: context,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppTheme.scale(context, 12)),
                  Text(
                    AppStrings.emailConfirmedSubtitle,
                    style: TextStyle(
                      fontSize: 15 * scale,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppTheme.scale(context, 40)),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        AuthDeepLink.clearJustConfirmedEmail();
                        widget.onProceed();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentTeal,
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
                      child: Text(
                        AppStrings.proceedToApp,
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppTheme.scale(context, 48)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated circle with a drawing checkmark inside.
class _AnimatedCheck extends AnimatedWidget {
  _AnimatedCheck({
    required this.circleScale,
    required this.circleOpacity,
    required this.checkScale,
    required this.checkOpacity,
    required this.checkStroke,
    required this.size,
  }) : super(listenable: Listenable.merge([
        circleScale,
        circleOpacity,
        checkScale,
        checkOpacity,
        checkStroke,
      ]));

  final Animation<double> circleScale;
  final Animation<double> circleOpacity;
  final Animation<double> checkScale;
  final Animation<double> checkOpacity;
  final Animation<double> checkStroke;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([circleScale, circleOpacity, checkScale, checkOpacity, checkStroke]),
      builder: (context, child) {
        return Opacity(
          opacity: circleOpacity.value,
          child: Transform.scale(
            scale: circleScale.value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentTeal.withOpacity(0.2),
                border: Border.all(
                  color: AppTheme.accentTeal,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentTeal.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Opacity(
                  opacity: checkOpacity.value,
                  child: Transform.scale(
                    scale: checkScale.value,
                    child: CustomPaint(
                      size: Size(size * 0.5, size * 0.5),
                      painter: _CheckmarkPainter(
                        progress: checkStroke.value,
                        color: Colors.white,
                        strokeWidth: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Draws a checkmark with animated stroke (draws from start to end).
class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.15, h * 0.5)
      ..lineTo(w * 0.4, h * 0.75)
      ..lineTo(w * 0.88, h * 0.2);

    final metric = path.computeMetrics().first;
    final totalLength = metric.length;
    final drawLength = totalLength * progress.clamp(0.0, 1.0);
    final pathToDraw = metric.extractPath(0.0, drawLength);

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(pathToDraw, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
