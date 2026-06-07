import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme/tokens.dart';
import '../../widgets/dk_ring.dart';

/// 스킨 공통 프로퍼티.
class FocusSkinProps {
  const FocusSkinProps({
    required this.pct,
    required this.color,
    required this.mm,
    required this.ss,
    required this.stateText,
    required this.sub,
  });

  final double pct;
  final Color color;
  final String mm;
  final String ss;
  final String stateText;
  final String sub;
}

/// 스킨: 링. 글로우 + Ring 264/stroke 16 + 중앙 readout.
class SkinRing extends StatelessWidget {
  const SkinRing({super.key, required this.props});
  final FocusSkinProps props;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return SizedBox(
      width: 264,
      height: 264,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              color: props.color.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
          ),
          DkRing(
            size: 264,
            stroke: 16,
            pct: props.pct,
            color: props.color,
            track: t.bgPress,
            child: _Readout(props: props, stateColor: props.color),
          ),
        ],
      ),
    );
  }
}

/// 스킨: 미니멀. 큰 mm:ss + 얇은 진행바.
class SkinMinimal extends StatelessWidget {
  const SkinMinimal({super.key, required this.props});
  final FocusSkinProps props;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 264),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            props.stateText,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.56,
              color: props.color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${props.mm}:${props.ss}',
            style: TextStyle(
              fontFamily: 'WantedSans',
              fontSize: 104,
              fontWeight: FontWeight.w800,
              letterSpacing: -5.2,
              height: 0.95,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              color: t.fgStrong,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            props.sub,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: t.fgSubtle,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              width: 220,
              height: 5,
              child: Stack(
                children: <Widget>[
                  Container(color: t.bgPress),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: props.pct / 100),
                    duration: const Duration(milliseconds: 600),
                    curve: const Cubic(0.4, 0, 0.2, 1),
                    builder: (BuildContext context, double v, _) =>
                        FractionallySizedBox(
                          widthFactor: v.clamp(0, 1),
                          child: Container(color: props.color),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 스킨: 리퀴드. 원 안에 아래에서 차오르는 물 + 물결.
class SkinLiquid extends StatefulWidget {
  const SkinLiquid({super.key, required this.props});
  final FocusSkinProps props;

  @override
  State<SkinLiquid> createState() => _SkinLiquidState();
}

class _SkinLiquidState extends State<SkinLiquid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final FocusSkinProps p = widget.props;
    return SizedBox(
      width: 264,
      height: 264,
      child: ClipOval(
        child: Stack(
          children: <Widget>[
            Container(color: Color.lerp(p.color, t.bg, 0.91)),
            AnimatedBuilder(
              animation: _wave,
              builder: (BuildContext context, _) => CustomPaint(
                size: const Size(264, 264),
                painter: _LiquidPainter(
                  pct: p.pct / 100,
                  color: p.color,
                  phase: _wave.value,
                ),
              ),
            ),
            Center(
              child: _Readout(props: p, stateColor: t.fgStrong),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  _LiquidPainter({required this.pct, required this.color, required this.phase});

  final double pct;
  final Color color;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final double level = size.height * (1 - pct.clamp(0, 1));
    final Paint paint = Paint()..color = color;
    final Path path = Path()..moveTo(0, size.height);
    const double amp = 8;
    final double shift = phase * size.width;
    path.lineTo(0, level);
    for (double x = 0; x <= size.width; x += 4) {
      final double y =
          level + amp * math.sin((x + shift) / size.width * 2 * math.pi * 2);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LiquidPainter old) =>
      old.pct != pct || old.color != color || old.phase != phase;
}

/// 스킨: 플립. 플립 디지트 카드 4개 + ":" 구분.
class SkinFlip extends StatelessWidget {
  const SkinFlip({super.key, required this.props});
  final FocusSkinProps props;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return SizedBox(
      height: 264,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            props.stateText,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.56,
              color: props.color,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _FlipDigit(d: props.mm[0], color: props.color),
              const SizedBox(width: 6),
              _FlipDigit(d: props.mm[1], color: props.color),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontFamily: 'WantedSans',
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: t.fgDisabled,
                  ),
                ),
              ),
              _FlipDigit(d: props.ss[0], color: props.color),
              const SizedBox(width: 6),
              _FlipDigit(d: props.ss[1], color: props.color),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            props.sub,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: t.fgSubtle,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlipDigit extends StatelessWidget {
  const _FlipDigit({required this.d, required this.color});
  final String d;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 56,
        height: 78,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.fgStrong,
          borderRadius: BorderRadius.circular(14),
          boxShadow: t.shadows.s2,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // flipIn: 새 숫자가 위에서 떨어지는 느낌.
            TweenAnimationBuilder<double>(
              key: ValueKey<String>(d),
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: const Cubic(0.4, 0, 0.2, 1),
              builder: (BuildContext context, double v, Widget? child) =>
                  Opacity(
                    opacity: v,
                    child: Transform.translate(
                      offset: Offset(0, (1 - v) * -8),
                      child: child,
                    ),
                  ),
              child: Text(
                d,
                style: const TextStyle(
                  fontFamily: 'WantedSans',
                  fontSize: 50,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
            // 중앙 분할선.
            Positioned(
              left: 0,
              right: 0,
              child: Container(height: 1, color: const Color(0x59000000)),
            ),
            // 하단 모드색 바.
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(height: 3, color: color.withValues(alpha: 0.9)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 중앙 readout(상태/시간/sub). 링·리퀴드 공용.
class _Readout extends StatelessWidget {
  const _Readout({required this.props, required this.stateColor});
  final FocusSkinProps props;
  final Color stateColor;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          props.stateText,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.27,
            color: stateColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${props.mm}:${props.ss}',
          style: TextStyle(
            fontFamily: 'WantedSans',
            fontSize: 60,
            fontWeight: FontWeight.w800,
            letterSpacing: -2.4,
            height: 1,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            color: t.fgStrong,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          props.sub,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: t.fgSubtle,
          ),
        ),
      ],
    );
  }
}
