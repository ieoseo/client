import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/theme/seed_components.dart';
import 'package:ieoseo/theme/tokens.dart';
import 'package:ieoseo/theme/tweaks.dart';
import 'package:ieoseo/widgets/dk_button.dart';

import 'support/harness.dart';

void main() {
  group('DkButton — seed 컴포넌트 스펙 소비', () {
    testWidgets('md 버튼 높이는 seed sizes[md].height 를 따른다', (tester) async {
      await tester.pumpWidget(
        wrapForTest(const Center(child: DkButton(child: Text('확인')))),
      );

      final Size size = tester.getSize(find.byType(DkButton));
      expect(size.height, SeedButton.sizes['md']!.height);
      expect(size.height, 50);
    });

    testWidgets('lg 버튼 높이는 seed sizes[lg].height 를 따른다', (tester) async {
      await tester.pumpWidget(
        wrapForTest(
          const Center(
            child: DkButton(size: DkButtonSize.lg, child: Text('확인')),
          ),
        ),
      );

      final Size size = tester.getSize(find.byType(DkButton));
      expect(size.height, SeedButton.sizes['lg']!.height);
      expect(size.height, 56);
    });

    testWidgets('primary 변형 배경은 테마 primary 색을 쓴다', (tester) async {
      await tester.pumpWidget(
        wrapForTest(const Center(child: DkButton(child: Text('확인')))),
      );

      final DkTokens t = DkTokens.build(TweakSettings(dark: false));
      final Iterable<Container> filled = tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (Container c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).color == t.primary,
          );
      expect(filled, isNotEmpty);
    });

    test('SeedButton 권위값(디자인 스펙)과 일치', () {
      expect(SeedButton.weight, 600);
      expect(SeedButton.sizes['md']!.radius, 14);
      expect(SeedButton.sizes['lg']!.fontSize, 16);
      expect(SeedButton.variants['primary']!.bg, 'primary');
      expect(SeedButton.variants['subtle']!.fg, 'primary');
    });
  });
}
