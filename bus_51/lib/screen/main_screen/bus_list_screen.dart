import 'package:bus_51/model/user_save_model.dart';
import 'package:bus_51/repository/bus_arrival_repository.dart';
import 'package:bus_51/screen/init_setting_screen/init_setting_screen.dart';
import 'package:bus_51/screen/main_screen/bus_main_screen.dart';
import 'package:bus_51/service/storage_service.dart';
import 'package:bus_51/theme/app_tokens.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/utils/arrival_time.dart';
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
      create: (_) => BusListViewModel(GetIt.I<StorageService>(), GetIt.I<BusArrivalRepository>()),
      child: const BusListView(),
    );
  }
}

// --------------------------------------------------
// View
// 화면 요소는 "내 버스" 타이틀 + 우측 상단 편집 알약 + 저장 노선 카드 + 우측 하단 노선 추가 플로팅 버튼.
// 편집을 누르면 선택 모드 (헤더 "N개 선택됨 / 완료", 하단 삭제 바, 플로팅 버튼 숨김, 손잡이 드래그로 순서 변경).
// 카드는 왼쪽에 노선번호 / → 종점 방면 / 승차 정류장 3줄 (같은 노선 양방향 구분용),
// 오른쪽에 다음 버스 남은 시간 / 몇 정거장 전 (들어가지 않아도 바로 보이게). 선택 모드에선 시간을 숨긴다
// --------------------------------------------------
class BusListView extends StatefulWidget {
  const BusListView({super.key});

  @override
  State<BusListView> createState() => _BusListViewState();
}

class _BusListViewState extends State<BusListView> {
  static const double _buttonHeight = 52;
  static const double _fabSize = 56;

  /// 리스트 마지막 카드가 플로팅 버튼에 가려지지 않도록 비워두는 하단 여백
  static const double _fabClearance = 96;

  /// 카드 우측 도착 정보 영역 최소 폭 (상태가 바뀌어도 왼쪽 텍스트가 흔들리지 않게)
  static const double _arrivalMinWidth = 78;

  // Back button handling
  DateTime? _lastPressed;

