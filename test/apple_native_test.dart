import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/data/auth/apple_native.dart';
import 'package:ieoseo/data/auth/social_auth.dart';

void main() {
  group('generateRawNonce', () {
    test('returns a string of the requested length', () {
      expect(generateRawNonce(32).length, 32);
      expect(generateRawNonce(16).length, 16);
    });

    test('uses only url-safe alphanumeric characters', () {
      final nonce = generateRawNonce(64);
      expect(RegExp(r'^[A-Za-z0-9]+$').hasMatch(nonce), isTrue);
    });

    test('produces a different value on each call', () {
      expect(generateRawNonce(), isNot(generateRawNonce()));
    });
  });

  group('sha256OfString', () {
    test('returns the known SHA-256 hex digest (lowercase)', () {
      // 표준 테스트 벡터: SHA-256("abc")
      expect(
        sha256OfString('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('is deterministic for the same input', () {
      expect(sha256OfString('nonce-123'), sha256OfString('nonce-123'));
    });
  });

  group('shouldUseNativeApple', () {
    test('is true only for Apple on iOS', () {
      expect(
        shouldUseNativeApple(SocialProvider.apple, TargetPlatform.iOS),
        isTrue,
      );
    });

    test('is false for Apple on non-iOS platforms', () {
      expect(
        shouldUseNativeApple(SocialProvider.apple, TargetPlatform.android),
        isFalse,
      );
    });

    test('is false for non-Apple providers even on iOS', () {
      expect(
        shouldUseNativeApple(SocialProvider.google, TargetPlatform.iOS),
        isFalse,
      );
      expect(
        shouldUseNativeApple(SocialProvider.kakao, TargetPlatform.iOS),
        isFalse,
      );
    });
  });
}
