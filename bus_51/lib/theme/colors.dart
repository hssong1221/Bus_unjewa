import 'package:flutter/material.dart';

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  // 한국 버스 노선 색상 체계 (Bus Route Colors)
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

  const CustomColors({
    // Korean Bus Route Colors - 한국 버스 노선 색상 체계
    this.busYellow = const Color(0xFFF2A000), // 마을버스 (Pantone 130 C)
    this.busGreen = const Color(0xFF009775), // 간선버스 (Pantone 334 C)
    this.busBlue = const Color(0xFF0085CA), // 광역버스
    this.busRed = const Color(0xFFEE2737), // 급행버스 (Pantone 1788 C)
    this.busPurple = const Color(0xFFB62367), // 시내버스
    this.busGold = const Color(0xFF85714D), // 순환버스 (Pantone 872 C)
    // Additional bus colors
    this.busWhite = const Color(0xFFFFFFFF), // 흰색 버스
    this.busLightYellow = const Color(0xFFFED70F), // 노란색 변형
    this.busLightGreen = const Color(0xFF9AD84E), // 연두색 변형
    this.busDarkGreen = const Color(0xFF18BF74), // 초록색 변형
    this.busSkyBlue = const Color(0xFF27C7D8), // 하늘색
    this.busNavyBlue = const Color(0xFF3C96D5), // 진한 파란색
  });

  static const dark = CustomColors();

  static const light = CustomColors();

  @override
  CustomColors copyWith({
    Color? busYellow,
    Color? busGreen,
    Color? busBlue,
    Color? busRed,
    Color? busPurple,
    Color? busGold,
    Color? busWhite,
    Color? busLightYellow,
    Color? busLightGreen,
    Color? busDarkGreen,
    Color? busSkyBlue,
    Color? busNavyBlue,
  }) {
    return CustomColors(
      busYellow: busYellow ?? this.busYellow,
      busGreen: busGreen ?? this.busGreen,
      busBlue: busBlue ?? this.busBlue,
      busRed: busRed ?? this.busRed,
      busPurple: busPurple ?? this.busPurple,
      busGold: busGold ?? this.busGold,
      busWhite: busWhite ?? this.busWhite,
      busLightYellow: busLightYellow ?? this.busLightYellow,
      busLightGreen: busLightGreen ?? this.busLightGreen,
      busDarkGreen: busDarkGreen ?? this.busDarkGreen,
      busSkyBlue: busSkyBlue ?? this.busSkyBlue,
      busNavyBlue: busNavyBlue ?? this.busNavyBlue,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      busYellow: Color.lerp(busYellow, other.busYellow, t) ?? busYellow,
      busGreen: Color.lerp(busGreen, other.busGreen, t) ?? busGreen,
      busBlue: Color.lerp(busBlue, other.busBlue, t) ?? busBlue,
      busRed: Color.lerp(busRed, other.busRed, t) ?? busRed,
      busPurple: Color.lerp(busPurple, other.busPurple, t) ?? busPurple,
      busGold: Color.lerp(busGold, other.busGold, t) ?? busGold,
      busWhite: Color.lerp(busWhite, other.busWhite, t) ?? busWhite,
      busLightYellow: Color.lerp(busLightYellow, other.busLightYellow, t) ?? busLightYellow,
      busLightGreen: Color.lerp(busLightGreen, other.busLightGreen, t) ?? busLightGreen,
      busDarkGreen: Color.lerp(busDarkGreen, other.busDarkGreen, t) ?? busDarkGreen,
      busSkyBlue: Color.lerp(busSkyBlue, other.busSkyBlue, t) ?? busSkyBlue,
      busNavyBlue: Color.lerp(busNavyBlue, other.busNavyBlue, t) ?? busNavyBlue,
    );
  }
}

/// CustomColors 확장
/// UI 단에서 'context.customColors.primaryMain'의 형태로 사용 가능
extension CustomColorsExtension on BuildContext {
  CustomColors get colors {
    return Theme.of(this).extension<CustomColors>()!;
  }
}
