import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tokens.dart';

/// 브랜드(심플) 아이콘이 있는 provider 키. 자산: `assets/provider/<key>.{svg,png}`
/// (이어서 앱 출처는 런처 아이콘 마스터를 재사용).
const Set<String> kBrandKeys = <String>{
  'google',
  'kakao',
  'apple',
  'notion',
  'ieoseo',
};

/// 소셜·캘린더 provider 의 브랜드 마크(이슈 #59). 텍스트 이니셜/색점 대신 실제 로고를
/// 렌더한다 — google·apple 은 SVG(flutter_svg), kakao 는 PNG. seed-design 의
/// `dist/svg/provider/` 를 client 자산으로 들여온 것.
///
/// [brand] 는 `kBrandKeys`(google/kakao/apple). 알 수 없는 키면 빈 위젯을 반환한다.
class DkBrandMark extends StatelessWidget {
  const DkBrandMark({
    super.key,
    required this.brand,
    this.size = 36,
    this.framed = true,
    this.glyphColor,
  });

  final String brand;
  final double size;

  /// true(기본)면 배경 박스/테두리로 감싼 마크(목록·카드용). false 면 글리프만 직접
  /// 렌더(로그인 버튼처럼 이미 배경색이 있는 곳 — 박스가 겹쳐 "테두리"처럼 보이는 것 방지).
  final bool framed;

  /// 단색 글리프(apple·kakao) 틴트색. framed:false 에서 버튼 전경색을 넘긴다.
  /// google 은 멀티컬러라 무시한다. null 이면 검정.
  final Color? glyphColor;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final double radius = size * 0.3;
    if (!framed) return _bareGlyph();
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
      case 'notion':
        // 단색 N 글리프(currentColor) → 흰 배경 + 검정 글리프(브랜드 기본).
        return _framed(
          bg: const Color(0xFFFFFFFF),
          border: t.border,
          radius: radius,
          child: SvgPicture.asset(
            'assets/provider/notion.svg',
            width: size * 0.6,
            height: size * 0.6,
            colorFilter: const ColorFilter.mode(
              Color(0xFF000000),
              BlendMode.srcIn,
            ),
          ),
        );
      case 'ieoseo':
        // 이어서 앱 출처: 런처 아이콘 마스터(브랜드 로고)를 둥근 사각으로 클립.
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.asset(
            'assets/icon/ieoseo-icon-1024.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      default:
        return SizedBox(width: size, height: size);
    }
  }

  /// 박스 없이 글리프만(로그인 버튼용). 버튼 배경이 이미 있으므로 박스/테두리를 두지 않는다.
  Widget _bareGlyph() {
    final Color tint = glyphColor ?? const Color(0xFF000000);
    switch (brand) {
      case 'google':
        // 멀티컬러 → 틴트 없이 원본 G.
        return SvgPicture.asset(
          'assets/provider/google.svg',
          width: size,
          height: size,
        );
      case 'apple':
        return SvgPicture.asset(
          'assets/provider/apple.svg',
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
        );
      case 'kakao':
        // 노란 버튼 위 검정 말풍선(브랜드 가이드) — 박스 없는 심볼만.
        return SvgPicture.asset(
          'assets/provider/kakao_symbol.svg',
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
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
