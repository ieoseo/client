import 'package:flutter/foundation.dart';

/// 관측성(Sentry) 설정값. `--dart-define` 으로 주입된 컴파일타임 값에서 만든다(ADR-0011).
///
/// DSN 이 비어 있으면 [isEnabled] 가 false 가 되어 `main()` 이 Sentry 를 초기화하지
/// 않는다(외부 전송 0). DSN 은 시크릿이므로 소스/문서에 하드코딩하지 않는다.
@immutable
class SentryConfig {
  const SentryConfig({
    required this.dsn,
    required this.environment,
    required this.tracesSampleRate,
  });

  /// Sentry 프로젝트 DSN(`SENTRY_DSN`). 빈 값이면 비활성.
  final String dsn;

  /// 환경 태그(`SENTRY_ENVIRONMENT`, 예: local/staging/production).
  final String environment;

  /// 성능 트레이스 샘플링 비율(0.0~1.0). 기본 0.0 = 에러만.
  final double tracesSampleRate;

  /// DSN 이 설정돼 실제 초기화/전송이 이뤄지는지 여부.
  bool get isEnabled => dsn.isNotEmpty;

  /// `--dart-define` 환경에서 구성값을 읽어 만든다(미설정 시 비활성).
  /// 빈 값 정규화(environment→local, rate→0.0)는 [parse] 가 담당한다.
  factory SentryConfig.fromEnvironment() {
    const String dsn = String.fromEnvironment('SENTRY_DSN');
    const String environment = String.fromEnvironment('SENTRY_ENVIRONMENT');
    const String rate = String.fromEnvironment('SENTRY_TRACES_SAMPLE_RATE');
    return SentryConfig.parse(
      dsn: dsn,
      environment: environment,
      rawTracesSampleRate: rate,
    );
  }

  /// 원시 문자열 값에서 설정을 만든다(파싱·정규화 로직의 단일 지점, 테스트 대상).
  factory SentryConfig.parse({
    required String dsn,
    required String environment,
    required String rawTracesSampleRate,
  }) {
    final String env = environment.isEmpty ? 'local' : environment;
    return SentryConfig(
      dsn: dsn,
      environment: env,
      tracesSampleRate: _clampRate(rawTracesSampleRate),
    );
  }

  /// 샘플링 비율 파싱: 숫자가 아니거나 범위를 벗어나면 0.0~1.0 으로 보정.
  static double _clampRate(String raw) {
    final double? parsed = double.tryParse(raw);
    if (parsed == null) return 0.0;
    if (parsed < 0.0) return 0.0;
    if (parsed > 1.0) return 1.0;
    return parsed;
  }
}
