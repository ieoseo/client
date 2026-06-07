import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// 진행 링. 프로토타입 `Ring`(SVG)을 CustomPaint로 이식.
///
/// track 원 + 진행 원(round cap), -90°에서 시작. 채움은 600ms 표준 이징으로
/// 애니메이션. 중앙에 [child]를 겹쳐 그린다.
class DkRing extends StatelessWidget {
  const DkRing({
    super.key,
    this.size = 220,
    this.stroke = 14,
    this.pct = 0,
    this.color,
    this.track,
    this.rounded = true,
    this.child,
  });

  final double size;
  final double stroke;

  /// 진행률 0~100.
  final double pct;
  final Color? color;
  final Color? track;
  final bool rounded;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final double clamped = pct.clamp(0, 100) / 100;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: clamped),
            duration: const Duration(milliseconds: 600),
            curve: const Cubic(0.4, 0, 0.2, 1),
            builder: (BuildContext context, double value, _) {
              return CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  stroke: stroke,
                  pct: value,
                  color: color ?? t.primary,
                  track: track ?? t.bgPress,
                  rounded: rounded,
                ),
              );
            },
          ),
          ?child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.stroke,
    required this.pct,
    required this.color,
    required this.track,
    required this.rounded,
  });

  final double stroke;
  final double pct;
  final Color color;
  final Color track;
  final bool rounded;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - stroke) / 2;

    final Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    if (pct <= 0) return;

    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = rounded ? StrokeCap.round : StrokeCap.butt
      ..color = color;

    const double start = -math.pi / 2;
    final double sweep = 2 * math.pi * pct;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.pct != pct ||
      old.color != color ||
      old.track != track ||
      old.stroke != stroke ||
      old.rounded != rounded;
}
