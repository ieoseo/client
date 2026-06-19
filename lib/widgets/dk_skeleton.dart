import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// 스켈레톤 로딩 묶음의 shimmer 소스(토스·당근 패턴). 한 컨트롤러로 하위 [DkSkeleton]들을
/// **동기 sweep** 시킨다(블록마다 컨트롤러를 두지 않아 가볍다). reduced-motion 이면 정적.
class DkSkeletonScope extends StatefulWidget {
  const DkSkeletonScope({super.key, required this.child});

  final Widget child;

  /// 상위 scope 의 shimmer 애니메이션(없으면 null → 정적).
  static Animation<double>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonScope>()?.shimmer;

  @override
  State<DkSkeletonScope> createState() => _DkSkeletonScopeState();
}

class _DkSkeletonScopeState extends State<DkSkeletonScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _SkeletonScope(shimmer: _controller, child: widget.child);
}

class _SkeletonScope extends InheritedWidget {
  const _SkeletonScope({required this.shimmer, required super.child});

  final Animation<double> shimmer;

  // 컨트롤러 객체는 안정적이라 매 프레임 알림이 필요 없다(각 DkSkeleton 이 AnimatedBuilder 로 구독).
  @override
  bool updateShouldNotify(_SkeletonScope oldWidget) => false;
}

/// shimmer 그라데이션을 가로로 흘려보내는 변환(좌→우 sweep).
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.fraction);

  /// -1(왼쪽 밖) ~ 1(오른쪽 밖) 범위로 이동.
  final double fraction;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * fraction, 0, 0);
}

/// 스켈레톤 블록 한 개(회색 플레이스홀더 + 좌→우 shimmer 하이라이트).
///
/// 최종 콘텐츠와 같은 크기·radius 로 두어 레이아웃 시프트가 없게 한다(NN/g·토스 가이드).
/// reduced-motion 또는 scope 부재 시 정적 회색으로 폴백한다.
class DkSkeleton extends StatelessWidget {
  const DkSkeleton({super.key, this.width, this.height = 16, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final Color base = t.bgPress; // 회색 베이스(라이트/다크 토큰 적응)
    final Widget box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    final Animation<double>? shimmer = DkSkeletonScope.of(context);
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (shimmer == null || reduceMotion) return box;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AnimatedBuilder(
        animation: shimmer,
        builder: (BuildContext context, _) {
          // 0..1 → -1..1 로 매핑해 하이라이트 밴드를 왼쪽 밖에서 오른쪽 밖으로 흘린다.
          final double fraction = shimmer.value * 2 - 1;
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (Rect rect) => LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[base, t.bg, base], // 좁은 밝은 밴드
              stops: const <double>[0.35, 0.5, 0.65],
              transform: _SlideGradient(fraction),
            ).createShader(rect),
            child: box,
          );
        },
      ),
    );
  }
}
