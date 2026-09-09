import 'package:bus_51/theme/app_tokens.dart';
import 'package:flutter/material.dart';

// --------------------------------------------------
// 앱 공통 토스트(스낵바)
// 화면 아래에 떠 있는 둥근 막대, 2초 뒤 사라진다. isError 면 error 색 배경.
// 리스트 화면의 삭제 안내와 메인 화면의 도착 알림 안내가 같은 모양으로 나오도록 한 곳에 둔다
// --------------------------------------------------
void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
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
