import 'package:ieoseo/data/api/api_exception.dart';
import 'package:ieoseo/data/api/settings_api.dart';
import 'package:ieoseo/data/api/settings_dto.dart';
import 'package:ieoseo/data/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// 가짜 설정 소스. [value] 를 반환하고, [failPut] 이면 put 시 ApiException 을 던진다.
class _FakeSource implements SettingsSource {
  _FakeSource({DkSettings? value}) : value = value ?? const DkSettings();

  DkSettings value;
  bool failPut = false;
  DkSettings? lastPut;

  @override
  Future<DkSettings> get() async => value;

  @override
  Future<DkSettings> put(DkSettings settings) async {
    if (failPut) {
      throw const ApiException(
        kind: ApiErrorKind.server,
        code: 'INTERNAL_ERROR',
        message: '서버 오류',
      );
    }
    lastPut = settings;
    value = settings;
    return settings;
  }
}

void main() {
  test('load 는 서버 설정을 채우고 isLoaded 를 true 로 만든다', () async {
    final source = _FakeSource(value: const DkSettings(weekStart: 'SUN'));
    final controller = SettingsController(source);

    await controller.load();

    expect(controller.isLoaded, true);
    expect(controller.settings.weekStart, 'SUN');
    expect(controller.error, isNull);
  });

  test('save 는 낙관적으로 즉시 반영하고 PUT 한다', () async {
    final source = _FakeSource();
    final controller = SettingsController(source);
    await controller.load();

    await controller.save(const DkSettings(autoCarry: false));

    expect(controller.settings.autoCarry, false);
    expect(source.lastPut?.autoCarry, false);
  });

  test('save 실패 시 이전 값으로 롤백하고 ApiException 을 던진다', () async {
    final source = _FakeSource(value: const DkSettings(autoCarry: true));
    final controller = SettingsController(source);
    await controller.load();
    source.failPut = true;

    await expectLater(
      controller.save(const DkSettings(autoCarry: false)),
      throwsA(isA<ApiException>()),
    );
    // 롤백되어 이전 값(true) 유지.
    expect(controller.settings.autoCarry, true);
  });

  test('save 가 동일 값이면 PUT 하지 않는다', () async {
    final source = _FakeSource(value: const DkSettings());
    final controller = SettingsController(source);
    await controller.load();

    await controller.save(const DkSettings());

    expect(source.lastPut, isNull);
  });
}
