import 'package:shared_preferences/shared_preferences.dart';

import 'tweaks.dart';

/// [TweakSettings](브랜드색·글자배율·라운드·**다크모드**) 로컬 영속화.
///
/// `shared_preferences` 에 저장해 앱을 나갔다 들어와도 유지한다(다크모드 초기화 버그 해소).
/// 읽기/쓰기 실패(테스트·플랫폼 미지원)는 조용히 기본값/무시로 폴백한다.
class TweakStore {
  const TweakStore();

  static const String _kPrimary = 'tweak.primary';
  static const String _kFontScale = 'tweak.fontScale';
  static const String _kRadius = 'tweak.radius';
  static const String _kDark = 'tweak.dark';

  /// 저장된 설정을 읽는다. 키가 없으면 기본값([TweakSettings])으로 채운다.
  Future<TweakSettings> load() async {
    const TweakSettings d = TweakSettings();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return TweakSettings(
        primary: prefs.getInt(_kPrimary) ?? d.primary,
        fontScale: prefs.getDouble(_kFontScale) ?? d.fontScale,
        radius: prefs.getDouble(_kRadius) ?? d.radius,
        dark: prefs.getBool(_kDark) ?? d.dark,
      );
    } on Exception {
      return d; // 저장소 접근 실패 시 기본값
    }
  }

  /// 설정을 저장한다(실패는 무시 — 베스트에포트).
  Future<void> save(TweakSettings t) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kPrimary, t.primary);
      await prefs.setDouble(_kFontScale, t.fontScale);
      await prefs.setDouble(_kRadius, t.radius);
      await prefs.setBool(_kDark, t.dark);
    } on Exception {
      // 저장 실패는 치명적이지 않다(다음 변경 때 재시도).
    }
  }
}
