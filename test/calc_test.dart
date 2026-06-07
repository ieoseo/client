import 'dart:math' as math;

import 'package:ieoseo/data/calc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dkEval — 기본 산술', () {
    test('덧셈·뺄셈', () {
      expect(dkEval('1+2'), 3);
      expect(dkEval('10−4'), 6); // 유니코드 마이너스
      expect(dkEval('10-4'), 6); // ASCII 하이픈
    });

    test('곱셈·나눗셈과 우선순위', () {
      expect(dkEval('2+3×4'), 14);
      expect(dkEval('2×3+4'), 10);
      expect(dkEval('20÷4÷5'), 1);
    });

    test('괄호로 우선순위를 바꾼다', () {
      expect(dkEval('(2+3)×4'), 20);
      expect(dkEval('2×(3+(4−1))'), 12);
    });

    test('거듭제곱은 우결합', () {
      expect(dkEval('2^3'), 8);
      expect(dkEval('2^3^2'), 512); // 2^(3^2)
    });

    test('단항 마이너스', () {
      expect(dkEval('−5'), -5);
      expect(dkEval('3+−2'), 1);
      expect(dkEval('−(2+3)'), -5);
    });

    test('암묵 곱셈(숫자×괄호, 괄호×괄호)', () {
      expect(dkEval('2(3)'), 6);
      expect(dkEval('(1+1)(2+2)'), 8);
    });
  });

  group('dkEval — 후위 연산자', () {
    test('퍼센트는 100으로 나눈다', () {
      expect(dkEval('50%'), 0.5);
    });

    test('팩토리얼(정수)', () {
      expect(dkEval('5!'), 120);
      expect(dkEval('0!'), 1);
    });

    test('팩토리얼(비정수)는 감마로 근사', () {
      // dkFact(0.5)=Γ(1.5)=√π / 2 ≈ 0.8862
      expect(dkEval('0.5!'), closeTo(0.8862, 0.001));
    });
  });

  group('dkEval — 함수와 상수', () {
    test('상수 π·e', () {
      expect(dkEval('π'), closeTo(math.pi, 1e-9));
      expect(dkEval('e'), closeTo(math.e, 1e-9));
    });

    test('제곱근', () {
      expect(dkEval('√(9)'), 3);
      expect(dkEval('√(16)'), 4);
    });

    test('로그(ln·log)', () {
      expect(dkEval('ln(e)'), closeTo(1, 1e-9));
      expect(dkEval('log(100)'), closeTo(2, 1e-9));
    });

    test('삼각함수 DEG(기본)', () {
      expect(dkEval('sin(30)', deg: true), closeTo(0.5, 1e-9));
      expect(dkEval('cos(60)', deg: true), closeTo(0.5, 1e-9));
    });

    test('삼각함수 RAD', () {
      expect(dkEval('sin(0)', deg: false), closeTo(0, 1e-9));
    });

    test('역삼각함수는 DEG에서 도 단위 반환', () {
      expect(dkEval('asin(0.5)', deg: true), closeTo(30, 1e-9));
    });
  });

  group('dkEval — 오류', () {
    test('닫히지 않은 괄호는 던진다', () {
      expect(() => dkEval('(1+2'), throwsA(isA<FormatException>()));
    });

    test('잘못된 문자는 던진다', () {
      expect(() => dkEval('1+@'), throwsA(isA<FormatException>()));
    });

    test('빈 식은 던진다', () {
      expect(() => dkEval(''), throwsA(isA<FormatException>()));
    });
  });

  group('dkFmt — 표시 포맷', () {
    test('정수는 천 단위 콤마', () {
      expect(dkFmt(1234567), '1,234,567');
    });

    test('소수는 정밀도 정리', () {
      expect(dkFmt(3.14), '3.14');
    });

    test('무한대/NaN은 오류', () {
      expect(dkFmt(double.infinity), '오류');
      expect(dkFmt(double.nan), '오류');
    });
  });
}
