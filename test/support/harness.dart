import 'package:ieoseo/theme/tokens.dart';
import 'package:ieoseo/theme/tweaks.dart';
import 'package:flutter/material.dart';

/// 위젯 테스트용 래퍼. [child]를 DkTheme + DefaultTextStyle로 감싼다.
/// 실제 앱(`main.dart`)의 토큰 주입과 동일한 환경을 만든다.
Widget wrapForTest(Widget child, {bool dark = false}) {
  final DkTokens tokens = DkTokens.build(TweakSettings(dark: dark));
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'Pretendard'),
    home: DkTheme(
      tokens: tokens,
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: tokens.baseFontSize,
          color: tokens.fg,
        ),
        child: Material(color: tokens.page, child: child),
      ),
    ),
  );
}
