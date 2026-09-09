import 'package:bus_51/theme/app_tokens.dart';
import 'package:flutter/material.dart';

// --------------------------------------------------
// 앱 공통 권한 안내 다이얼로그
// 권한이 없어 기능을 쓸 수 없을 때 띄운다. 아이콘·제목·설명·버튼 문구만 바꿔 어디서든 재사용한다.
// (도착 알림 → 알림 권한, 정류장 찾기 → 위치 권한)
//
// "설정 열기"를 누르면 true, 그 외(나중에·바깥 탭·뒤로가기)는 false 를 돌려준다.
// 실제로 어느 설정 화면을 열지는 부르는 쪽이 정한다 (알림 설정 / 앱 정보 등 권한마다 다르다).
// 모양은 리스트 화면의 삭제 확인 다이얼로그와 같다 (16px 모서리, 아이콘+제목 한 줄)
// --------------------------------------------------
class AppPermissionDialog extends StatelessWidget {
  const AppPermissionDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.dismissLabel = '나중에',
    this.settingsLabel = '설정 열기',
  });

  final IconData icon;
  final String title;
  final String message;

  /// 왼쪽(닫기) 버튼 문구. 위치 권한처럼 대신할 동작이 있으면 "기본 위치로" 같은 문구를 준다
  final String dismissLabel;
  final String settingsLabel;

  /// 다이얼로그를 띄우고 "설정 열기"를 눌렀는지 돌려준다
  static Future<bool> show(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    String dismissLabel = '나중에',
    String settingsLabel = '설정 열기',
  }) async {
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (_) => AppPermissionDialog(
        icon: icon,
        title: title,
        message: message,
        dismissLabel: dismissLabel,
        settingsLabel: settingsLabel,
      ),
    );
    return openSettings ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      title: Row(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(dismissLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(settingsLabel),
        ),
      ],
    );
  }
}
