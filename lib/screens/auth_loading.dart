import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../widgets/dk_logo.dart';

/// 로그인(외부 OAuth 복귀 → server provisioning) 중 표시하는 **브랜드 로딩 화면**.
///
/// 스플래시와 톤을 맞춰(중앙 로고 + 안내 문구) "쌩 화면" 대신 일관된 진입 경험을 준다.
/// 로고에 잔잔한 펄스(opacity)로 진행 중임을 알린다 — compositor 친화 속성만 애니메이트.
class AuthLoadingView extends StatefulWidget {
  const AuthLoadingView({super.key, this.message = '로그인 중…'});

  /// 가운데 안내 문구.
  final String message;

  @override
  State<AuthLoadingView> createState() => _AuthLoadingViewState();
}

class _AuthLoadingViewState extends State<AuthLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
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
          FadeTransition(
            // 0.45 ↔ 1.0 잔잔한 펄스(스플래시 등장 이후의 "처리 중" 느낌).
            opacity: Tween<double>(
              begin: 0.45,
              end: 1,
            ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
            child: const DkLogo(size: 48),
          ),
          const SizedBox(height: 18),
          Text(
            widget.message,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: t.fgSubtle,
            ),
          ),
        ],
      ),
    );
  }
}
