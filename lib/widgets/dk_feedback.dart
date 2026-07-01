import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import 'dk_badge.dart';
import 'dk_icon.dart';

/// 토스트 한 건. 프로토타입 `showToast` payload.
class DkToastData {
  const DkToastData(this.message, {this.icon, this.tone});
  final String message;
  final String? icon;
  final DkTone? tone;
}

/// 화면 하단에 토스트를 쌓아 보여주는 호스트. 프로토타입 `ToastHost`.
///
/// 하단 104, ink 배경/onInk 글자(다크에서 뒤집히지 않음), 14/600, 2.4초 후 소멸, 최대 3개.
/// 표시는 [DkToastHostState.show]로 트리거(상위 위젯이 GlobalKey로 접근).
class DkToastHost extends StatefulWidget {
  const DkToastHost({super.key});

  @override
  State<DkToastHost> createState() => DkToastHostState();
}

class DkToastHostState extends State<DkToastHost> {
  final List<_ActiveToast> _items = <_ActiveToast>[];
  int _seq = 0;

  void show(DkToastData data) {
    final int id = _seq++;
    setState(() {
      _items.add(_ActiveToast(id, data));
      if (_items.length > 3) _items.removeAt(0);
    });
    Future<void>.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() => _items.removeWhere((_ActiveToast x) => x.id == id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    if (_items.isEmpty) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 104,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final _ActiveToast it in _items)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: _Toast(data: it.data, tokens: t),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActiveToast {
  _ActiveToast(this.id, this.data);
  final int id;
  final DkToastData data;
}

class _Toast extends StatelessWidget {
  const _Toast({required this.data, required this.tokens});
  final DkToastData data;
  final DkTokens tokens;

  Color _toneColor() {
    switch (data.tone) {
      case DkTone.success:
        return tokens.success;
      case DkTone.warning:
        return tokens.warning;
      case DkTone.danger:
        return tokens.danger;
      case DkTone.info:
        return tokens.info;
      case DkTone.primary:
        return tokens.primary;
      default:
        // ink 표면 위 기본 아이콘 — 양 테마 모두 밝은 onInk(흰색 하드코딩 아님).
        return tokens.onInk;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: const Cubic(0.34, 1.3, 0.64, 1),
      builder: (BuildContext context, double v, Widget? child) {
        return Opacity(
          opacity: v.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 12),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          // ink 표면(양 테마 모두 어두움) — fgStrong 은 다크에서 흰색으로 뒤집혀
          // 흰 알약+흰 글자가 되므로 쓰지 않는다.
          color: tokens.ink,
          borderRadius: BorderRadius.circular(14),
          boxShadow: tokens.shadows.s3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (data.icon != null) ...<Widget>[
              DkIcon(
                data.icon!,
                size: 18,
                color: _toneColor(),
                strokeWidth: 2.4,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              data.message,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.14,
                color: tokens.onInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 0→값 카운트업. 프로토타입 `CountUp`: 700ms ease-out-cubic.
class DkCountUp extends StatelessWidget {
  const DkCountUp({
    super.key,
    required this.value,
    this.decimals = 0,
    this.duration = const Duration(milliseconds: 700),
    this.prefix = '',
    this.suffix = '',
    this.style,
  });

  final double value;
  final int decimals;
  final Duration duration;
  final String prefix;
  final String suffix;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double v, _) {
        return Text(
          '$prefix${v.toStringAsFixed(decimals)}$suffix',
          style: style,
        );
      },
    );
  }
}

/// 스켈레톤 placeholder. 프로토타입 `Skeleton`: shimmer 그라데이션(bg-press 기반).
class DkSkeleton extends StatefulWidget {
  const DkSkeleton({
    super.key,
    this.height = 16,
    this.width = double.infinity,
    this.radius = 10,
  });

  final double height;
  final double width;
  final double radius;

  @override
  State<DkSkeleton> createState() => _DkSkeletonState();
}

class _DkSkeletonState extends State<DkSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, _) {
        final double x = _c.value * 2 - 1; // -1 → 1
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(x - 1, 0),
              end: Alignment(x + 1, 0),
              colors: <Color>[t.bgPress, t.bgSubtle, t.bgPress],
            ),
          ),
        );
      },
    );
  }
}
