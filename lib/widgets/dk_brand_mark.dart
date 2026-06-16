import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tokens.dart';

/// 브랜드(심플) 아이콘이 있는 provider 키. 자산: `assets/provider/<key>.{svg,png}`.
const Set<String> kBrandKeys = <String>{'google', 'kakao', 'apple'};

/// 소셜·캘린더 provider 의 브랜드 마크(이슈 #59). 텍스트 이니셜/색점 대신 실제 로고를
/// 렌더한다 — google·apple 은 SVG(flutter_svg), kakao 는 PNG. seed-design 의
/// `dist/svg/provider/` 를 client 자산으로 들여온 것.
///
/// [brand] 는 `kBrandKeys`(google/kakao/apple). 알 수 없는 키면 빈 위젯을 반환한다.
class DkBrandMark extends StatelessWidget {
  const DkBrandMark({super.key, required this.brand, this.size = 36});

  final String brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final double radius = size * 0.3;
    switch (brand) {
      case 'google':
        // 멀티컬러 로고 → 밝은 배경 + 얇은 테두리로 가시성 확보.
        return _framed(
          bg: const Color(0xFFFFFFFF),
          border: t.border,
          radius: radius,
          child: SvgPicture.asset(
            'assets/provider/google.svg',
            width: size * 0.58,
            height: size * 0.58,
          ),
        );
      case 'kakao':
        // 카카오 마크 PNG(자체 색). 둥근 모서리로 클립.
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.asset(
            'assets/provider/kakao.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      case 'apple':
        // 단색 로고(currentColor) → 검정 배경 + 흰색 글리프.
        return _framed(
          bg: const Color(0xFF000000),
          border: null,
          radius: radius,
          child: SvgPicture.asset(
            'assets/provider/apple.svg',
            width: size * 0.54,
            height: size * 0.54,
            colorFilter: const ColorFilter.mode(
              Color(0xFFFFFFFF),
              BlendMode.srcIn,
            ),
          ),
        );
      default:
        return SizedBox(width: size, height: size);
    }
  }

  Widget _framed({
    required Color bg,
    required Color? border,
    required double radius,
    required Widget child,
  }) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: border != null ? Border.all(color: border, width: 1) : null,
      ),
      child: child,
    );
  }
}
