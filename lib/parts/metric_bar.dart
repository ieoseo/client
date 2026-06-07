import 'package:flutter/widgets.dart';

import '../data/models.dart';
import '../theme/tokens.dart';
import '../widgets/dk_card.dart';
import '../widgets/dk_feedback.dart';

/// 주간 지표 막대. 프로토타입 `MetricBar`.
///
/// Card. 3지표(계획/완료/밀린 시간) CountUp brand 25/800 + "시간".
/// 하단 진행바 10 radius 99(완료 % success 채움) + 안내문.
class MetricBar extends StatelessWidget {
  const MetricBar({super.key, required this.summary});

  final DkWeekSummary summary;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final int donePct = summary.planned == 0
        ? 0
        : (summary.done / summary.planned * 100).round();

    return DkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _metric(
                t,
                '계획',
                summary.planned,
                t.fgStrong,
                Alignment.centerLeft,
              ),
              _metric(t, '완료', summary.done, t.success, Alignment.center),
              _metric(
                t,
                '밀린 시간',
                summary.debt,
                t.warningFg,
                Alignment.centerRight,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Stack(
              children: <Widget>[
                Container(height: 10, color: t.bgPress),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints c) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: donePct / 100),
                      duration: const Duration(milliseconds: 600),
                      curve: const Cubic(0.4, 0, 0.2, 1),
                      builder: (BuildContext context, double v, _) => Container(
                        height: 10,
                        width: c.maxWidth * v,
                        decoration: BoxDecoration(
                          color: t.success,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: t.fgSubtle,
              ),
              children: <InlineSpan>[
                const TextSpan(text: '이번 주 '),
                TextSpan(
                  text: '$donePct%',
                  style: TextStyle(
                    color: t.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' 완료 · 밀린 일은 주말로 옮겨드릴게요'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(
    DkTokens t,
    String label,
    double value,
    Color color,
    Alignment align,
  ) {
    final bool isInt = value == value.roundToDouble();
    final MainAxisAlignment rowAlign = align == Alignment.center
        ? MainAxisAlignment.center
        : align == Alignment.centerRight
        ? MainAxisAlignment.end
        : MainAxisAlignment.start;
    final CrossAxisAlignment colAlign = align == Alignment.center
        ? CrossAxisAlignment.center
        : align == Alignment.centerRight
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    return Expanded(
      child: Column(
        crossAxisAlignment: colAlign,
        children: <Widget>[
          Row(
            mainAxisAlignment: rowAlign,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              DkCountUp(
                value: value,
                decimals: isInt ? 0 : 1,
                style: TextStyle(
                  fontFamily: 'WantedSans',
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.75,
                  color: color,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                '시간',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.fgSubtle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: t.fgSubtle,
            ),
          ),
        ],
      ),
    );
  }
}
