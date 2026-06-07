import 'package:ieoseo/data/api/api_client.dart';
import 'package:ieoseo/data/api/api_config.dart';
import 'package:ieoseo/data/api/api_exception.dart';
import 'package:ieoseo/data/api/settings_api.dart';
import 'package:ieoseo/data/api/settings_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

/// SettingsApi 테스트(이슈 #56). DioAdapter 가짜 HTTP 로 GET/PUT 검증.
Map<String, dynamic> _ok(Object? data) => <String, dynamic>{
  'success': true,
  'data': data,
  'error': null,
  'meta': null,
};

Map<String, dynamic> _settingsJson({
  bool autoCarry = true,
  String weekStart = 'MON',
  int pomodoroFocus = 25,
}) => <String, dynamic>{
  'autoCarry': autoCarry,
  'dayDeadlineHour': 0,
  'weekStart': weekStart,
  'maxDailyMinutes': 480,
  'pomodoroFocus': pomodoroFocus,
  'pomodoroShortBreak': 5,
  'pomodoroLongBreak': 15,
  'completionSound': true,
};

({Dio dio, DioAdapter adapter, SettingsApi api}) _harness() {
  final Dio dio = Dio(
    BaseOptions(baseUrl: apiBaseUrl, validateStatus: (int? _) => true),
  );
  final DioAdapter adapter = DioAdapter(dio: dio);
  final SettingsApi api = SettingsApi(ApiClient(dio: dio));
  return (dio: dio, adapter: adapter, api: api);
}

void main() {
  test('get 은 GET /auth/me/settings 를 파싱한다', () async {
    final h = _harness();
    h.adapter.onGet(
      '/auth/me/settings',
      (server) => server.reply(200, _ok(_settingsJson(weekStart: 'SUN'))),
    );

    final DkSettings settings = await h.api.get();

    expect(settings.weekStart, 'SUN');
    expect(settings.maxDailyMinutes, 480);
    expect(settings.pomodoroFocus, 25);
  });

  test('put 은 PUT 본문을 보내고 갱신 설정을 반환한다', () async {
    final h = _harness();
    const DkSettings next = DkSettings(
      autoCarry: false,
      weekStart: 'SUN',
      pomodoroFocus: 50,
    );
    h.adapter.onPut(
      '/auth/me/settings',
      (server) => server.reply(
        200,
        _ok(
          _settingsJson(autoCarry: false, weekStart: 'SUN', pomodoroFocus: 50),
        ),
      ),
      data: next.toJson(),
    );

    final DkSettings saved = await h.api.put(next);

    expect(saved.autoCarry, false);
    expect(saved.pomodoroFocus, 50);
  });

  test('get 401 은 ApiException 으로 매핑된다', () async {
    final h = _harness();
    h.adapter.onGet(
      '/auth/me/settings',
      (server) => server.reply(401, <String, dynamic>{
        'success': false,
        'data': null,
        'error': <String, dynamic>{
          'code': 'UNAUTHORIZED',
          'message': '로그인이 필요해요.',
        },
        'meta': null,
      }),
    );

    await expectLater(
      h.api.get(),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'UNAUTHORIZED'),
      ),
    );
  });
}
