import 'package:bus_51/theme/colors.dart';
import 'package:bus_51/theme/custom_text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _lightCustomColors = CustomColors.light;
CustomTextStyle _lightTextStyle = CustomTextStyle(customThemeColor: _lightCustomColors);

// Bus-themed color scheme using Korean bus route colors
final ColorScheme _lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  // Primary: 초록색 (간선버스)
  primary: const Color(0xFF009775),
  onPrimary: const Color(0xFFFFFFFF),
  primaryContainer: const Color(0xFFB2DFDB),
  onPrimaryContainer: const Color(0xFF00201C),
  // Secondary: 파란색 (광역버스)
  secondary: const Color(0xFF0085CA),
  onSecondary: const Color(0xFFFFFFFF),
  secondaryContainer: const Color(0xFFB3E5FC),
  onSecondaryContainer: const Color(0xFF001E2F),
  // Tertiary: 노란색 (마을버스)
  tertiary: const Color(0xFFF2A000),
  onTertiary: const Color(0xFF000000),
  tertiaryContainer: const Color(0xFFFFE0B2),
  onTertiaryContainer: const Color(0xFF3E2723),
  // Error: 빨간색 (급행버스)
  error: const Color(0xFFEE2737),
  onError: const Color(0xFFFFFFFF),
  errorContainer: const Color(0xFFFFCDD2),
  onErrorContainer: const Color(0xFF5F1419),
  // Surface colors
  surface: const Color(0xFFFFFFFF),
  onSurface: const Color(0xFF1C1B1F),
  surfaceVariant: const Color(0xFFF5F5F5),
  onSurfaceVariant: const Color(0xFF424242),
  outline: const Color(0xFF9E9E9E),
  outlineVariant: const Color(0xFFE0E0E0),
  shadow: const Color(0xFF000000),
  scrim: const Color(0xFF000000),
  inverseSurface: const Color(0xFF2E2E2E),
  onInverseSurface: const Color(0xFFF5F5F5),
  inversePrimary: const Color(0xFF4DB6AC),
  surfaceTint: const Color(0xFF009775),
  // Additional surface colors for Material 3
  surfaceDim: const Color(0xFFE8E8E8),
  surfaceBright: const Color(0xFFFFFFFF),
  surfaceContainerLowest: const Color(0xFFFFFFFF),
  surfaceContainerLow: const Color(0xFFFAFAFA),
  surfaceContainer: const Color(0xFFF0F0F0),
  surfaceContainerHigh: const Color(0xFFEBEBEB),
  surfaceContainerHighest: const Color(0xFFE6E6E6),
);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _lightColorScheme,
  splashFactory: InkRipple.splashFactory,
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
    backgroundColor: _lightColorScheme.primary, // 초록색 배경
    foregroundColor: _lightColorScheme.onPrimary,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      color: _lightColorScheme.onPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      fontFamily: 'Pretendard',
    ),
    iconTheme: IconThemeData(
      color: _lightColorScheme.onPrimary,
    ),
    centerTitle: true,
    systemOverlayStyle: SystemUiOverlayStyle.light,
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
    displayLarge: TextStyle(
      color: _lightColorScheme.onSurface,
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      fontFamily: 'Pretendard',
    ),
    displayMedium: TextStyle(
      color: _lightColorScheme.onSurface,
      fontSize: 45,
      fontWeight: FontWeight.w400,
      fontFamily: 'Pretendard',
    ),
    displaySmall: TextStyle(
      color: _lightColorScheme.onSurface,
      fontSize: 36,
      fontWeight: FontWeight.w400,
      fontFamily: 'Pretendard',
    ),
    headlineLarge: TextStyle(
      color: _lightColorScheme.onSurface,
      fontSize: 32,
      fontWeight: FontWeight.w400,
      fontFamily: 'Pretendard',
    ),
    headlineMedium: TextStyle(
      color: _lightColorScheme.onSurface,
      fontSize: 28,
      fontWeight: FontWeight.w400,
      fontFamily: 'Pretendard',
    ),
    headlineSmall: TextStyle(
      color: _lightColorScheme.onSurface,
      fontSize: 24,
      fontWeight: FontWeight.w400,
      fontFamily: 'Pretendard',
    ),
    titleLarge: TextStyle(
      color: _lightColorScheme.onSurface,
      fontSize: 22,
      fontWeight: FontWeight.w400,
      fontFamily: 'Pretendard',
    ),
    titleMedium: TextStyle(
      color: _lightColorScheme.onSurface,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      fontFamily: 'Pretendard',
    ),
    titleSmall: TextStyle(
      color: _lightColorScheme.onSurface,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      fontFamily: 'Pretendard',
    ),
    bodyLarge: TextStyle(
      color: _lightColorScheme.onSurface,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      fontFamily: 'Pretendard',
    ),
    bodyMedium: TextStyle(
      color: _lightColorScheme.onSurface,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      fontFamily: 'Pretendard',
    ),
    bodySmall: TextStyle(
      color: _lightColorScheme.onSurface,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      fontFamily: 'Pretendard',
    ),
    labelLarge: TextStyle(
      color: _lightColorScheme.onSurface,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      fontFamily: 'Pretendard',
    ),
    labelMedium: TextStyle(
      color: _lightColorScheme.onSurface,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      fontFamily: 'Pretendard',
    ),
    labelSmall: TextStyle(
      color: _lightColorScheme.onSurface,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      fontFamily: 'Pretendard',
    ),
  ),

  /// Material 3 component themes
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _lightColorScheme.primary, // 초록색
      foregroundColor: _lightColorScheme.onPrimary,
      elevation: 2,
      shadowColor: _lightColorScheme.shadow.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Pretendard',
      ),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: _lightColorScheme.secondary, // 파란색
      foregroundColor: _lightColorScheme.onSecondary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Pretendard',
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: _lightColorScheme.primary,
      side: BorderSide(color: _lightColorScheme.outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'Pretendard',
      ),
    ),
  ),
  cardTheme: CardTheme(
    color: _lightColorScheme.surface,
    surfaceTintColor: _lightColorScheme.surfaceTint.withOpacity(0.05),
    elevation: 4,
    shadowColor: _lightColorScheme.shadow.withOpacity(0.15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: _lightColorScheme.surfaceContainerHigh,
    selectedColor: _lightColorScheme.primaryContainer,
    labelStyle: TextStyle(
      color: _lightColorScheme.onSurface,
      fontFamily: 'Pretendard',
      fontWeight: FontWeight.w500,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    elevation: 2,
    shadowColor: _lightColorScheme.shadow.withOpacity(0.1),
  ),
  dividerTheme: DividerThemeData(
    color: _lightColorScheme.outlineVariant,
    space: 1,
    thickness: 1,
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: _lightColorScheme.surface,
    indicatorColor: _lightColorScheme.primaryContainer,
    elevation: 8,
    shadowColor: _lightColorScheme.shadow.withOpacity(0.1),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      return TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: states.contains(WidgetState.selected)
            ? _lightColorScheme.primary // 선택시 초록색
            : _lightColorScheme.onSurfaceVariant,
        fontFamily: 'Pretendard',
      );
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      return IconThemeData(
        color: states.contains(WidgetState.selected)
            ? _lightColorScheme.primary // 선택시 초록색
            : _lightColorScheme.onSurfaceVariant,
      );
    }),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _lightColorScheme.surfaceContainerHighest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: _lightColorScheme.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: _lightColorScheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: _lightColorScheme.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: _lightColorScheme.error),
    ),
    labelStyle: TextStyle(
      color: _lightColorScheme.onSurfaceVariant,
      fontFamily: 'Pretendard',
    ),
    hintStyle: TextStyle(
      color: _lightColorScheme.onSurfaceVariant,
      fontFamily: 'Pretendard',
    ),
  ),

  /// Custom Colors & Text Style 추가
  extensions: [
    _lightCustomColors,
    _lightTextStyle,
  ],
);
