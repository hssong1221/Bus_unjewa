import 'package:bus_51/theme/colors.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:flutter/material.dart';

const _lightCustomColors = CustomColors.light;
CustomTextStyle _lightTextStyle = CustomTextStyle(customThemeColor: _lightCustomColors);

final ColorScheme colorScheme = ColorScheme.fromSeed(
  seedColor: Colors.indigo,
  brightness: Brightness.light,
);

final ThemeData lightTheme = ThemeData(
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  primaryColor: _lightCustomColors.backgroundPaper,
  scaffoldBackgroundColor: _lightCustomColors.backgroundPaper,
  dialogBackgroundColor: _lightCustomColors.backgroundPaper,
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: _lightCustomColors.backgroundPaper,
    surfaceTintColor: _lightCustomColors.backgroundPaper,
  ),
  dialogTheme: DialogTheme(
    backgroundColor: _lightCustomColors.backgroundPaper,
    surfaceTintColor: _lightCustomColors.backgroundPaper,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: colorScheme.primary,
    surfaceTintColor: _lightCustomColors.backgroundPaper,
    foregroundColor: _lightCustomColors.backgroundPaper,
    iconTheme: IconThemeData(
      color: _lightCustomColors.backgroundPaper,
    ),
  ),

  /*textSelectionTheme: TextSelectionThemeData(
    cursorColor: _darkCustomColors.primaryMain,
    selectionColor: _darkCustomColors.primaryMain.withOpacity(0.3),
    selectionHandleColor: _darkCustomColors.primaryMain,
  ),
  dividerColor: _darkCustomColors.dividerBorderContainer,
  dividerTheme: DividerThemeData(
    space: 1,
    color: _darkCustomColors.dividerBorderContainer,
  ),*/
  textTheme: TextTheme(
    bodyLarge: _lightTextStyle.bodyMediumLg,
    bodyMedium: _lightTextStyle.bodyRegularMd,
  ),

  /// Custom Colors & Text Style 추가
  extensions: [
    _lightCustomColors,
    _lightTextStyle,
  ],
);
