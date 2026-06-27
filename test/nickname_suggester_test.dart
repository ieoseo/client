import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/data/auth/nickname_suggester.dart';

/// 랜덤 닉네임 제안 생성기 테스트(형용사+동물, 예: "행복한하마").
void main() {
  test('형용사+동물 조합을 만든다(사전 단어로 구성)', () {
    final String nickname = suggestNickname(Random(1));
    final bool hasAdjective = kNicknameAdjectives.any(nickname.startsWith);
    final bool hasAnimal = kNicknameAnimals.any(nickname.endsWith);
    expect(hasAdjective, isTrue);
    expect(hasAnimal, isTrue);
  });

  test('닉네임 최대 길이(20자)를 넘지 않는다', () {
    for (int seed = 0; seed < 50; seed++) {
      expect(suggestNickname(Random(seed)).length, lessThanOrEqualTo(20));
    }
  });

  test('같은 시드는 같은 값, 다른 시드는 보통 다른 값', () {
    expect(suggestNickname(Random(7)), suggestNickname(Random(7)));
    // 서로 다른 시드 다수에서 모두 동일할 확률은 무시 가능.
    final Set<String> values = <String>{
      for (int s = 0; s < 20; s++) suggestNickname(Random(s)),
    };
    expect(values.length, greaterThan(1));
  });

  test('단어 사전이 비어있지 않다', () {
    expect(kNicknameAdjectives, isNotEmpty);
    expect(kNicknameAnimals, isNotEmpty);
  });
}
