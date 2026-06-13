import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/widgets/dk_icon.dart';

/// 제공된 사양 그대로의 path 데이터(달력 몸체 + 헤더선 + 고리 2 + 이월 화살표).
/// 서브패스는 공백으로 이어 단일 `d` 문자열로 둔다(kDkIcons 규칙).
const String _expected =
    'M21 11V6a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2h6 '
    'M3 9h18 M8 2v4 M16 2v4 M14 18h6 M20 18l-2.5-2.5 M20 18l-2.5 2.5';

void main() {
  test('kDkIcons 에 carryForward 가 제공된 path 데이터 그대로 등록된다', () {
    expect(kDkIcons['carryForward'], _expected);
  });

  testWidgets('DkIcon(carryForward) 는 빈 자리표시자가 아니라 아이콘을 렌더한다', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: DkIcon('carryForward', size: 22),
      ),
    );
    // 알 수 없는 이름이면 DkIcon 은 SizedBox 폴백만 그린다. 등록되면 SvgPicture 가 생긴다.
    expect(find.byType(DkIcon), findsOneWidget);
    expect(
      find.byType(SvgPicture),
      findsOneWidget,
      reason: 'carryForward 가 kDkIcons 에 없으면 SvgPicture 대신 SizedBox 폴백이 그려진다',
    );
  });
}