  /// 앱이 백그라운드로 가면 갱신을 멈추고, 다시 보이면 재조회한다 (보지 않는 동안 API 를 쓰지 않도록).
  /// onResume 이 아니라 onShow 를 쓰는 이유: 알림창을 내렸다 올리는 것만으로도 inactive ↔ resumed 가
  /// 오가며 onResume 이 불리는데, 그때는 멈춘 적이 없으니 다시 조회할 이유가 없다
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onHide: () => context.read<BusListViewModel>().pause(),
      onShow: _resumeIfVisible,
    );
    context.read<BusListViewModel>().loadArrivals();
  }

  /// 상세·노선 추가 화면이 위에 떠 있으면 그 화면에서 돌아올 때 resume 하므로 여기서는 건너뛴다
  void _resumeIfVisible() {
    if (ModalRoute.of(context)?.isCurrent ?? true) {
      context.read<BusListViewModel>().resume();
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  /// 노선 추가 플로우로 이동, 돌아오면 저장소 재동기화 + 도착 정보 다시 조회.
  /// 다른 화면에 있는 동안은 갱신을 멈춘다 (노선 수만큼 API 를 부르므로)
  void _goToAddRoute() {
    final viewModel = context.read<BusListViewModel>()..pause();
    context
        .pushNamed(
          InitSettingScreen.routeName,
          queryParameters: {'startFromStation': 'true'},
        )
        .then((_) {
      if (!mounted) return;
      viewModel.reload();
      viewModel.resume();
    });
  }

  /// 상세(메인) 화면으로 이동. 돌아오면 도착 정보 다시 조회
  void _goToDetail(UserSaveModel item) {
    final viewModel = context.read<BusListViewModel>()..pause();
    context
        .pushNamed(
          BusMainScreen.routeName,
          queryParameters: {'idx': viewModel.indexOf(item).toString()},
        )
        .then((_) {
      if (mounted) viewModel.resume();
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
    // 빈 상태는 가운데 "첫 노선 추가하기"가 있고, 선택 모드는 삭제 중이므로 플로팅 버튼을 숨긴다
    final showFab = viewModel.hasItems && !viewModel.isSelectionMode;

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
        floatingActionButton: showFab ? _buildAddFab(colorScheme) : null,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colorScheme, viewModel),
                const SizedBox(height: AppSpacing.lg),
                _buildBody(colorScheme, viewModel, showFab: showFab),
                if (viewModel.isSelectionMode) _buildDeleteBar(colorScheme, viewModel),
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
        // 우측 상단: 편집(선택 모드 진입) / 완료(순서·삭제는 즉시 반영되므로 되돌릴 게 없어 취소가 아니다). 빈 상태는 비운다
        if (isSelectionMode)
          _buildPillButton(colorScheme, label: '완료', onPressed: viewModel.toggleSelectionMode)
        else if (viewModel.hasItems)
          _buildPillButton(
            colorScheme,
            label: '편집',
            icon: Icons.edit_outlined,
            onPressed: viewModel.toggleSelectionMode,
          ),
      ],
    );
  }

  /// 헤더 우측의 낮은 알약 버튼 (편집 / 완료)
  Widget _buildPillButton(
    ColorScheme colorScheme, {
    required String label,
    IconData? icon,
    required VoidCallback onPressed,
  }) {
    final foreground = colorScheme.onSurface.withValues(alpha: 0.75);

    return Material(
      color: colorScheme.onSurface.withValues(alpha: 0.06),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: context.textStyle.labelMedium.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 우측 하단 노선 추가 플로팅 버튼: 초록 사선 그라데이션 + 초록빛 그림자
  Widget _buildAddFab(ColorScheme colorScheme) {
    final highlight = Color.lerp(colorScheme.primary, Colors.white, 0.12)!;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs, bottom: AppSpacing.sm),
      child: Container(
        width: _fabSize,
        height: _fabSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [highlight, colorScheme.primary],
            stops: const [0, 0.7],
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.32),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _goToAddRoute,
            child: Tooltip(
              message: '노선 추가',
              child: Icon(Icons.add_rounded, color: colorScheme.onPrimary, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, BusListViewModel viewModel, {required bool showFab}) {
    return Expanded(
      child: switch (viewModel.state) {
        BusListEmpty() => _buildEmptyState(colorScheme),
        BusListSuccess(items: final items) => Stack(
            children: [
              if (viewModel.isSelectionMode)
                // 선택 모드: 손잡이(≡)를 끌어 순서 변경. 구분자 대신 카드 아래 여백으로 간격을 준다
                ReorderableListView.builder(
                  physics: const BouncingScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorderItem: viewModel.move,
                  // 기본 장식은 항목(카드 + 아래 간격) 전체에 그림자 상자를 그려 카드 밖까지 튀어나온다.
                  // 간격은 투명하게 두고 카드만 살짝 키워서 들어 올린 느낌을 준다
                  proxyDecorator: (child, _, animation) => AnimatedBuilder(
                    animation: animation,
                    builder: (_, child) => Transform.scale(
                      scale: 1 + 0.03 * Curves.easeInOut.transform(animation.value),
                      child: child,
                    ),
                    child: Material(type: MaterialType.transparency, child: child),
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => Padding(
                    key: ValueKey(BusListViewModel.keyOf(items[index])),
                    padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : AppSpacing.md),
                    child: _buildRouteItem(items[index], colorScheme, viewModel, index: index),
                  ),
                )
              else
                // 당겨서 새로고침: 카드 전부 다시 조회
                RefreshIndicator(
                  onRefresh: viewModel.refresh,
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: EdgeInsets.only(bottom: showFab ? _fabClearance : 0),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) => _buildRouteItem(items[index], colorScheme, viewModel, index: index),
                  ),
                ),
              // 플로팅 버튼 뒤로 카드가 흰색으로 스르륵 사라지는 페이드
              if (showFab)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [colorScheme.surface.withValues(alpha: 0), colorScheme.surface],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      },
    );
  }

  Widget _buildRouteItem(UserSaveModel item, ColorScheme colorScheme, BusListViewModel viewModel, {required int index}) {
    final isSelectionMode = viewModel.isSelectionMode;
    final isSelected = viewModel.isSelected(item);
    final busColor = BusColor().setColor(item.routeTypeCd);

    return AppCard(
      selected: isSelected,
      onTap: () => isSelectionMode ? viewModel.toggleSelection(item) : _goToDetail(item),
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
          // 오른쪽: 선택 모드면 순서 변경 손잡이, 아니면 다음 버스 도착 정보
          if (isSelectionMode)
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                  size: 24,
                ),
              ),
            )
          else ...[
            const SizedBox(width: AppSpacing.md),
            _buildArrival(viewModel.arrivalOf(item), busColor, colorScheme, onRetry: () => viewModel.retry(item)),
          ],
        ],
      ),
    );
  }

  /// 카드 우측 도착 정보: 로딩 스켈레톤 / MM:SS + N정거장 전 / 잠시 후 도착 / 운행 없음 / 오류
  Widget _buildArrival(
    BusCardArrival arrival,
    Color busColor,
    ColorScheme colorScheme, {
    required VoidCallback onRetry,
  }) {
    final muted = colorScheme.onSurface.withValues(alpha: 0.55);
    final mutedStyle = context.textStyle.labelSmall.copyWith(color: muted, fontWeight: FontWeight.w600);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _arrivalMinWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: switch (arrival) {
          BusCardLoading() => [
              _buildSkeleton(colorScheme, width: 64, height: 22),
              const SizedBox(height: 6),
              _buildSkeleton(colorScheme, width: 48, height: 10),
            ],
          BusCardArriving(:final remainingSeconds, :final locationNo) => [
              if (isArrivingSoon(remainingSeconds))
                Text(
                  kArrivingSoonLabel,
                  style: context.textStyle.titleMedium.copyWith(
                    color: busColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                )
              else
                Text(
                  formatMmss(remainingSeconds),
                  style: context.textStyle.headlineLarge.copyWith(
                    color: busColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1.05,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              const SizedBox(height: 3),
              Text('$locationNo정거장 전', style: mutedStyle),
            ],
          BusCardNotOperating() => [
              Text(
                '운행 없음',
                style: context.textStyle.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '출발 전 · 운행 종료',
                style: context.textStyle.labelSmall.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          BusCardError() => [
              Text('불러오지 못함', style: mutedStyle.copyWith(fontSize: 13)),
              const SizedBox(height: 4),
              // 이 카드만 재조회
              InkWell(
                onTap: onRetry,
                borderRadius: BorderRadius.circular(AppRadius.inner),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 3),
                      Text(
                        '다시 시도',
                        style: context.textStyle.labelSmall.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
        },
      ),
    );
  }

  Widget _buildSkeleton(ColorScheme colorScheme, {required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
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

  /// 선택 모드 하단 바: 전체 삭제 (작게) + 선택 삭제 (N)
  Widget _buildDeleteBar(ColorScheme colorScheme, BusListViewModel viewModel) {
    final hasSelection = viewModel.selectedCount > 0;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Row(
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
