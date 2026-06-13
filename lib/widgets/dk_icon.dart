import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ieoseo/theme/seed_icons.dart';

/// 디자인 시스템 아이콘 path 맵. seed-design 단일 소스 [kSeedIcons]
/// (`theme/seed_icons.dart`, vendored)를 그대로 쓴다. 각 값은 SVG `path` `d`
/// 문자열(여러 서브패스가 ` M`으로 이어짐).
const Map<String, String> kDkIcons = kSeedIcons;

/// 단일 path `d` 문자열을 서브패스 단위로 쪼갠다(프로토타입 `d.split(" M")` 대응).
List<String> _splitSubpaths(String d) {
  final List<String> raw = d.split(' M');
  return <String>[
    for (int i = 0; i < raw.length; i++) i == 0 ? raw[i] : 'M${raw[i]}',
  ];
}

/// 색·두께·채움을 받아 stroke 아이콘 SVG 문자열을 만든다.
String _buildSvg(String d, Color color, double strokeWidth, Color? fill) {
  final String stroke = _hex(color);
  final String fillAttr = fill == null ? 'none' : _hex(fill);
  final StringBuffer paths = StringBuffer();
  for (final String p in _splitSubpaths(d)) {
    paths.write('<path d="$p"/>');
  }
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
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
    return SvgPicture.string(
      _buildSvg(d, color, strokeWidth, fill),
      width: size,
      height: size,
    );
  }
}
