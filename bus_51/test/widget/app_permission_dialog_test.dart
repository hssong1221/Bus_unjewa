import 'package:bus_51/theme/app_tokens.dart';
import 'package:bus_51/theme/light_theme.dart';
import 'package:bus_51/widget/app_permission_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// "열기" 버튼을 누르면 [open] 을 부르고, 그 결과를 [onResult] 로 돌려주는 최소 앱
Widget buildApp({
  required Future<bool> Function(BuildContext) open,
  required void Function(bool) onResult,
}) =>
    MaterialApp(
      theme: lightTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => onResult(await open(context)),
            child: const Text('열기'),
          ),
        ),
      ),
    );

/// 기획 문서의 알림 권한 인스턴스
Future<bool> openNotificationDialog(BuildContext context) => AppPermissionDialog.show(
      context,
      icon: Icons.notifications_none,
      title: '알림 권한이 필요해요',
      message: '알림을 허용해야 버스가 오기 전에 알려드릴 수 있어요. 설정에서 "버스 언제와" 알림을 켜주세요.',
    );

void main() {
  group('AppPermissionDialog', () {
    testWidgets('아이콘·제목·설명·두 버튼을 그린다', (tester) async {
      await tester.pumpWidget(buildApp(open: openNotificationDialog, onResult: (_) {}));
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      expect(find.text('알림 권한이 필요해요'), findsOneWidget);
      expect(find.textContaining('설정에서 "버스 언제와" 알림을 켜주세요'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '나중에'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '설정 열기'), findsOneWidget);

      // 삭제 확인 다이얼로그와 같은 16px 모서리
      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      final shape = dialog.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(AppRadius.card));
    });

    testWidgets('"설정 열기"를 누르면 true, 닫히고 나면 다이얼로그가 없다', (tester) async {
      bool? result;
      await tester.pumpWidget(buildApp(open: openNotificationDialog, onResult: (r) => result = r));
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('설정 열기'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('"나중에"를 누르면 false', (tester) async {
      bool? result;
      await tester.pumpWidget(buildApp(open: openNotificationDialog, onResult: (r) => result = r));
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('나중에'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('바깥을 탭해서 닫아도 false (null 이 아니다)', (tester) async {
      bool? result;
      await tester.pumpWidget(buildApp(open: openNotificationDialog, onResult: (r) => result = r));
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('위치 권한처럼 버튼 문구를 바꿔 쓸 수 있다', (tester) async {
      await tester.pumpWidget(buildApp(
        open: (context) => AppPermissionDialog.show(
          context,
          icon: Icons.location_on_outlined,
          title: '위치 권한이 필요해요',
          message: '내 주변 정류장을 찾으려면 위치 권한이 필요해요.',
          dismissLabel: '기본 위치로',
        ),
        onResult: (_) {},
      ));
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      expect(find.text('위치 권한이 필요해요'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '기본 위치로'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '설정 열기'), findsOneWidget);
    });
  });
}
