import 'package:dio/dio.dart';

import 'api_config.dart';
import 'api_exception.dart';

/// 현재 access 토큰을 비동기로 반환(없으면 null).
typedef AccessTokenReader = Future<String?> Function();

/// 401 시 토큰 재발급 시도. 성공 시 새 access 토큰 반환, 실패 시 null.
typedef TokenRefresher = Future<String?> Function();

/// dio 래퍼(이슈 #32).
///
/// - baseUrl + connect/receive 타임아웃
/// - 요청 인터셉터: access 토큰을 `Authorization: Bearer`로 부착
///   (단 [kSkipAuthFlag] 요청은 제외 — 인증 공개 엔드포인트)
/// - 401 시 [TokenRefresher]로 1회 재발급 후 원요청 재시도([kRetriedFlag] 가드)
/// - 응답 envelope `{success,data,error}` 언랩 → `data` 반환
/// - 실패는 [ApiException]으로 매핑(네트워크/타임아웃/서버 코드)
///
/// 토큰 평문은 로깅하지 않는다.
class ApiClient {
  ApiClient({
    Dio? dio,
    AccessTokenReader? accessTokenReader,
    TokenRefresher? tokenRefresher,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: apiBaseUrl,
               connectTimeout: kConnectTimeout,
               receiveTimeout: kReceiveTimeout,
               contentType: 'application/json; charset=utf-8',
               // 4xx/5xx도 응답으로 받아 envelope를 직접 언랩한다.
               validateStatus: (int? _) => true,
             ),
           ),
       _readAccessToken = accessTokenReader,
       _refreshToken = tokenRefresher {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  final Dio _dio;
  final AccessTokenReader? _readAccessToken;
  final TokenRefresher? _refreshToken;

  /// 인터셉터/refresh 등록을 위해 노출(테스트·확장용).
  Dio get dio => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 재시도 요청은 _onResponse가 갱신한 Bearer 헤더를 그대로 쓴다(덮어쓰기 금지).
    final bool isRetry = options.extra[kRetriedFlag] == true;
    final bool skipAuth = options.extra[kSkipAuthFlag] == true;
    if (!skipAuth && !isRetry && _readAccessToken != null) {
      final String? token = await _readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  /// `validateStatus`가 모든 상태를 통과시키므로 401은 정상 응답으로 들어온다.
  /// 여기서 401을 감지해 refresh 후 1회 재시도한다([kRetriedFlag] 가드).
  Future<void> _onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final RequestOptions req = response.requestOptions;
    final bool canRefresh =
        _refreshToken != null &&
        req.extra[kSkipAuthFlag] != true &&
        req.extra[kRetriedFlag] != true &&
        response.statusCode == 401;

    if (canRefresh) {
      final String? fresh = await _refreshToken();
      if (fresh != null && fresh.isNotEmpty) {
        req.extra[kRetriedFlag] = true;
        req.headers['Authorization'] = 'Bearer $fresh';
        try {
          final Response<dynamic> retry = await _dio.fetch<dynamic>(req);
          return handler.resolve(retry);
        } on DioException catch (e) {
          return handler.reject(e);
        }
      }
    }
    handler.next(response);
  }

  /// 전송 계층 오류만 도달(`validateStatus`가 4xx/5xx를 통과시키므로 보통
  /// 도메인 오류는 여기 오지 않는다). 그대로 통과시켜 [_send]에서 매핑.
  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    handler.next(error);
  }

  /// GET → envelope 언랩된 `data`.
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get<dynamic>(path, queryParameters: query));

  /// POST → envelope 언랩된 `data`.
  /// [skipAuth] true면 Authorization 부착을 생략(공개 인증 엔드포인트).
  Future<dynamic> post(String path, {Object? body, bool skipAuth = false}) =>
      _send(
        () => _dio.post<dynamic>(
          path,
          data: body,
          options: Options(extra: <String, dynamic>{kSkipAuthFlag: skipAuth}),
        ),
      );

  /// PUT → envelope 언랩된 `data`(전체 수정).
  Future<dynamic> put(String path, {Object? body}) =>
      _send(() => _dio.put<dynamic>(path, data: body));

  /// PATCH → envelope 언랩된 `data`(부분 수정, 예: 알림 읽음 처리).
  Future<dynamic> patch(String path, {Object? body}) =>
      _send(() => _dio.patch<dynamic>(path, data: body));

  /// DELETE → 204 No Content. 성공이면 null.
  Future<void> delete(String path) async {
    await _send(() => _dio.delete<dynamic>(path));
  }

  /// 응답을 보내고 envelope를 언랩한다. 전송/서버 오류는 [ApiException]으로 변환.
  Future<dynamic> _send(Future<Response<dynamic>> Function() run) async {
    final Response<dynamic> res;
    try {
      res = await run();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
    return _unwrap(res);
  }

  /// envelope `{success,data,error}` 언랩. 실패면 [ApiException] throw.
  dynamic _unwrap(Response<dynamic> res) {
    final int status = res.statusCode ?? 0;
    final dynamic raw = res.data;

    // 204 No Content(DELETE) 등 본문 없는 성공 → null.
    final bool isEmptyBody = raw == null || (raw is String && raw.isEmpty);
    if (isEmptyBody && status >= 200 && status < 300) {
      return null;
    }

    if (raw is Map<String, dynamic>) {
      final bool success = raw['success'] == true;
      if (success && status >= 200 && status < 300) {
        return raw['data'];
      }
      final Object? err = raw['error'];
      if (err is Map<String, dynamic>) {
        throw ApiException(
          kind: ApiErrorKind.server,
          code: (err['code'] as String?) ?? 'UNKNOWN',
          message: (err['message'] as String?) ?? _defaultMessage(status),
          statusCode: status,
        );
      }
    }

    // envelope가 아니거나 비정상 → 상태 기반 매핑.
    throw ApiException(
      kind: ApiErrorKind.server,
      code: _codeForStatus(status),
      message: _defaultMessage(status),
      statusCode: status,
    );
  }

  ApiException _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException.timeout();
      case DioExceptionType.connectionError:
        return ApiException.network();
      case DioExceptionType.badResponse:
        // validateStatus가 true라 보통 여기 오지 않지만 방어적으로 언랩 시도.
        final Response<dynamic>? res = e.response;
        if (res != null) {
          try {
            _unwrap(res);
          } on ApiException catch (mapped) {
            return mapped;
          }
        }
        return ApiException.unknown();
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        if (e.error != null && _looksLikeNetwork(e)) {
          return ApiException.network();
        }
        return ApiException.unknown();
    }
  }

  bool _looksLikeNetwork(DioException e) {
    final String s = e.error.toString().toLowerCase();
    return s.contains('socket') ||
        s.contains('connection') ||
        s.contains('network') ||
        s.contains('failed host lookup');
  }

  String _codeForStatus(int status) => switch (status) {
    401 => 'UNAUTHORIZED',
    403 => 'FORBIDDEN',
    404 => 'NOT_FOUND',
    409 => 'CONFLICT',
    >= 500 => 'INTERNAL_ERROR',
    _ => 'BAD_REQUEST',
  };

  String _defaultMessage(int status) => switch (status) {
    401 => '로그인이 필요해요.',
    403 => '접근 권한이 없어요.',
    404 => '요청한 정보를 찾을 수 없어요.',
    409 => '이미 처리된 요청이에요.',
    >= 500 => '서버에 문제가 생겼어요. 잠시 후 다시 시도해 주세요.',
    _ => '요청을 처리하지 못했어요.',
  };
}
