import 'package:flutter/material.dart' show showModalBottomSheet;
import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import 'dk_icon.dart';

/// 바텀시트. 프로토타입 `Sheet`.
///
/// 오버레이(fade) + 하단 패널(slideUp 320ms). 상단 radius 28, grab handle 40×5,
/// title 19/700 + 닫기 버튼(34 원형 bg-press). maxHeight 86%(full 94%).
/// [showDkSheet]로 호출한다.
class DkSheet extends StatelessWidget {
  const DkSheet({
    super.key,
    required this.child,
    this.title,
    this.full = false,
  });

  final Widget child;
  final String? title;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final double maxHeightFactor = full ? 0.94 : 0.86;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: t.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: t.borderStrong,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          title!,
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.38,
                            color: t.fgStrong,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: t.bgPress,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: DkIcon('x', size: 20, color: t.fgMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [DkSheet]를 표준 모션(slideUp 320ms, overlay fade)으로 띄운다.
Future<T?> showDkSheet<T>(
  BuildContext context, {
  required Widget child,
  String? title,
  bool full = false,
}) {
  final DkTokens t = DkTheme.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0x00000000),
    barrierColor: t.overlay,
    // 모달 라우트는 루트 오버레이에 붙어 호출부의 DkTheme 를 상속하지 못한다.
    // 호출부 토큰을 다시 제공해 시트 내부에서도 DkTheme.of 가 동작하게 한다.
    builder: (BuildContext context) => DkTheme(
      tokens: t,
      child: DkSheet(title: title, full: full, child: child),
    ),
  );
}
