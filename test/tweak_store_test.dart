import 'package:flutter_test/flutter_test.dart';
import 'package:ieoseo/theme/tweak_store.dart';
import 'package:ieoseo/theme/tweaks.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const TweakStore store = TweakStore();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('저장이 없으면 기본 설정을 반환한다(다크모드 off)', () async {
    final TweakSettings loaded = await store.load();
    expect(loaded, const TweakSettings());
    expect(loaded.dark, isFalse);
  });

  test('다크모드를 저장하면 다시 읽었을 때 유지된다', () async {
    await store.save(const TweakSettings(dark: true));

    final TweakSettings loaded = await store.load();
    expect(loaded.dark, isTrue);
  });

  test('모든 트윅(색·배율·라운드·다크)을 라운드트립한다', () async {
    const TweakSettings t = TweakSettings(
      primary: 0xFF6541F2,
      fontScale: 1.1,
      radius: 18.0,
      dark: true,
    );

    await store.save(t);

    expect(await store.load(), t);
  });
}
