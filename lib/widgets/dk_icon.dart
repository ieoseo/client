import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Lucide 스타일 24-grid 아이콘 path 맵. 프로토타입 `DK_ICONS`를 그대로 이식.
/// 각 값은 SVG `path` `d` 문자열(여러 서브패스가 ` M`으로 이어짐).
const Map<String, String> kDkIcons = <String, String>{
  'home': 'M3 10.5 12 3l9 7.5 M5 9.5V21h14V9.5 M9.5 21v-6h5v6',
  'calendar':
      'M3 9h18 M7 3v3 M17 3v3 M5 5h14a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1Z',
  // 미룬 시간/하루 최대 예약: 달력 + 앞으로 향하는 화살표(못 한 일을 다음 날로 이월).
  'carryForward':
      'M21 11V6a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2h6 '
      'M3 9h18 M8 2v4 M16 2v4 M14 18h6 M20 18l-2.5-2.5 M20 18l-2.5 2.5',
  'tasks': 'M4 6h2v2H4z M4 11h2v2H4z M4 16h2v2H4z M9 7h11 M9 12h11 M9 17h11',
  'focus': 'M12 22a9 9 0 1 0 0-18 9 9 0 0 0 0 18Z M12 8v4l3 2 M9 2h6',
  'settings':
      'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z M19.4 13.5a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-2.7 1.1V21a2 2 0 1 1-4 0v-.1a1.6 1.6 0 0 0-2.7-1.1l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.6 1.6 0 0 0-1.1-2.7H3a2 2 0 1 1 0-4h.1a1.6 1.6 0 0 0 1.1-2.7l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.6 1.6 0 0 0 2.7-1.1V3a2 2 0 1 1 4 0v.1a1.6 1.6 0 0 0 2.7 1.1l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.6 1.6 0 0 0-.3 1.8Z',
  'bell':
      'M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9 M10.3 21a1.94 1.94 0 0 0 3.4 0',
  'plus': 'M12 5v14 M5 12h14',
  'check': 'M20 6 9 17l-5-5',
  'chevR': 'M9 6l6 6-6 6',
  'chevL': 'M15 6l-6 6 6 6',
  'chevD': 'M6 9l6 6 6-6',
  'clock': 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20Z M12 6v6l4 2',
  'flame':
      'M12 2c1 4 5 5 5 9a5 5 0 0 1-10 0c0-2 1-3 1-3 .5 2 2 2 2 2 .5-3-.5-6 2-8Z',
  'arrowR': 'M5 12h14 M13 6l6 6-6 6',
  'more': 'M6 12h.01 M12 12h.01 M18 12h.01',
  'pin': 'M12 17v5 M9 3h6l-1 7 3 3H7l3-3-1-7Z',
  'play': 'M7 4v16l13-8z',
  'pause': 'M8 5h3v14H8z M14 5h3v14h-3z',
  'reset': 'M3 12a9 9 0 1 0 3-6.7L3 8 M3 3v5h5',
  'x': 'M18 6 6 18 M6 6l12 12',
  'coffee':
      'M4 8h13v5a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5V8Z M17 9h2a2 2 0 0 1 0 5h-2 M7 3v2 M11 3v2',
  'target':
      'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20Z M12 18a6 6 0 1 0 0-12 6 6 0 0 0 0 12Z M12 14a2 2 0 1 0 0-4 2 2 0 0 0 0 4Z',
  'repeat':
      'M17 2l4 4-4 4 M3 11V9a4 4 0 0 1 4-4h14 M7 22l-4-4 4-4 M21 13v2a4 4 0 0 1-4 4H3',
  'trash':
      'M3 6h18 M8 6V4a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2 M19 6l-1 14a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1L5 6 M10 11v6 M14 11v6',
  'edit': 'M12 20h9 M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4 12.5-12.5Z',
  'skip': 'M5 4l10 8-10 8z M19 5v14',
  'sliders':
      'M4 21v-7 M4 10V3 M12 21v-9 M12 8V3 M20 21v-5 M20 12V3 M2 14h4 M10 8h4 M18 16h4',
  'moon': 'M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8Z',
  'sun':
      'M12 17a5 5 0 1 0 0-10 5 5 0 0 0 0 10Z M12 1v2 M12 21v2 M4.2 4.2l1.4 1.4 M18.4 18.4l1.4 1.4 M1 12h2 M21 12h2 M4.2 19.8l1.4-1.4 M18.4 5.6l1.4-1.4',
  'mail':
      'M3 5h18a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1Z M3 6l9 7 9-7',
  'lock':
      'M5 11h14a1 1 0 0 1 1 1v8a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-8a1 1 0 0 1 1-1Z M8 11V7a4 4 0 0 1 8 0v4',
  'user':
      'M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2 M12 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8Z',
  'trophy':
      'M6 9H4.5a2.5 2.5 0 0 1 0-5H6 M18 9h1.5a2.5 2.5 0 0 0 0-5H18 M6 4h12v5a6 6 0 0 1-12 0V4Z M9 18h6 M10 18v-3 M14 18v-3 M8 21h8',
  'hourglass': 'M6 3h12 M6 21h12 M8 3c0 4 8 5 8 9s-8 5-8 9 M16 3c0 4-8 5-8 9',
  'alert':
      'M12 9v4 M12 17h.01 M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0Z',
  'chart': 'M3 3v18h18 M7 14l3-3 3 3 4-5',
  'sparkle': 'M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8Z',
  'link':
      'M9 15l6-6 M11 6l1-1a4 4 0 0 1 6 6l-1 1 M13 18l-1 1a4 4 0 0 1-6-6l1-1',
  'sync':
      'M21 2v6h-6 M3 12a9 9 0 0 1 15-6.7L21 8 M3 22v-6h6 M21 12a9 9 0 0 1-15 6.7L3 16',
  'list': 'M8 6h13 M8 12h13 M8 18h13 M3 6h.01 M3 12h.01 M3 18h.01',
  'flag': 'M4 21V4a1 1 0 0 1 1-1h12l-2 4 2 4H5',
  'pieView': 'M8 2v20 M2 8h20',
  'search': 'M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14Z M21 21l-4.3-4.3',
  'logout': 'M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4 M16 17l5-5-5-5 M21 12H9',
  'calc':
      'M6 2h12a1 1 0 0 1 1 1v18a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1Z M8 6h8v3H8z M8 13h.01 M12 13h.01 M16 13h.01 M8 17h.01 M12 17h.01 M16 17h.01',
  'backspace':
      'M21 5H8.5a1 1 0 0 0-.8.4L3 12l4.7 6.6a1 1 0 0 0 .8.4H21a1 1 0 0 0 1-1V6a1 1 0 0 0-1-1Z M17 9l-5 6 M12 9l5 6',
  // 미룬 시간(이월) — 달력 + 앞으로 향하는 화살표. path 는 사양 그대로(임의 변형 금지).
  // 강조색 #B86200, 배경 칩 rgba(255,146,0,0.12) 와 함께 쓴다.
  'deferred':
      'M21 11V6a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2h6 M3 9h18 M8 2v4 M16 2v4 M14 18h6 M20 18l-2.5-2.5 M20 18l-2.5 2.5',
};

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
