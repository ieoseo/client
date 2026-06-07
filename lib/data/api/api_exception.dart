import 'package:flutter/foundation.dart';

/// API 호출 실패를 표현하는 타입드 예외(이슈 #32).
///
/// 서버 envelope `error.{code,message}`를 그대로 담거나, 네트워크/타임아웃 등
/// 전송 계층 오류를 [ApiErrorKind.network]/[ApiErrorKind.timeout]로 매핑한다.
/// [message]는 사용자에게 보여줄 친화 한국어 메시지(UI에서 그대로 사용).
@immutable
class ApiException implements Exception {
  const ApiException({
    required this.kind,
    required this.code,
    required this.message,
    this.statusCode,
  });

  /// 오류 분류(분기·메시지 결정에 사용).
  final ApiErrorKind kind;

  /// 서버 안정 식별 코드(`INVALID_CREDENTIALS` 등). 전송 오류면 합성 코드.
  final String code;

  /// 사용자 친화 한국어 메시지.
  final String message;

  /// HTTP 상태 코드(있으면).
  final int? statusCode;

  /// 네트워크 연결 실패.
  factory ApiException.network() => const ApiException(
    kind: ApiErrorKind.network,
    code: 'NETWORK_ERROR',
    message: '네트워크 연결을 확인해 주세요.',
  );

  /// 타임아웃.
  factory ApiException.timeout() => const ApiException(
    kind: ApiErrorKind.timeout,
    code: 'TIMEOUT',
    message: '요청이 지연되고 있어요. 잠시 후 다시 시도해 주세요.',
  );

  /// 예기치 못한 오류.
  factory ApiException.unknown([String? message]) => ApiException(
    kind: ApiErrorKind.unknown,
    code: 'UNKNOWN',
    message: message ?? '문제가 발생했어요. 잠시 후 다시 시도해 주세요.',
  );

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}

/// API 오류 분류.
enum ApiErrorKind {
  /// 서버가 envelope로 내려준 도메인/검증 오류(409, 401, 400 등).
  server,

  /// 네트워크 연결 실패(전송 계층).
  network,

  /// 연결/수신 타임아웃.
  timeout,

  /// 분류 불가.
  unknown,
}
