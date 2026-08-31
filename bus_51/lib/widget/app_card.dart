import 'package:bus_51/theme/app_tokens.dart';
import 'package:flutter/material.dart';

// --------------------------------------------------
// 앱 공통 플랫 카드
// 그림자 없이 surface 배경 + 연한 outline 테두리로 구분한다.
// selected=true 면 primary 테두리 + 옅은 primary 배경 (리스트 선택 모드용)
// onTap 을 주면 InkWell 리플이 카드 모양대로 잘려서 나온다
// --------------------------------------------------
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final side = selected
        ? BorderSide(color: colorScheme.primary, width: 2)
        : BorderSide(color: colorScheme.outline.withValues(alpha: kCardBorderAlpha));
    final background = selected
        ? colorScheme.primary.withValues(alpha: 0.06)
        : colorScheme.surface;

    Widget card = Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: side,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(padding: padding, child: child),
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }
    return card;
  }
}
