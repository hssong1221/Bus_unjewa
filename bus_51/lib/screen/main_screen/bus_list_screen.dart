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

  // Selection mode state
  bool _isSelectionMode = false;
  Set<int> _selectedIndices = {};

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
      body: SafeArea(
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
                if (userSaveModel.isNotEmpty) _buildActionButtons(colorScheme, readProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    final watchProvider = context.watch<BusProvider>();
    var userSaveModel = watchProvider.loadUserDataList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 선택 모드일 때만 선택 정보 표시
        if (_isSelectionMode)
          Text(
            '${_selectedIndices.length}개 선택됨',
            style: context.textStyle.bodyLarge.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          )
        else
          const SizedBox.shrink(),
        Row(
          children: [
            // 선택 모드일 때 취소 버튼만 표시
            if (_isSelectionMode)
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _toggleSelectionMode,
                  icon: Icon(Icons.close, color: colorScheme.onSurface),
                  tooltip: '선택 취소',
                ),
              ),
            // 추가 버튼
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => context.pushNamed(InitSettingScreen.routeName),
                icon: Icon(Icons.add_road, color: colorScheme.onPrimary),
                tooltip: '새 버스 노선 추가하기',
              ),
            ),
          ],
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
    final isSelected = _selectedIndices.contains(index);
    final busColor = BusColor().setColor(item.routeTypeCd);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(index);
            } else {
              readProvider.userDataIdx = index;
              context.pushNamed(BusMainScreen.routeName);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected ? busColor.withValues(alpha: 0.1) : colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? busColor : busColor.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
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
                // Checkbox (선택 모드일 때만 표시)
                if (_isSelectionMode) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? busColor : colorScheme.outline,
                        width: 2,
                      ),
                      color: isSelected ? busColor : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                ],
                // Bus Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: busColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: busColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Route Info
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.routeName.toString(),
                      style: context.textStyle.headlineLarge.copyWith(
                        color: busColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
                // Arrow (선택 모드가 아닐 때만 표시)
                if (!_isSelectionMode)
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

  Widget _buildActionButtons(ColorScheme colorScheme, readProvider) {
    return Column(
      children: [
        const SizedBox(height: 24),
        // 삭제 버튼 (항상 표시)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: _isSelectionMode
              ? FilledButton.icon(
                  onPressed: _selectedIndices.isNotEmpty ? () => _showSelectedDeleteConfirmDialog(context, readProvider) : null,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text(
                    '선택 삭제 (${_selectedIndices.length})',
                    style: context.textStyle.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _selectedIndices.isNotEmpty ? colorScheme.error : colorScheme.surfaceContainerHighest,
                    foregroundColor: _selectedIndices.isNotEmpty ? colorScheme.onError : colorScheme.onSurface.withValues(alpha: 0.4),
                    elevation: _selectedIndices.isNotEmpty ? 3 : 0,
                    shadowColor: colorScheme.error.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                )
              : OutlinedButton(
                  onPressed: _toggleSelectionMode,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    backgroundColor: colorScheme.surface,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    '노선 삭제하기',
                    style: context.textStyle.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
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
            '저장된 버스 노선이 없습니다',
            style: context.textStyle.headlineSmall.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '자주 이용하는 버스 노선을 추가해 보세요',
            style: context.textStyle.bodyLarge.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 220,
            height: 52,
            child: FilledButton.icon(
              onPressed: () => context.pushNamed(InitSettingScreen.routeName),
              icon: const Icon(Icons.add_road, size: 20),
              label: Text(
                '첫 번째 노선 추가하기',
                style: context.textStyle.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                elevation: 3,
                shadowColor: colorScheme.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedIndices.clear();
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _showSelectedDeleteConfirmDialog(BuildContext context, BusProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final userSaveModel = provider.loadUserDataList();
    final selectedRoutes = _selectedIndices.map((index) => userSaveModel[index].routeName).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: colorScheme.error),
              const SizedBox(width: 8),
              const Text('선택 삭제'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('선택한 ${_selectedIndices.length}개의 노선을 삭제하시겠습니까?'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: selectedRoutes
                      .map(
                        (routeName) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• $routeName',
                            style: context.textStyle.bodyMedium.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '이 작업은 실행 취소할 수 없습니다.',
                style: context.textStyle.bodySmall.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                _deleteSelectedRoutes(provider);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  void _deleteSelectedRoutes(BusProvider provider) {
    final userSaveModel = provider.loadUserDataList();
    final sortedIndices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));

    // 인덱스를 역순으로 정렬해서 삭제 (높은 인덱스부터 삭제해야 인덱스 꼬임 방지)
    for (int index in sortedIndices) {
      // 실제 삭제 로직은 BusProvider에 구현되어야 함
      // 현재는 전체 삭제만 있으므로, 개별 삭제 메서드가 필요
    }

    setState(() {
      _isSelectionMode = false;
      _selectedIndices.clear();
    });
  }
}
