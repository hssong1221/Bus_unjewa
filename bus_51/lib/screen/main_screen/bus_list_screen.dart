import 'package:bus_51/provider/bus_provider.dart';
import 'package:bus_51/screen/init_setting_screen/init_setting_screen.dart';
import 'package:bus_51/screen/main_screen/bus_main_screen.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/utils/bus_color.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// --------------------------------------------------
// Screen
// --------------------------------------------------
class BusListScreen extends StatelessWidget {
  const BusListScreen({super.key});

  static const String routeName = "list";
  static const String routeURL = "/list";

  @override
  Widget build(BuildContext context) {
    return const BusListView();
  }
}

// --------------------------------------------------
// View
// --------------------------------------------------
class BusListView extends StatefulWidget {
  const BusListView({super.key});

  @override
  State<BusListView> createState() => _BusListViewState();
}

class _BusListViewState extends State<BusListView> with TickerProviderStateMixin {
  // Animation constants
  static const Duration _fadeDuration = Duration(milliseconds: 800);
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(duration: _fadeDuration, vsync: this);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final readProvider = context.read<BusProvider>();
    final watchProvider = context.watch<BusProvider>();
    var userSaveModel = watchProvider.loadUserDataList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.05),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(colorScheme),
                  const SizedBox(height: 32),
                  _buildRoutesList(colorScheme, userSaveModel, readProvider),
                  if (userSaveModel.isNotEmpty) _buildDeleteButton(colorScheme, readProvider),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bus 언제와',
              style: context.textStyle.headlineMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '저장된 노선 목록',
              style: context.textStyle.bodyLarge.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => context.pushNamed(InitSettingScreen.routeName),
            icon: Icon(Icons.add, color: colorScheme.onPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildRoutesList(ColorScheme colorScheme, userSaveModel, readProvider) {
    return Expanded(
      child: userSaveModel.isEmpty
          ? _buildEmptyState(colorScheme)
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: userSaveModel.length,
              itemBuilder: (context, index) {
                var item = userSaveModel[index];
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0.0, 20 * (1 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: _buildRouteItem(item, colorScheme, readProvider, index),
                );
              },
            ),
    );
  }

  Widget _buildRouteItem(item, ColorScheme colorScheme, readProvider, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            readProvider.userDataIdx = index;
            context.pushNamed(BusMainScreen.routeName);
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BusColor().setColor(item.routeTypeCd).withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Bus Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BusColor().setColor(item.routeTypeCd).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: BusColor().setColor(item.routeTypeCd),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Route Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: BusColor().setColor(item.routeTypeCd).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.routeName.toString(),
                          style: context.textStyle.titleLarge.copyWith(
                            color: BusColor().setColor(item.routeTypeCd),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '노선 ID: ${item.routeId}',
                        style: context.textStyle.bodyMedium.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(ColorScheme colorScheme, readProvider) {
    return Column(
      children: [
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteConfirmDialog(context, readProvider),
            icon: const Icon(Icons.delete_outline),
            label: Text('전체 삭제', style: context.textStyle.labelMedium),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_bus,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '저장된 노선이 없습니다',
            style: context.textStyle.headlineSmall.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새 노선을 추가해 보세요',
            style: context.textStyle.bodyLarge.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => context.pushNamed(InitSettingScreen.routeName),
              icon: const Icon(Icons.add),
              label: const Text('노선 추가하기'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmDialog(BuildContext context, BusProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: colorScheme.error),
              const SizedBox(width: 8),
              const Text('전체 삭제'),
            ],
          ),
          content: const Text('모든 저장된 노선을 삭제하시겠습니까?\n이 작업은 실행 취소할 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                provider.deleteAllData();
                Navigator.of(context).pop();
                context.goNamed(InitSettingScreen.routeName);
              },
              style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }
}