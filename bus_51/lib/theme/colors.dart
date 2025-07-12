import 'package:flutter/material.dart';

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  static const Color commonWhite = Color(0xFFFFFFFF);
  static const Color commonBlack = Color(0xFF000000);

  static const Color grey100 = Color(0xFFEEF3F9);
  static const Color grey200 = Color(0xFFE5EBF3);
  static const Color grey300 = Color(0xFFD4D8EA);
  static const Color grey400 = Color(0xFFBCC7D4);
  static const Color grey500 = Color(0xFFAEB2C7);
  static const Color grey600 = Color(0xFF9397AC);
  static const Color grey700 = Color(0xFF74788B);
  static const Color grey800 = Color(0xFF3C3E49);
  static const Color grey900 = Color(0xFF2A2C35);

  final Color text01;
  final Color text02;
  final Color text03;
  final Color text04;

  final Color backgroundPaper;
  final Color backgroundDefault;
  final Color line01;
  final Color line02;
  final Color bttt;
  final Color btbg;

  final Color busYellow;
  final Color busGreen;
  final Color busBlue;
  final Color busRed;
  final Color busPurple;
  final Color busGold;

  const CustomColors({
    this.text01 = const Color(0xFF1B1C1E),
    this.text02 = const Color(0xFF45484D),
    this.text03 = const Color(0xFF616D81),
    this.text04 = const Color(0xFFAAB0BA),

    this.backgroundPaper = const Color(0xFFFFFFFF),
    this.backgroundDefault = const Color(0xFFF4F5F6),
    this.line01 = const Color(0xFFF1F3F9),
    this.line02 = const Color(0xFFE6E9F0),
    this.bttt = const Color(0xFF7C808B),
    this.btbg = const Color(0xFFE6E7E9),

    this.busYellow = const Color(0xFFF2A000),
    this.busGreen = const Color(0xFF009775),
    this.busBlue = const Color(0xFF0085CA),
    this.busRed = const Color(0xFFEE2737),
    this.busPurple = const Color(0xFFB62367),
    this.busGold = const Color(0xFF85714D),
  });

  static const dark = CustomColors();

  static const light = CustomColors();

  @override
  CustomColors copyWith({Color? customColor}) {
    return this;

    /// 추후 필요하다면 구현
    // return CustomColors(
    //   primaryMain: customColor ?? primaryMain,
    // );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    return this;

    /// 추후 필요하다면 구현
    // if (other is! CustomColors) return this;
    // return CustomColors(
    //   primaryMain: Color.lerp(primaryMain, other.primaryMain, t) ?? primaryMain,
    // );
  }
}

/// CustomColors 확장
/// UI 단에서 'context.customColors.primaryMain'의 형태로 사용 가능
extension CustomColorsExtension on BuildContext {
  CustomColors get colors {
    return Theme.of(this).extension<CustomColors>()!;
  }
}
