import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import 'dk_button.dart';
import 'dk_icon.dart';

/// 빈 상태. 프로토타입 `Empty`.
///
/// 중앙 정렬. 아이콘 칩 64 radius 22(primary-subtle/primary), 제목 17/700,
/// 본문 14/fg-subtle(maxWidth 260), 선택 CTA 버튼.
class DkEmpty extends StatelessWidget {
  const DkEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.cta,
    this.onCta,
  });

  final String icon;
  final String title;
  final String body;
  final String? cta;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: t.primarySubtle,
              borderRadius: BorderRadius.circular(22),
            ),
            child: DkIcon(icon, size: 30, color: t.primary),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.34,
              color: t.fg,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                height: 1.5,
                color: t.fgSubtle,
              ),
            ),
          ),
          if (cta != null) ...<Widget>[
            const SizedBox(height: 14),
            DkButton(
              onPressed: onCta,
              leading: const DkIcon(
                'plus',
                size: 18,
                color: Color(0xFFFFFFFF),
                strokeWidth: 2.2,
              ),
              child: Text(cta!),
            ),
          ],
        ],
      ),
    );
  }
}
