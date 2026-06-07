import 'package:ieoseo/observability/sentry_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SentryConfig.parse', () {
    test('DSN 이 비면 비활성(isEnabled=false)이다', () {
      final config = SentryConfig.parse(
        dsn: '',
        environment: 'local',
        rawTracesSampleRate: '0.0',
      );

      expect(config.isEnabled, isFalse);
    });

    test('DSN 이 있으면 활성(isEnabled=true)이다', () {
      final config = SentryConfig.parse(
        dsn: 'https://examplePublicKey@o0.ingest.sentry.io/0',
        environment: 'production',
        rawTracesSampleRate: '0.2',
      );

      expect(config.isEnabled, isTrue);
      expect(config.environment, 'production');
      expect(config.tracesSampleRate, 0.2);
    });

    test('environment 가 비면 local 로 정규화된다', () {
      final config = SentryConfig.parse(
        dsn: 'https://k@o0.ingest.sentry.io/0',
        environment: '',
        rawTracesSampleRate: '0.0',
      );

      expect(config.environment, 'local');
    });

    test('샘플링 비율이 숫자가 아니면 0.0 으로 보정된다', () {
      final config = SentryConfig.parse(
        dsn: 'https://k@o0.ingest.sentry.io/0',
        environment: 'local',
        rawTracesSampleRate: 'not-a-number',
      );

      expect(config.tracesSampleRate, 0.0);
    });

    test('샘플링 비율이 범위를 벗어나면 0.0~1.0 으로 클램프된다', () {
      final tooHigh = SentryConfig.parse(
        dsn: 'https://k@o0.ingest.sentry.io/0',
        environment: 'local',
        rawTracesSampleRate: '5.0',
      );
      final negative = SentryConfig.parse(
        dsn: 'https://k@o0.ingest.sentry.io/0',
        environment: 'local',
        rawTracesSampleRate: '-1.0',
      );

      expect(tooHigh.tracesSampleRate, 1.0);
      expect(negative.tracesSampleRate, 0.0);
    });
  });
}
