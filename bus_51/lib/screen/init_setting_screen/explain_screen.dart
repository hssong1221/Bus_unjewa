import 'package:bus_51/provider/bus_provider.dart';
import 'package:bus_51/provider/init_provider.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --------------------------------------------------
// View
// --------------------------------------------------
class ExplainScreenView extends StatefulWidget {
  const ExplainScreenView({super.key});

  @override
  State<ExplainScreenView> createState() => _ExplainScreenViewState();
}

class _ExplainScreenViewState extends State<ExplainScreenView> with TickerProviderStateMixin {
  // Animation constants
  static const Duration _fadeDuration = Duration(milliseconds: 1200);
  static const Duration _slideDuration = Duration(milliseconds: 1000);
  static const Duration _staggerDelay = Duration(milliseconds: 300);
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(duration: _fadeDuration, vsync: this);
    _slideController = AnimationController(duration: _slideDuration, vsync: this);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
  }

  void _initializeApp() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<BusProvider>().testConnect(item_id: "1", q: "hello world");
      _startAnimations();
    });
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(_staggerDelay, () => _slideController.forward());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.1),
              colorScheme.secondary.withValues(alpha: 0.05),
              colorScheme.surface,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                // App Title
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    "버스언제와",
                    style: context.textStyle.appTitle.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                
                Expanded(child: _buildMainContent(colorScheme)),
                
                // Footer Info
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "GPS와 실시간 교통정보를 이용합니다",
                          style: context.textStyle.caption.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(ColorScheme colorScheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildWelcomeCard(colorScheme),
        const SizedBox(height: 48),
        _buildStartButton(colorScheme),
      ],
    );
  }

  Widget _buildWelcomeCard(ColorScheme colorScheme) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Card.filled(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.7),
                  colorScheme.secondaryContainer.withValues(alpha: 0.5),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bus Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Main Text
                Text(
                  "매일 같은 버스로\n출퇴근하는 직장을 위한",
                  style: context.textStyle.headlineMedium.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Sub Text
                Text(
                  "실시간 버스 도착 정보를\n한눈에 확인하세요",
                  style: context.textStyle.bodyLarge.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton(ColorScheme colorScheme) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: () => context.read<InitProvider>().nextAccountView(),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "시작하기",
                  style: context.textStyle.buttonText.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: colorScheme.onSecondaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
