import 'package:bus_51/theme/colors.dart';
import 'package:flutter/material.dart';

@immutable
class CustomTextStyle extends ThemeExtension<CustomTextStyle> {
  CustomTextStyle({this.customThemeColor})
      : _defaultFontFamily = TextStyle(
    fontFamily: 'Pretendard',
    letterSpacing: 0.0,
    wordSpacing: 0.0,
    // height: 1.0,
    color: customThemeColor?.text01,
  );

  final CustomColors? customThemeColor;
  final TextStyle _defaultFontFamily;

  /// private getter
  TextStyle get _boldFont => _defaultFontFamily.copyWith(fontWeight: FontWeight.w700);
  TextStyle get _mediumFont => _defaultFontFamily.copyWith(fontWeight: FontWeight.w500);
  TextStyle get _regularFont => _defaultFontFamily.copyWith(fontWeight: FontWeight.w400);

  /// Material 3 Typography Scale
  // Display styles (large headings)
  TextStyle get displayLarge => _boldFont.copyWith(fontSize: 32);
  TextStyle get displayMedium => _boldFont.copyWith(fontSize: 28);
  TextStyle get displaySmall => _boldFont.copyWith(fontSize: 24);

  // Headline styles (section headers)
  TextStyle get headlineLarge => _boldFont.copyWith(fontSize: 22);
  TextStyle get headlineMedium => _boldFont.copyWith(fontSize: 20);
  TextStyle get headlineSmall => _boldFont.copyWith(fontSize: 18);

  // Title styles (component titles)
  TextStyle get titleLarge => _boldFont.copyWith(fontSize: 18);
  TextStyle get titleMedium => _mediumFont.copyWith(fontSize: 16);
  TextStyle get titleSmall => _mediumFont.copyWith(fontSize: 14);

  // Body styles (main content)
  TextStyle get bodyLarge => _regularFont.copyWith(fontSize: 16);
  TextStyle get bodyMedium => _regularFont.copyWith(fontSize: 14);
  TextStyle get bodySmall => _regularFont.copyWith(fontSize: 12);

  // Label styles (buttons, form labels)
  TextStyle get labelLarge => _mediumFont.copyWith(fontSize: 16);
  TextStyle get labelMedium => _mediumFont.copyWith(fontSize: 14);
  TextStyle get labelSmall => _mediumFont.copyWith(fontSize: 12);

  // Custom app-specific styles
  TextStyle get appTitle => _boldFont.copyWith(fontSize: 28);
  TextStyle get buttonText => _mediumFont.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
  TextStyle get caption => _regularFont.copyWith(fontSize: 12);
  TextStyle get subtitle => _regularFont.copyWith(fontSize: 15);

  // Legacy styles (기존 호환성)
  TextStyle get titleBoldLg => _boldFont.copyWith(fontSize: 22);
  TextStyle get titleBoldMd => _boldFont.copyWith(fontSize: 20);
  TextStyle get titleBoldSm => _boldFont.copyWith(fontSize: 18);

  TextStyle get titleMediumLg => _mediumFont.copyWith(fontSize: 22);
  TextStyle get titleMediumMd => _mediumFont.copyWith(fontSize: 20);
  TextStyle get titleMediumSm => _mediumFont.copyWith(fontSize: 18);

  TextStyle get subtitleBoldMd => _boldFont.copyWith(fontSize: 18);
  TextStyle get subtitleMediumMd => _mediumFont.copyWith(fontSize: 16);
  TextStyle get subtitleRegularMd => _regularFont.copyWith(fontSize: 16);

  TextStyle get bodyBoldLg => _boldFont.copyWith(fontSize: 14);
  TextStyle get bodyBoldMd => _boldFont.copyWith(fontSize: 12);

  TextStyle get bodyMediumLg => _mediumFont.copyWith(fontSize: 14);
  TextStyle get bodyMediumMd => _mediumFont.copyWith(fontSize: 12);

  TextStyle get bodyRegularLg => _regularFont.copyWith(fontSize: 14);
  TextStyle get bodyRegularMd => _regularFont.copyWith(fontSize: 12);

  TextStyle get captionLg => _regularFont.copyWith(fontSize: 10);
  TextStyle get captionMd => _regularFont.copyWith(fontSize: 8);

  @override
  CustomTextStyle copyWith({Color? customColor}) {
    return this;

    /// 추후 필요하다면 구현
    // return CustomFonts(
    //   primaryMain: customColor ?? primaryMain,
    // );
  }

  @override
  CustomTextStyle lerp(ThemeExtension<CustomTextStyle>? other, double t) {
    return this;

    /// 추후 필요하다면 구현
    // if (other is! CustomColors) return this;
    // return CustomFonts(
    //   primaryMain: Color.lerp(primaryMain, other.primaryMain, t) ?? primaryMain,
    // );
  }
}

/// CustomFonts 확장
/// UI 단에서 'context.customColors.primaryMain'의 형태로 사용 가능
extension CustomTextStyleExtension on BuildContext {
  CustomTextStyle get textStyle {
    return Theme.of(this).extension<CustomTextStyle>()!;
  }
}
