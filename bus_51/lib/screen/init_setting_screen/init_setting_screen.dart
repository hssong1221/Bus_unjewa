import 'package:bus_51/provider/init_provider.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --------------------------------------------------
// Screen
// --------------------------------------------------
class InitSettingScreen extends StatelessWidget {
  const InitSettingScreen({super.key});

  static const String routeName = "init";
  static const String routeURL = "/init";

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => InitProvider(),
        ),
      ],
      child: const InitSettingView(),
    );
  }
}

// --------------------------------------------------
// View
// --------------------------------------------------
class InitSettingView extends StatefulWidget {
  const InitSettingView({super.key});

  @override
  State<InitSettingView> createState() => _InitSettingViewState();
}

class _InitSettingViewState extends State<InitSettingView> with TickerProviderStateMixin {
  late AnimationController _transitionController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOutCubic,
    ));
    _transitionController.forward();
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final watchProvider = context.watch<InitProvider>();

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.05),
                colorScheme.secondary.withValues(alpha: 0.03),
                colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            children: [
              // Progress Indicator
              SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 4, bottom: 0),
                  child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: watchProvider.curIdx > 0 
                                ? () {
                                    _transitionController.reset();
                                    watchProvider.prevAccountView();
                                    _transitionController.forward();
                                  }
                                : null,
                            icon: Icon(
                              Icons.arrow_back,
                              color: watchProvider.curIdx > 0 
                                  ? colorScheme.onSurface 
                                  : colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: (watchProvider.curIdx + 1) / 4,
                                  backgroundColor: colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            '${watchProvider.curIdx + 1}/4',
                            style: context.textStyle.labelSmall.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                  ),
                ),
              ),
              // Content Area
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: watchProvider.curView,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
