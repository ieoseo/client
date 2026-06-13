import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/data/meta.dart';
import 'package:ieoseo/screens/me/settings_section.dart';
import 'package:ieoseo/theme/tokens.dart';
import 'package:ieoseo/widgets/dk_coming_soon.dart';

import 'support/harness.dart';

void main() {
  group('DkComingSoon', () {
    testWidgets('자식을 뮤트(낮은 불투명도)로 감싸고 준비 중 뱃지를 보여준다', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapForTest(
          const DkComingSoon(
            child: Text('아바타', key: ValueKey<String>('child')),
          ),
        ),
      );

      // 준비 중 어포던스 라벨(공용 문구가 아닌 짧은 뱃지 텍스트)이 보인다.
      expect(find.text(kComingSoonBadgeLabel), findsOneWidget);

      // 자식이 뮤트(Opacity < 1)로 렌더된다.
      final Opacity muted = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byKey(const ValueKey<String>('child')),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(muted.opacity, lessThan(1.0));
      expect(muted.opacity, equals(kComingSoonOpacity));
    });

    testWidgets('탭하면 onTap 콜백이 호출된다(여전히 탭 가능)', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        wrapForTest(
          DkComingSoon(
            onTap: () => taps++,
            child: const SizedBox(
              key: ValueKey<String>('child'),
              width: 80,
              height: 40,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DkComingSoon));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('badge: false 면 준비 중 뱃지를 숨긴다', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapForTest(const DkComingSoon(badge: false, child: Text('아바타'))),
      );

      expect(find.text(kComingSoonBadgeLabel), findsNothing);
    });
  });

  group('SettingRow comingSoon', () {
    testWidgets('comingSoon 행은 준비 중 뱃지를 보여주고 라벨을 뮤트색으로 칠한다', (
      WidgetTester tester,
    ) async {
      late DkTokens t;
      await tester.pumpWidget(
        wrapForTest(
          Builder(
            builder: (BuildContext context) {
              t = DkTheme.of(context);
              return const SettingGroup(
                children: <Widget>[
                  SettingRow(
                    icon: 'bell',
                    label: '알림 설정',
                    comingSoon: true,
                    last: true,
                  ),
                ],
              );
            },
          ),
        ),
      );

      // 준비 중 뱃지가 보인다.
      expect(find.text(kComingSoonBadgeLabel), findsOneWidget);

      // 라벨이 뮤트색(fgSubtle)으로 칠해진다(활성 행 fg와 구분).
      final Text label = tester.widget<Text>(find.text('알림 설정'));
      expect(label.style?.color, t.fgSubtle);
    });

    testWidgets('comingSoon 행도 탭하면 onTap 콜백을 호출한다', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        wrapForTest(
          SettingGroup(
            children: <Widget>[
              SettingRow(
                icon: 'bell',
                label: '알림 설정',
                comingSoon: true,
                last: true,
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('알림 설정'));
      await tester.pump();
      expect(taps, 1);
    });
  });
}
