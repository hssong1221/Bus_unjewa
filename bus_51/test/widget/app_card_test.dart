import 'package:bus_51/theme/light_theme.dart';
import 'package:bus_51/widget/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) => MaterialApp(theme: lightTheme, home: Scaffold(body: child));

/// AppCard 최상위 Material 의 테두리(BorderSide)를 꺼낸다
BorderSide borderOf(WidgetTester tester) {
  final material = tester.widget<Material>(
    find.descendant(of: find.byType(AppCard), matching: find.byType(Material)).first,
  );
  return (material.shape as RoundedRectangleBorder).side;
}

void main() {
  group('AppCard', () {
    testWidgets('child 를 그리고 onTap 이 호출된다', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(wrap(AppCard(onTap: () => tapped++, child: const Text('내용'))));

      expect(find.text('내용'), findsOneWidget);
      await tester.tap(find.byType(AppCard));
      expect(tapped, 1);
    });

    testWidgets('기본은 그림자 없이 연한 outline 테두리', (tester) async {
      await tester.pumpWidget(wrap(const AppCard(child: SizedBox())));

      final material = tester.widget<Material>(
        find.descendant(of: find.byType(AppCard), matching: find.byType(Material)).first,
      );
      expect(material.elevation, 0);

      final outline = lightTheme.colorScheme.outline;
      final side = borderOf(tester);
      expect(side.width, 1);
      expect(side.color.r, outline.r);
      expect(side.color.a, lessThan(0.5));
    });

    testWidgets('selected 면 primary 2px 테두리', (tester) async {
      await tester.pumpWidget(wrap(const AppCard(selected: true, child: SizedBox())));

      final side = borderOf(tester);
      expect(side.width, 2);
      expect(side.color, lightTheme.colorScheme.primary);
    });
  });
}
