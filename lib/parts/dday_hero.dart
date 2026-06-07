import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../data/dday.dart';
import '../data/format.dart';
import '../data/models.dart';
import '../theme/tokens.dart';
import '../widgets/dk_badge.dart';
import '../widgets/dk_icon.dart';

/// D-Day 히어로 카드. 프로토타입 `DdayHero`.
///
/// fg-strong 배경/흰 글자, radius-lg, shadow-2. 우상단 hue 글로우 원(blur).
/// 상단: 고정 칩 + 카테고리 + (urgency high면) "마감 임박" 솔리드 뱃지.
/// 하단: 제목·날짜 + 큰 D-라벨(brand 52/800).
class DdayHero extends StatelessWidget {
  const DdayHero({super.key, required this.event, this.onOpen});

  final DkEvent event;
  final ValueChanged<DkEvent>? onOpen;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final DkDdayInfo info = ddayInfo(event);
    final DkHue h = DkHue.byName(event.color);
    final bool urgent = info.urgency == DkUrgency.high;
    const Color white = Color(0xFFFFFFFF);

    return GestureDetector(
      onTap: onOpen == null ? null : () => onOpen!(event),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(t.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            color: t.fgStrong,
            borderRadius: BorderRadius.circular(t.radiusLg),
            boxShadow: t.shadows.s2,
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: -60,
                right: -40,
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: h.color.withValues(alpha: 0.34),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        if (event.pinned) ...<Widget>[
                          _pill(white),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          event.category,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xB3FFFFFF),
                          ),
                        ),
                        if (urgent) ...<Widget>[
                          const SizedBox(width: 8),
                          const DkBadge(
                            '마감 임박',
                            tone: DkTone.danger,
                            solid: true,
                            leading: DkIcon(
                              'flame',
                              size: 12,
                              color: white,
                              strokeWidth: 2,
                              fill: white,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                event.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xE0FFFFFF),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                eventDateLabel(event),
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 13,
                                  color: Color(0x99FFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          info.type == DkEventType.progress
                              ? '${info.pct}%'
                              : info.label,
                          style: const TextStyle(
                            fontFamily: 'WantedSans',
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2.08,
                            height: 0.9,
                            color: white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(Color white) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x24FFFFFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DkIcon('pin', size: 13, color: white, strokeWidth: 2),
          const SizedBox(width: 4),
          const Text(
            '고정됨',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xD1FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}
