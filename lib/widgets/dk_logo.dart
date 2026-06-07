import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// 이어서 로고. 앱 아이콘 마스터(`assets/icon/ieoseo-icon-1024.png`)를 둥근 박스로
/// 표시 + "이어서" wordmark(brand size×.62/800). 런처 아이콘과 동일 비주얼을 쓴다.
class DkLogo extends StatelessWidget {
  const DkLogo({super.key, this.size = 40, this.light = false});

  final double size;

  /// 어두운 배경 위에서 wordmark를 흰색으로.
  final bool light;

  /// 런처 아이콘 마스터와 동일 PNG(pubspec `assets` 에 등록).
  static const String _markAsset = 'assets/icon/ieoseo-icon-1024.png';

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final BorderRadius radius = BorderRadius.circular(size * 0.30);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: t.primary.withValues(alpha: 0.22),
                offset: const Offset(0, 4),
                blurRadius: 14,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Image.asset(
              _markAsset,
              width: size,
              height: size,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '이어서',
          style: TextStyle(
            fontFamily: 'WantedSans',
            fontSize: size * 0.62,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.04 * size * 0.62,
            color: light ? const Color(0xFFFFFFFF) : t.fgStrong,
          ),
        ),
      ],
    );
  }
}
