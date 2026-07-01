import 'package:ieoseo/theme/tokens.dart';
import 'package:ieoseo/theme/tweaks.dart';
import 'package:ieoseo/widgets/dk_badge.dart';
import 'package:ieoseo/widgets/dk_feedback.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

/// 토스트는 ink 표면(양 테마 어두움) + onInk 글자를 써야 한다. 과거엔 배경에 fgStrong 을
/// 써서 다크모드에서 흰 알약 + 흰 글자(텍스트 안 보임)가 됐다. 그 회귀를 막는다.
void main() {
  Future<void> pumpToast(WidgetTester tester, {required bool dark}) async {
    final GlobalKey<DkToastHostState> key = GlobalKey<DkToastHostState>();
    await tester.pumpWidget(
      wrapForTest(
        Stack(children: <Widget>[DkToastHost(key: key)]),
        dark: dark,
      ),
    );
    key.currentState!.show(
      const DkToastData('이벤트를 삭제했어요', icon: 'x', tone: DkTone.danger),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  BoxDecoration? toastDecoration(WidgetTester tester) {
    // 토스트 표면은 ink 색을 가진 둥근 Container 다.
    for (final Container c in tester.widgetList<Container>(
      find.byType(Container),
    )) {
      final Object? d = c.decoration;
      if (d is BoxDecoration && d.color != null && d.borderRadius != null) {
        return d;
      }
    }
    return null;
  }

  testWidgets('다크모드 토스트는 ink 배경 + onInk 글자(흰 글자 묻힘 방지)', (
    WidgetTester tester,
  ) async {
    await pumpToast(tester, dark: true);
    final DkTokens t = DkTokens.build(TweakSettings(dark: true));

    // 텍스트가 보인다(배경과 대비되는 onInk, 배경 ink 와 다름).
    final Text text = tester.widget<Text>(find.text('이벤트를 삭제했어요'));
    expect(text.style?.color, t.onInk);
    expect(toastDecoration(tester)?.color, t.ink);
    expect(t.onInk, isNot(t.ink)); // 표면과 글자색이 같으면 안 됨(가시성).

    await tester.pump(const Duration(seconds: 3)); // 소멸 타이머 소진
  });

  testWidgets('라이트모드 토스트도 ink 배경 + onInk 글자', (WidgetTester tester) async {
    await pumpToast(tester, dark: false);
    final DkTokens t = DkTokens.build(TweakSettings(dark: false));

    final Text text = tester.widget<Text>(find.text('이벤트를 삭제했어요'));
    expect(text.style?.color, t.onInk);
    expect(toastDecoration(tester)?.color, t.ink);

    await tester.pump(const Duration(seconds: 3)); // 소멸 타이머 소진
  });
}
