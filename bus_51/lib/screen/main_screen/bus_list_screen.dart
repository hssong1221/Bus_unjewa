import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/screen/init_setting_screen/init_setting_screen.dart';
import 'package:bus_51/screen/main_screen/bus_main_screen.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/theme/app_tokens.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/utils/bus_color.dart';
import 'package:bus_51/viewmodel/bus_list_view_model.dart';
import 'package:bus_51/widget/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
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
    return ChangeNotifierProvider(
      create: (_) => BusListViewModel(GetIt.I<StorageService>()),
      child: const BusListView(),
    );
  }
}

// --------------------------------------------------
// View
// 화면 요소는 "내 버스" 타이틀 + 저장 노선 카드 + 삭제 버튼뿐.
// 카드는 노선번호 / → 종점 방면 / 승차 정류장 3줄 (같은 노선 양방향 구분용)
// --------------------------------------------------
class BusListView extends StatefulWidget {
  const BusListView({super.key});

  @override
  State<BusListView> createState() => _BusListViewState();
}

class _BusListViewState extends State<BusListView> {
  static const double _buttonHeight = 52;

  // Back button handling
  DateTime? _lastPressed;

  /// 노선 추가 플로우로 이동, 돌아오면 저장소 재동기화
  void _goToAddRoute() {
    final viewModel = context.read<BusListViewModel>();
    context
        .pushNamed(
          InitSettingScreen.routeName,
          queryParameters: {'startFromStation': 'true'},
        )
        .then((_) {
      if (mounted) viewModel.reload();
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.lg),
        backgroundColor: isError ? colorScheme.error : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.inner),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewModel = context.watch<BusListViewModel>();

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
          _showSnackBar('한번 더 누르면 앱이 종료됩니다');
        } else {
          // 앱 종료
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colorScheme, viewModel),
                const SizedBox(height: AppSpacing.lg),
                _buildBody(colorScheme, viewModel),
                if (viewModel.hasItems) _buildActionButtons(colorScheme, viewModel),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, BusListViewModel viewModel) {
    final isSelectionMode = viewModel.isSelectionMode;

    return Row(
      children: [
        Expanded(
          child: isSelectionMode
              ? Text(
                  '${viewModel.selectedCount}개 선택됨',
                  style: context.textStyle.titleMedium.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Text(
                  '내 버스',
                  style: context.textStyle.displaySmall.copyWith(
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
        ),
        if (isSelectionMode)
          _buildCircleButton(
            background: colorScheme.surfaceContainerHighest,
            icon: Icon(Icons.close, color: colorScheme.onSurface),
            onPressed: viewModel.toggleSelectionMode,
            tooltip: '선택 취소',
          )
        else
          _buildCircleButton(
            background: colorScheme.primary,
            icon: Icon(Icons.add, color: colorScheme.onPrimary),
            onPressed: _goToAddRoute,
            tooltip: '새 버스 노선 추가하기',
          ),
      ],
    );
  }

  Widget _buildCircleButton({
    required Color background,
    required Icon icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, BusListViewModel viewModel) {
    return Expanded(
      child: switch (viewModel.state) {
        BusListEmpty() => _buildEmptyState(colorScheme),
        BusListSuccess(items: final items) => ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => _buildRouteItem(items[index], colorScheme, viewModel),
          ),
      },
    );
  }

  Widget _buildRouteItem(UserSaveModel item, ColorScheme colorScheme, BusListViewModel viewModel) {
    final isSelectionMode = viewModel.isSelectionMode;
    final isSelected = viewModel.isSelected(item);
    final busColor = BusColor().setColor(item.routeTypeCd);

    return AppCard(
      selected: isSelected,
      onTap: () {
        if (isSelectionMode) {
          viewModel.toggleSelection(item);
        } else {
          context.pushNamed(
            BusMainScreen.routeName,
            queryParameters: {'idx': viewModel.indexOf(item).toString()},
          );
        }
      },
      child: Row(
        children: [
          // 선택 모드: 체크 원
          if (isSelectionMode) ...[
            _buildCheckCircle(colorScheme, isSelected),
            const SizedBox(width: AppSpacing.lg),
          ]
          // 일반 모드: 노선색 버스 아이콘
          else ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: busColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.directions_bus, color: busColor, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          // 노선번호 / → 종점 방면 / 승차 정류장
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.routeName.toString(),
                  style: context.textStyle.headlineLarge.copyWith(
                    color: busColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // 진행 방향 — 같은 노선 양방향을 구분하는 핵심 정보
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '→ ',
                        style: TextStyle(color: busColor),
                      ),
                      TextSpan(text: '${item.routeDestName} 방면'),
                    ],
                  ),
                  style: context.textStyle.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.stationName} 승차',
                  style: context.textStyle.bodySmall.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!isSelectionMode) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
              size: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckCircle(ColorScheme colorScheme, bool isSelected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? colorScheme.primary : colorScheme.outline,
          width: 2,
        ),
        color: isSelected ? colorScheme.primary : Colors.transparent,
      ),
      child: isSelected
          ? Icon(Icons.check, size: 14, color: colorScheme.onPrimary)
          : null,
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme, BusListViewModel viewModel) {
    final hasSelection = viewModel.selectedCount > 0;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: viewModel.isSelectionMode
          ? Row(
              children: [
                // 전체 삭제 (왼쪽, 작게)
                SizedBox(
                  width: 100,
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () => _showAllDeleteConfirmDialog(context, viewModel),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.error.withValues(alpha: 0.4)),
                      foregroundColor: colorScheme.error,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.inner),
                      ),
                    ),
                    child: Text(
                      '전체 삭제',
                      style: context.textStyle.labelMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // 선택 삭제 (오른쪽, 큰 영역)
                Expanded(
                  child: SizedBox(
                    height: _buttonHeight,
                    child: FilledButton.icon(
                      onPressed: hasSelection ? () => _showSelectedDeleteConfirmDialog(context, viewModel) : null,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      label: Text(
                        '선택 삭제 (${viewModel.selectedCount})',
                        style: context.textStyle.labelLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              height: _buttonHeight,
              child: OutlinedButton(
                onPressed: viewModel.toggleSelectionMode,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                  foregroundColor: colorScheme.onSurface.withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                ),
                child: Text(
                  '노선 삭제하기',
                  style: context.textStyle.labelLarge.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_bus,
              size: 42,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '저장된 버스가 없어요',
            style: context.textStyle.headlineSmall.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '자주 타는 버스를 추가해 보세요',
            style: context.textStyle.bodyMedium.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: 200,
            height: _buttonHeight,
            child: FilledButton.icon(
              onPressed: _goToAddRoute,
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                '첫 노선 추가하기',
                style: context.textStyle.labelLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogTitle(ColorScheme colorScheme, String title) {
    return Row(
      children: [
        Icon(Icons.warning_amber_outlined, color: colorScheme.error),
        const SizedBox(width: AppSpacing.sm),
        Text(title),
      ],
    );
  }

  Widget _buildIrreversibleNotice(ColorScheme colorScheme) {
    return Text(
      '이 작업은 실행 취소할 수 없습니다.',
      style: context.textStyle.bodySmall.copyWith(color: colorScheme.error),
    );
  }

  void _showSelectedDeleteConfirmDialog(BuildContext context, BusListViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedRoutes = viewModel.selectedRouteNames;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
          title: _buildDialogTitle(colorScheme, '선택 삭제'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('선택한 ${selectedRoutes.length}개의 노선을 삭제하시겠습니까?'),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.inner),
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
              const SizedBox(height: AppSpacing.sm),
              _buildIrreversibleNotice(colorScheme),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                _deleteSelectedRoutes(viewModel);
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

  Future<void> _deleteSelectedRoutes(BusListViewModel viewModel) async {
    try {
      await viewModel.deleteSelected();
      _showSnackBar('선택한 노선이 삭제되었습니다');
    } catch (e) {
      _showSnackBar('삭제 중 오류가 발생했습니다: $e', isError: true);
    }
  }

  void _showAllDeleteConfirmDialog(BuildContext context, BusListViewModel viewModel) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
          title: _buildDialogTitle(colorScheme, '전체 삭제'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('모든 저장된 노선(${viewModel.totalCount}개)을 삭제하시겠습니까?'),
              const SizedBox(height: AppSpacing.lg),
              _buildIrreversibleNotice(colorScheme),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                _deleteAllRoutes(viewModel);
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

  void _deleteAllRoutes(BusListViewModel viewModel) {
    try {
      viewModel.deleteAll();
      _showSnackBar('모든 노선이 삭제되었습니다');
    } catch (e) {
      _showSnackBar('삭제 중 오류가 발생했습니다: $e', isError: true);
    }
  }
}
