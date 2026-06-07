import 'dart:async';

import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../widgets/dk_logo.dart';

/// 스플래시. 프로토타입 `Splash`.
///
/// bg 배경 중앙. 로고 56(pop 스프링) + 부제(fade). 3초 후 [onDone].
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// 3초 후 [onDone] 타이머. dispose(인증 복원으로 스플래시 조기 종료) 시 취소해
  /// 타이머 누수를 막는다(취소 불가능한 Future.delayed 사용 금지).
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return Container(
      color: t.bg,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: const Cubic(0.34, 1.4, 0.64, 1),
            builder: (BuildContext context, double v, Widget? child) =>
                Transform.scale(scale: v, child: child),
            child: const DkLogo(size: 56),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            builder: (BuildContext context, double v, Widget? child) =>
                Opacity(opacity: v.clamp(0, 1), child: child),
            child: Text(
              'D-Day · 할 일 · 집중을 하나로',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: t.fgSubtle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
