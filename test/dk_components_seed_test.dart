import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/theme/seed_components.dart';
import 'package:ieoseo/theme/tokens.dart';
import 'package:ieoseo/theme/tweaks.dart';
import 'package:ieoseo/widgets/dk_badge.dart';
import 'package:ieoseo/widgets/dk_card.dart';
import 'package:ieoseo/widgets/dk_segmented.dart';

import 'support/harness.dart';

void main() {
  final DkTokens t = DkTokens.build(TweakSettings(dark: false));

  group('DkTokens.byKey — seed 색 키 해석', () {
    test('scheme 키·transparent·#hex 를 색으로 해석', () {
      expect(t.byKey('primary'), t.primary);
      expect(t.byKey('primarySubtle'), t.primarySubtle);
      expect(t.byKey('transparent'), const Color(0x00000000));
      expect(t.byKey('#FFFFFF'), const Color(0xFFFFFFFF));
    });
  });

  group('DkBadge — seed 스펙 소비', () {
    test('톤 매핑은 SeedBadge.tones 를 byKey 로 해석', () {
      for (final DkTone tone in DkTone.values) {
        final SeedTone st = SeedBadge.tones[tone.name]!;
        final ({Color bg, Color fg}) c = dkToneColors(t, tone);
        expect(c.bg, t.byKey(st.bg));
        expect(c.fg, t.byKey(st.fg));
      }
    });

    test('SeedBadge 권위값', () {
      expect(SeedBadge.radius, 8);
      expect(SeedBadge.fontSize, 12);
      expect(SeedBadge.tones.length, DkTone.values.length);
      expect(SeedBadge.tones['primary']!.bg, 'primarySubtle');
    });

    testWidgets('라벨을 렌더한다', (tester) async {
      await tester.pumpWidget(
        wrapForTest(const Center(child: DkBadge('완료', tone: DkTone.success))),
      );
      expect(find.text('완료'), findsOneWidget);
    });
  });

  group('DkCard — seed 스펙 소비', () {
    test('기본 padding 은 SeedCard.padding', () {
      const DkCard card = DkCard(child: SizedBox());
      expect(card.padding, SeedCard.padding);
      expect(SeedCard.padding, 18);
    });

    testWidgets('자식을 렌더한다', (tester) async {
      await tester.pumpWidget(
        wrapForTest(const Center(child: DkCard(child: Text('카드')))),
      );
      expect(find.text('카드'), findsOneWidget);
    });
  });

  group('DkSegmented — seed 스펙 소비', () {
    test('SeedSegmented 권위값', () {
      expect(SeedSegmented.radius, 12);
      expect(SeedSegmented.thumbRadius, 9);
      expect(SeedSegmented.fontSize, 14);
    });

    testWidgets('옵션 라벨을 렌더한다', (tester) async {
      await tester.pumpWidget(
        wrapForTest(
          Center(
            child: DkSegmented<int>(
              options: const <DkSegment<int>>[
                DkSegment<int>(0, '월'),
                DkSegment<int>(1, '주'),
              ],
              value: 0,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('월'), findsOneWidget);
      expect(find.text('주'), findsOneWidget);
    });
  });
}
