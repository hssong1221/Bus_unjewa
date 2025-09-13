import 'package:bus_51/enums/bus_enums.dart';
import 'package:bus_51/provider/bus_provider.dart';
import 'package:bus_51/screen/init_setting_screen/init_setting_screen.dart';
import 'package:bus_51/screen/main_screen/bus_main_screen.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/utils/bus_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final Set<int> _selectedIndices = {};

  // Back button handling
  DateTime? _lastPressed;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    // 시간대에 맞는 초기 모드 설정
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<BusProvider>();
      // 테스트 데이터 추가 (필요시 주석 해제)
      // if (provider.loadUserDataList().isEmpty) {
      //   await provider.addTestData();
      // }
      provider.setInitialBusMode();
    });
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
    var userSaveModel = watchProvider.getFilteredBusList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final now = DateTime.now();
        const maxDuration = Duration(seconds: 2);
        
        final isWarning = _lastPressed == null || 
            now.difference(_lastPressed!) > maxDuration;

        if (isWarning) {
          _lastPressed = now;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('한번 더 누르면 앱이 종료됩니다'),
              duration: maxDuration,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          // 앱 종료
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
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
                  const SizedBox(height: 16),
                  _buildModeSelector(colorScheme, watchProvider, readProvider),
                  const SizedBox(height: 24),
                  _buildRoutesList(colorScheme, userSaveModel, readProvider),
                  if (userSaveModel.isNotEmpty) _buildActionButtons(colorScheme, readProvider),
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
                onPressed: () => context.pushNamed(
                  InitSettingScreen.routeName,
                  queryParameters: {'startFromStation': 'true'},
                ),
                icon: Icon(Icons.add_road, color: colorScheme.onPrimary),
                tooltip: '새 버스 노선 추가하기',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeSelector(ColorScheme colorScheme, BusProvider watchProvider, BusProvider readProvider) {
    return Row(
      children: [
        // 전체 모드
        Expanded(
          child: _buildModeButton(
            title: '전체',
            mode: BusMode.all,
            isSelected: watchProvider.currentBusMode == BusMode.all,
            colorScheme: colorScheme,
            onTap: () => readProvider.setBusMode(BusMode.all),
          ),
        ),
        const SizedBox(width: 8),
        // 출근 모드
        Expanded(
          child: _buildModeButton(
            title: '출근',
            mode: BusMode.work,
            isSelected: watchProvider.currentBusMode == BusMode.work,
            colorScheme: colorScheme,
            onTap: () => readProvider.setBusMode(BusMode.work),
          ),
        ),
        const SizedBox(width: 8),
        // 퇴근 모드
        Expanded(
          child: _buildModeButton(
            title: '퇴근',
            mode: BusMode.home,
            isSelected: watchProvider.currentBusMode == BusMode.home,
            colorScheme: colorScheme,
            onTap: () => readProvider.setBusMode(BusMode.home),
          ),
        ),
      ],
    );
  }


  Widget _buildModeButton({
    required String title,
    required BusMode mode,
    required bool isSelected,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isSelected 
                ? Colors.teal.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                  ? Colors.teal.withValues(alpha: 0.7)
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            title,
            style: context.textStyle.labelLarge.copyWith(
              color: isSelected 
                  ? Colors.white
                  : colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
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

  Widget _buildRouteItem(item, ColorScheme colorScheme, readProvider, int filteredIndex) {
    // 전체 리스트에서의 실제 인덱스를 찾기
    final allUserSaveModel = readProvider.loadUserDataList();
    final actualIndex = allUserSaveModel.indexWhere((busItem) => 
      busItem.stationId == item.stationId && 
      busItem.routeId == item.routeId && 
      busItem.staOrder == item.staOrder &&
      busItem.busType == item.busType
    );
    
    final isSelected = _selectedIndices.contains(actualIndex);
    final busColor = BusColor().setColor(item.routeTypeCd);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(actualIndex);
            } else {
              readProvider.userDataIdx = actualIndex;
              context.pushNamed(BusMainScreen.routeName);
            }
          },
          onLongPress: () => _showBusTypeChangeDialog(context, readProvider, actualIndex, item),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.routeName.toString(),
                        style: context.textStyle.headlineLarge.copyWith(
                          color: busColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildBusTypeBadge(item.busType, colorScheme),
                    ],
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
        // 삭제 버튼들
        if (_isSelectionMode)
          Row(
            children: [
              // 전체 삭제 버튼 (왼쪽, 작게)
              SizedBox(
                width: 100,
                height: 42,
                child: OutlinedButton(
                  onPressed: () => _showAllDeleteConfirmDialog(context, readProvider),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: colorScheme.error,
                      width: 1,
                    ),
                    foregroundColor: colorScheme.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '전체 삭제',
                    style: context.textStyle.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 선택 삭제 버튼 (오른쪽, 큰 영역)
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _selectedIndices.isNotEmpty ? () => _showSelectedDeleteConfirmDialog(context, readProvider) : null,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: Text(
                      '선택 삭제 (${_selectedIndices.length})',
                      style: context.textStyle.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _selectedIndices.isNotEmpty ? colorScheme.onError : colorScheme.onSurface.withValues(alpha: 0.4),
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
                  ),
                ),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
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
              onPressed: () => context.pushNamed(
                InitSettingScreen.routeName,
                queryParameters: {'startFromStation': 'true'},
              ),
              icon: const Icon(Icons.add_road, size: 20),
              label: Text(
                '첫 번째 노선 추가하기',
                style: context.textStyle.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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

  void _deleteSelectedRoutes(BusProvider provider) async {
    try {
      // BusProvider의 deleteSelectedUserData 메서드 호출
      await provider.deleteSelectedUserData(_selectedIndices.toList());
      
      setState(() {
        _isSelectionMode = false;
        _selectedIndices.clear();
      });

      // 성공 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('선택한 노선이 삭제되었습니다'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      // 오류 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 중 오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showAllDeleteConfirmDialog(BuildContext context, BusProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final userSaveModel = provider.loadUserDataList();

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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('모든 저장된 노선(${userSaveModel.length}개)을 삭제하시겠습니까?'),
              const SizedBox(height: 16),
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
                _deleteAllRoutes(provider);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
              child: const Text('전체 삭제'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAllRoutes(BusProvider provider) {
    try {
      provider.deleteAllData();
      
      setState(() {
        _isSelectionMode = false;
        _selectedIndices.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('모든 노선이 삭제되었습니다'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 중 오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Widget _buildBusTypeBadge(BusType busType, ColorScheme colorScheme) {
    String text;
    Color backgroundColor;
    Color textColor;

    switch (busType) {
      case BusType.work:
        text = '출근';
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case BusType.home:
        text = '퇴근';
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case BusType.none:
        text = '평시';
        backgroundColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurface.withValues(alpha: 0.7);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: context.textStyle.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showBusTypeChangeDialog(BuildContext context, BusProvider provider, int index, item) {
    final colorScheme = Theme.of(context).colorScheme;
    BusType selectedType = item.busType;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.edit_outlined, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('${item.routeName} 버스 타입 변경'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '이 버스의 용도를 선택해 주세요',
                    style: context.textStyle.bodyMedium.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 버스 타입 선택 옵션들
                  _buildTypeOption(
                    title: '평시',
                    subtitle: '일반적인 이용',
                    type: BusType.none,
                    isSelected: selectedType == BusType.none,
                    colorScheme: colorScheme,
                    onTap: () => setDialogState(() => selectedType = BusType.none),
                  ),
                  const SizedBox(height: 8),
                  _buildTypeOption(
                    title: '출근',
                    subtitle: '출근 시간대 이용',
                    type: BusType.work,
                    isSelected: selectedType == BusType.work,
                    colorScheme: colorScheme,
                    onTap: () => setDialogState(() => selectedType = BusType.work),
                  ),
                  const SizedBox(height: 8),
                  _buildTypeOption(
                    title: '퇴근',
                    subtitle: '퇴근 시간대 이용',
                    type: BusType.home,
                    isSelected: selectedType == BusType.home,
                    colorScheme: colorScheme,
                    onTap: () => setDialogState(() => selectedType = BusType.home),
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
                    _changeBusType(provider, index, selectedType);
                    Navigator.of(context).pop();
                  },
                  child: const Text('변경'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTypeOption({
    required String title,
    required String subtitle,
    required BusType type,
    required bool isSelected,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                  width: 2,
                ),
                color: isSelected ? colorScheme.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textStyle.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: context.textStyle.bodySmall.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeBusType(BusProvider provider, int index, BusType newType) async {
    try {
      await provider.updateBusType(index, newType);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('버스 타입이 변경되었습니다'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('타입 변경 중 오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }



}
