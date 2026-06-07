import 'dart:convert';
import 'dart:typed_data';

import 'package:ieoseo/data/api/api_client.dart';
import 'package:ieoseo/data/api/api_config.dart';
import 'package:ieoseo/data/api/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// envelope 헬퍼.
Map<String, dynamic> ok(Object? data) => <String, dynamic>{
  'success': true,
  'data': data,
  'error': null,
  'meta': null,
};

Map<String, dynamic> fail(String code, String message) => <String, dynamic>{
  'success': false,
  'data': null,
  'error': <String, dynamic>{'code': code, 'message': message},
  'meta': null,
};

/// 호출마다 다른 응답을 돌려주는 스크립트형 가짜 어댑터.
/// http_mock_adapter는 같은 라우트에 순차 응답을 못 줘서 401→200 재시도 검증에 사용.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._steps);
  final List<({int status, Map<String, dynamic> body})> _steps;
  int calls = 0;
  final List<RequestOptions> seen = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    seen.add(options);
    final step = _steps[calls < _steps.length ? calls : _steps.length - 1];
    calls += 1;
    return ResponseBody.fromString(
      jsonEncode(step.body),
      step.status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(HttpClientAdapter adapter) {
  final Dio dio = Dio(
    BaseOptions(baseUrl: apiBaseUrl, validateStatus: (int? _) => true),
  );
  dio.httpClientAdapter = adapter;
  return dio;
}

void main() {
  test('성공 envelope를 언랩해 data만 반환한다', () async {
    final Dio dio = Dio(
      BaseOptions(baseUrl: apiBaseUrl, validateStatus: (int? _) => true),
    );
    final DioAdapter adapter = DioAdapter(dio: dio);
    adapter.onGet('/ping', (server) => server.reply(200, ok({'v': 1})));
    final ApiClient client = ApiClient(dio: dio);

    final dynamic data = await client.get('/ping');

    expect(data, <String, dynamic>{'v': 1});
  });

  test('저장된 access 토큰을 Authorization 헤더로 부착한다', () async {
    final _ScriptedAdapter adapter = _ScriptedAdapter(
      <({int status, Map<String, dynamic> body})>[
        (status: 200, body: ok({'ok': true})),
      ],
    );
    final Dio dio = _dioWith(adapter);
    final ApiClient client = ApiClient(
      dio: dio,
      accessTokenReader: () async => 'acc-1',
    );

    await client.get('/auth/me');

    expect(adapter.seen.single.headers['Authorization'], 'Bearer acc-1');
  });

  test('skipAuth POST는 Authorization을 부착하지 않는다', () async {
    final _ScriptedAdapter adapter = _ScriptedAdapter(
      <({int status, Map<String, dynamic> body})>[
        (status: 200, body: ok({'ok': true})),
      ],
    );
    final Dio dio = _dioWith(adapter);
    final ApiClient client = ApiClient(
      dio: dio,
      accessTokenReader: () async => 'acc-1',
    );

    await client.post(
      '/auth/login',
      body: <String, dynamic>{'email': 'a@b.com'},
      skipAuth: true,
    );

    expect(adapter.seen.single.headers.containsKey('Authorization'), isFalse);
  });

  test('401이면 refresh 1회 후 원요청을 재시도한다', () async {
    final _ScriptedAdapter adapter = _ScriptedAdapter(
      <({int status, Map<String, dynamic> body})>[
        (status: 401, body: fail('UNAUTHORIZED', '만료')),
        (status: 200, body: ok({'id': 'u1'})),
      ],
    );
    final Dio dio = _dioWith(adapter);
    int refreshCount = 0;
    final ApiClient client = ApiClient(
      dio: dio,
      accessTokenReader: () async => 'old',
      tokenRefresher: () async {
        refreshCount += 1;
        return 'new';
      },
    );

    final dynamic data = await client.get('/auth/me');

    expect(refreshCount, 1);
    expect(adapter.calls, 2);
    expect(adapter.seen.last.headers['Authorization'], 'Bearer new');
    expect(data, <String, dynamic>{'id': 'u1'});
  });

  test('refresh 실패면 401을 그대로 ApiException으로 던진다', () async {
    final _ScriptedAdapter adapter = _ScriptedAdapter(
      <({int status, Map<String, dynamic> body})>[
        (status: 401, body: fail('UNAUTHORIZED', '만료')),
      ],
    );
    final Dio dio = _dioWith(adapter);
    final ApiClient client = ApiClient(
      dio: dio,
      accessTokenReader: () async => 'old',
      tokenRefresher: () async => null,
    );

    expect(
      () => client.get('/auth/me'),
      throwsA(
        isA<ApiException>()
            .having((ApiException e) => e.statusCode, 'status', 401)
            .having((ApiException e) => e.kind, 'kind', ApiErrorKind.server),
      ),
    );
  });

  test('서버 오류 envelope의 code/message를 ApiException으로 매핑한다', () async {
    final _ScriptedAdapter adapter = _ScriptedAdapter(
      <({int status, Map<String, dynamic> body})>[
        (status: 409, body: fail('EMAIL_TAKEN', '이미 가입된 이메일이에요.')),
      ],
    );
    final Dio dio = _dioWith(adapter);
    final ApiClient client = ApiClient(dio: dio);

    expect(
      () => client.post(
        '/auth/signup',
        body: <String, dynamic>{'email': 'dup@b.com'},
        skipAuth: true,
      ),
      throwsA(
        isA<ApiException>()
            .having((ApiException e) => e.code, 'code', 'EMAIL_TAKEN')
            .having((ApiException e) => e.message, 'message', '이미 가입된 이메일이에요.'),
      ),
    );
  });

  test('연결 오류는 network ApiException으로 매핑한다', () async {
    final Dio dio = Dio(
      BaseOptions(baseUrl: apiBaseUrl, validateStatus: (int? _) => true),
    );
    final DioAdapter adapter = DioAdapter(dio: dio);
    adapter.onGet(
      '/ping',
      (server) => server.throws(
        -1,
        DioException.connectionError(
          requestOptions: RequestOptions(path: '/ping'),
          reason: 'no internet',
        ),
      ),
    );
    final ApiClient client = ApiClient(dio: dio);

    expect(
      () => client.get('/ping'),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.kind,
          'kind',
          ApiErrorKind.network,
        ),
      ),
    );
  });
}
