import 'package:bus_51/theme/colors.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:bus_51/theme/images.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BaseAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BaseAppBar({
    super.key,
    this.title = "",
    this.titleStyle,
    this.centerTitle = true,
    this.backButtonVisible = true,
    this.isBackButtonCustom = false,
    this.onPressed_notRouter,
    this.onPressed,
    this.textColor,
    this.backgroundColor,
    this.actions,
    this.leading,
  });

  final String title;
  final TextStyle? titleStyle;
  final bool centerTitle;
  final bool backButtonVisible;
  final bool isBackButtonCustom;
  final Function()? onPressed;
  final Function()? onPressed_notRouter;
  final Color? textColor;
  final Color? backgroundColor;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(60.0); // 원하는 높이 설정

  @override
  Widget build(BuildContext context) {
    actions?.add(const SizedBox(width: 20));

    return AppBar(
      title: title.isEmpty
          ? Image.asset(
              Images.imgAppBarLogo,
              width: 121,
              height: 25,
            )
          : Text(
              title,
              style: titleStyle ?? context.textStyle.titleBoldLg.copyWith(color: CustomColors.commonWhite),
            ),
      backgroundColor: backgroundColor,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: leading ?? _setLeading(context)
          /*(backButtonVisible && context.canPop()
              ? IconButton(
                  alignment: Alignment.centerLeft,
                  onPressed: onPressed ?? () => context.pop(),
                  icon: ImageIcon(
                    const AssetImage(Images.iconArrowBack),
                    color: textColor ?? context.colors.textPrimary,
                  ),
                  iconSize: 24,
                )
              : null)*/,
      leadingWidth: centerTitle ? null : 20,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0), // 라인의 높이를 설정합니다.
        child: Container(
          color: context.colors.line01, // 라인의 색상을 설정합니다.
          height: 1.0, // 라인의 높이를 설정합니다.
        ),
      ),
      actions: actions,
      elevation: 0.0,
      titleSpacing: 0,
      scrolledUnderElevation: 0,
    );
  }

  Widget _setLeading(BuildContext context) {
    // 한 스크린 안에서 여러개의 뷰를 사용하기 때문에 직접 백 버튼 아이콘을 만들어서 보여줘야하는 경우
    if (isBackButtonCustom) {
      return IconButton(
        alignment: Alignment.centerLeft,
        icon: ImageIcon(
          const AssetImage(Images.iconArrowBack),
          color: textColor ?? const Color(0xFFBDC2D7),
        ),
        iconSize: 24,
        onPressed: onPressed_notRouter,
      );
    }

    // 일반적인 라우터를 사용했을 경우
    if(backButtonVisible && context.canPop()) {
      return IconButton(
        alignment: Alignment.centerLeft,
        onPressed: onPressed ?? () => context.pop(),
        icon: ImageIcon(
          const AssetImage(Images.iconArrowBack),
          color: textColor ?? const Color(0xFFBDC2D7),
        ),
        iconSize: 24,
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
