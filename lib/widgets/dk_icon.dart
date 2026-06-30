import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ieoseo/theme/seed_icons.dart';

/// 디자인 시스템 아이콘 path 맵. seed-design 단일 소스 [kSeedIcons]
/// (`theme/seed_icons.dart`, vendored)를 그대로 쓴다. 각 값은 SVG `path` `d`
/// 문자열(여러 서브패스가 ` M`으로 이어짐).
const Map<String, String> kDkIcons = kSeedIcons;

/// 단일 path `d` 문자열을 서브패스 단위로 쪼갠다.
///
/// Lucide 아이콘은 여러 `<path>`(각 스트로크)를 한 문자열로 평탄화해 두는데, 서브패스 시작은
/// 대문자 `M`(절대)뿐 아니라 소문자 `m`(상대)일 수도 있다(예: `languages`=어학). 둘 다 경계로
/// 쪼개 각자 `<path>` 로 렌더한다 — 소문자 `m` 으로 시작하는 서브패스는 SVG 규약상 첫 moveto 가
/// 절대로 취급돼 좌표가 맞는다. (대문자만 쪼개면 상대 `m` 서브패스가 앞 패스에 붙어 깨졌다.)
List<String> _splitSubpaths(String d) => d.split(RegExp(r' (?=[Mm])'));

/// 24-grid 둘레에 둘 여백(단위). 가장자리에 닿는 path(예: 캘린더 상단 고리 y=2,
/// sun 광선 등)는 굵은 stroke(활성 2.3)+round cap 이 viewBox 밖으로 삐져나가는데,
/// flutter_svg 는 viewBox 로 잘라내 아이콘이 잘려 보인다. viewBox 를 이만큼 넓혀 막는다.
const double _kIconViewBoxPad = 2;

/// 색·두께·채움을 받아 stroke 아이콘 SVG 문자열을 만든다.
///
/// viewBox 는 `0 0 24 24` 가 아니라 [_kIconViewBoxPad] 만큼 사방으로 넓힌다 →
/// 가장자리 stroke 가 잘리지 않는다(원본 아이콘 그대로 유지). 콘텐츠 크기 보정은
/// [DkIcon.build] 가 그린 크기를 키워 맞춘다.
String _buildSvg(String d, Color color, double strokeWidth, Color? fill) {
  final String stroke = _hex(color);
  final String fillAttr = fill == null ? 'none' : _hex(fill);
  final StringBuffer paths = StringBuffer();
  for (final String p in _splitSubpaths(d)) {
    paths.write('<path d="$p"/>');
  }
  const double min = -_kIconViewBoxPad;
  const double span = 24 + 2 * _kIconViewBoxPad;
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="$min $min $span $span" '
      'fill="$fillAttr" stroke="$stroke" stroke-width="$strokeWidth" '
      'stroke-linecap="round" stroke-linejoin="round">$paths</svg>';
}

String _hex(Color c) {
  final int argb = c.toARGB32();
  final String rgb = (argb & 0xFFFFFF)
      .toRadixString(16)
      .padLeft(6, '0')
      .toUpperCase();
  return '#$rgb';
}

/// 디자인 시스템 아이콘. flutter_svg로 [kDkIcons]의 path를 렌더한다.
///
/// 프로토타입 `Ic`에 대응: 기본 size 22, stroke 1.9, round cap/join, fill none.
class DkIcon extends StatelessWidget {
  const DkIcon(
    this.name, {
    super.key,
    this.size = 22,
    this.color = const Color(0xFF1A1B1E),
    this.strokeWidth = 1.9,
    this.fill,
  });

  /// [kDkIcons]의 키.
  final String name;
  final double size;
  final Color color;
  final double strokeWidth;

  /// 채움 색. null이면 외곽선만.
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final String? d = kDkIcons[name];
    if (d == null) return SizedBox(width: size, height: size);
    // viewBox 를 _kIconViewBoxPad 만큼 넓혔으므로, 24-grid 콘텐츠가 정확히 [size] 로
    // 보이도록 그린 그림은 그만큼 크게 그린다. 레이아웃 박스는 [size] 로 유지하고,
    // 투명 여백은 OverflowBox 로 밖으로 흘려보낸다(가시 콘텐츠는 항상 size 안 → 잘림 없음).
    final double drawn = size * (24 + 2 * _kIconViewBoxPad) / 24;
    return SizedBox(
      width: size,
      height: size,
      child: OverflowBox(
        minWidth: 0,
        minHeight: 0,
        maxWidth: drawn,
        maxHeight: drawn,
        child: SvgPicture.string(
          _buildSvg(d, color, strokeWidth, fill),
          width: drawn,
          height: drawn,
        ),
      ),
    );
  }
}
