import 'package:flutter/material.dart' show showDialog;
import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import 'dk_button.dart';

/// 중앙 확인 Alert(취소/확인). 되돌리기 어려운 동작(연동 해제 등)에 명시적 확인을 받는다.
///
/// 바텀시트(DkSheet)와 달리 화면 중앙 카드로 띄운다. 확인 → true, 취소/바깥탭 → false.
/// 모달 라우트는 루트 오버레이라 호출부 [DkTheme] 를 상속하지 못하므로 토큰을 다시 제공한다.
Future<bool> showDkConfirmAlert(
  BuildContext context, {
  required String title,
  required String body,
  String confirmLabel = '확인',
  String cancelLabel = '취소',
  bool destructive = false,
}) async {
  final DkTokens t = DkTheme.of(context);
  final bool? ok = await showDialog<bool>(
    context: context,
    barrierColor: t.overlay,
    builder: (BuildContext context) => DkTheme(
      tokens: t,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              decoration: BoxDecoration(
                color: t.bg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: t.fgStrong,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      height: 1.45,
                      color: t.fgSubtle,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: DkButton(
                          size: DkButtonSize.md,
                          variant: DkButtonVariant.subtle,
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(cancelLabel),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DkButton(
                          size: DkButtonSize.md,
                          variant: destructive
                              ? DkButtonVariant.danger
                              : DkButtonVariant.primary,
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(confirmLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return ok == true;
}
