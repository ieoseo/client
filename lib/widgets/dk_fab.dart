import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import 'dk_icon.dart';

/// 플로팅 추가 버튼. 프로토타입 `Fab`.
///
/// 58×58, radius 20, primary 배경, plus 아이콘 28. primary 45% 그림자.
/// 배치(right 18 / bottom 92)는 호출부(Stack)에서 Positioned로 지정한다.
class DkFab extends StatefulWidget {
  const DkFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<DkFab> createState() => _DkFabState();
}

class _DkFabState extends State<DkFab> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 160),
        child: Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: t.primary.withValues(alpha: 0.45),
                offset: const Offset(0, 8),
                blurRadius: 24,
              ),
            ],
          ),
          child: const DkIcon(
            'plus',
            size: 28,
            color: Color(0xFFFFFFFF),
            strokeWidth: 2.4,
          ),
        ),
      ),
    );
  }
}
