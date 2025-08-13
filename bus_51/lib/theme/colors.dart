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
  final Color busWhite;
  final Color busLightYellow;
  final Color busLightGreen;
  final Color busDarkGreen;
  final Color busSkyBlue;
  final Color busNavyBlue;

  // Material 3 semantic colors
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color inverseSurface;
  final Color onInverseSurface;
  final Color inversePrimary;
  final Color shadow;
  final Color scrim;
  final Color surfaceDim;
  final Color surfaceBright;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;

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

    // Korean Bus Route Colors - 한국 버스 노선 색상 체계
    this.busYellow = const Color(0xFFF2A000), // 마을버스 (Pantone 130 C)
    this.busGreen = const Color(0xFF009775), // 간선버스 (Pantone 334 C)
    this.busBlue = const Color(0xFF0085CA), // 광역버스
    this.busRed = const Color(0xFFEE2737), // 급행버스 (Pantone 1788 C)
    this.busPurple = const Color(0xFFB62367), // 시내버스
    this.busGold = const Color(0xFF85714D), // 순환버스 (Pantone 872 C)
    // Additional bus colors
    this.busWhite = const Color(0xFFFFFFFF), // 하여상버스
    this.busLightYellow = const Color(0xFFFED70F), // 노란색 변형
    this.busLightGreen = const Color(0xFF9AD84E), // 연두색 변형
    this.busDarkGreen = const Color(0xFF18BF74), // 초록색 변형
    this.busSkyBlue = const Color(0xFF27C7D8), // 하늘색
    this.busNavyBlue = const Color(0xFF3C96D5), // 진한 파란색

    // Material 3 Light Theme Colors
    this.primary = const Color(0xFF3F51B5),
    this.onPrimary = const Color(0xFFFFFFFF),
    this.primaryContainer = const Color(0xFFE1E7FF),
    this.onPrimaryContainer = const Color(0xFF00174A),
    this.secondary = const Color(0xFF009688),
    this.onSecondary = const Color(0xFFFFFFFF),
    this.secondaryContainer = const Color(0xFFB2DFDB),
    this.onSecondaryContainer = const Color(0xFF00201C),
    this.tertiary = const Color(0xFF7B5800),
    this.onTertiary = const Color(0xFFFFFFFF),
    this.tertiaryContainer = const Color(0xFFFFDF9B),
    this.onTertiaryContainer = const Color(0xFF251A00),
    this.error = const Color(0xFFBA1A1A),
    this.onError = const Color(0xFFFFFFFF),
    this.errorContainer = const Color(0xFFFFDAD6),
    this.onErrorContainer = const Color(0xFF410002),
    this.surface = const Color(0xFFFFFBFE),
    this.onSurface = const Color(0xFF1C1B1F),
    this.surfaceVariant = const Color(0xFFE4E1EC),
    this.onSurfaceVariant = const Color(0xFF46454F),
    this.outline = const Color(0xFF777680),
    this.outlineVariant = const Color(0xFFC8C5D0),
    this.inverseSurface = const Color(0xFF313033),
    this.onInverseSurface = const Color(0xFFF3EFF4),
    this.inversePrimary = const Color(0xFFBEC6FF),
    this.shadow = const Color(0xFF000000),
    this.scrim = const Color(0xFF000000),
    this.surfaceDim = const Color(0xFFDDD8DD),
    this.surfaceBright = const Color(0xFFFFFBFE),
    this.surfaceContainerLowest = const Color(0xFFFFFFFF),
    this.surfaceContainerLow = const Color(0xFFF6F2F7),
    this.surfaceContainer = const Color(0xFFF0ECF1),
    this.surfaceContainerHigh = const Color(0xFFEAE7EC),
    this.surfaceContainerHighest = const Color(0xFFE4E1E6),
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
