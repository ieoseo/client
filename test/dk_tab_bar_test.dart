import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/widgets/dk_tab_bar.dart';

import 'support/harness.dart';

void main() {
  // 시스템 내비게이션 inset(viewPadding.bottom)을 주입했을 때, 탭바 하단 패딩이
  // 이를 반영해 전체 높이가 inset 만큼 커지는지 검증한다(edge-to-edge 겹침 방지).
  Future<double> tabBarHeight(WidgetTester tester, double bottomInset) async {
    await tester.pumpWidget(
      wrapForTest(
        MediaQuery(
          data: MediaQueryData(
            viewPadding: EdgeInsets.only(bottom: bottomInset),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: DkTabBar(
              active: DkTab.today,
              onChanged: (_) {},
              onAdd: () {},
            ),
          ),
        ),
      ),
    );
    return tester.getSize(find.byType(DkTabBar)).height;
  }

  testWidgets('시스템 바가 없으면 디자인 하단 패딩(22)을 유지한다', (WidgetTester tester) async {
    final double noInset = await tabBarHeight(tester, 0);
    final double withInset = await tabBarHeight(tester, 48);

    // bottom = max(22, inset + 8): inset 0 → 22, inset 48 → 56. 차이는 34.
    expect(withInset, noInset + 34);
  });

  testWidgets('작은 inset(제스처 바)도 22 미만으로 깎이지 않는다', (WidgetTester tester) async {
    final double noInset = await tabBarHeight(tester, 0);
    final double tinyInset = await tabBarHeight(tester, 10);

    // max(22, 10 + 8) = 22 → 높이 변화 없음.
    expect(tinyInset, noInset);
  });

  testWidgets('가운데 + 버튼 탭은 onAdd를 호출한다', (WidgetTester tester) async {
    bool added = false;
    await tester.pumpWidget(
      wrapForTest(
        Align(
          alignment: Alignment.bottomCenter,
          child: DkTabBar(
            active: DkTab.today,
            onChanged: (_) {},
            onAdd: () => added = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('tabbar-add')));
    await tester.pump();
    expect(added, true);
  });
}
