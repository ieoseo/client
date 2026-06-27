import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../data/format.dart';
import '../../data/meta.dart';
import '../../theme/tokens.dart';
import '../../widgets/dk_card.dart';
import '../../widgets/dk_feedback.dart';
import '../../widgets/dk_icon.dart';
import '../../widgets/dk_ring.dart';
import '../../widgets/dk_section.dart';

/// 주간 리뷰(회고) 서브화면. 프로토타입 `ReviewScreen`.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({
    super.key,
    required this.review,
    required this.streak,
    required this.onBack,
  });

  final DkWeekReview review;
  final int streak;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final int pct = review.planned == 0
        ? 0
        : (review.done / review.planned * 100).round();
    final double maxDay = review.byDay
        .map((DkReviewDay d) => d.planned)
        .reduce(math.max);
    final int catTotal = review.byCategory.fold(
      0,
      (int s, DkReviewCategory c) => s + c.mins,
    );
    final int doneDays = review.byDay
        .where((DkReviewDay d) => d.allDone)
        .length;

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        _header(t),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _hero(t, pct),
              const SizedBox(height: 22),
              const DkSectionHead(title: '요일별 실행'),
              _byDay(t, maxDay, doneDays),
              const SizedBox(height: 22),
              _streakCard(t),
              const SizedBox(height: 22),
              const DkSectionHead(title: '카테고리 분포'),
              _byCategory(t, catTotal),
              const SizedBox(height: 22),
              _insight(t),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(DkTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 58, 16, 8),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.bgPress,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DkIcon('chevL', size: 22, color: t.fg),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '주간 리뷰',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.66,
                  color: t.fgStrong,
                ),
              ),
              Text(
                review.range,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: t.fgSubtle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hero(DkTokens t, int pct) {
    const Color white = Color(0xFFFFFFFF);
    return ClipRRect(
      borderRadius: BorderRadius.circular(t.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: t.ink,
          borderRadius: BorderRadius.circular(t.radiusLg),
          boxShadow: t.shadows.s3,
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -80,
              right: -50,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: t.primary.withValues(alpha: 0.26),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: <Widget>[
                  DkRing(
                    size: 108,
                    stroke: 11,
                    pct: pct.toDouble(),
                    color: white,
                    track: const Color(0x29FFFFFF),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        DkCountUp(
                          value: pct.toDouble(),
                          suffix: '%',
                          style: const TextStyle(
                            fontFamily: 'WantedSans',
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.81,
                            color: white,
                          ),
                        ),
                        Text(
                          '완료율',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: t.onInkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        _heroRow(t, '계획', review.planned, t.onInk, '개'),
                        const SizedBox(height: 10),
                        _heroRow(t, '완료', review.done, white, '개'),
                        const SizedBox(height: 10),
                        _heroRow(t, '밀린 시간', review.carried, t.warningFg, '시간'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroRow(
    DkTokens t,
    String label,
    int value,
    Color color,
    String unit,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: t.onInkMuted,
          ),
        ),
        const Spacer(),
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: 'WantedSans',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            children: <InlineSpan>[
              TextSpan(text: '$value'),
              TextSpan(
                text: unit,
                style: TextStyle(fontSize: 12, color: t.onInkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _byDay(DkTokens t, double maxDay, int doneDays) {
    return DkCard(
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 132,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (final DkReviewDay d in review.byDay)
                  Expanded(child: _bar(t, d, maxDay)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.borderSubtle)),
            ),
            child: Row(
              children: <Widget>[
                _legendDot(t, t.success, '모두 달성'),
                const SizedBox(width: 14),
                _legendDot(t, t.primary, '부분 달성'),
                const Spacer(),
                Text(
                  '$doneDays/7일 완벽',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: t.fg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(DkTokens t, DkReviewDay d, double maxDay) {
    final double ratio = d.planned == 0 ? 0 : d.done / d.planned;
    final double h = maxDay <= 0
        ? 8
        : math.max(8, (d.planned / maxDay * 104).round().toDouble());
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Container(
          width: 22,
          height: h,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: t.bgPress,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: ratio.clamp(0, 1)),
            duration: const Duration(milliseconds: 600),
            curve: const Cubic(0.4, 0, 0.2, 1),
            builder: (BuildContext context, double v, _) => Container(
              width: 22,
              height: h * v,
              decoration: BoxDecoration(
                color: d.allDone ? t.success : t.primary,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          d.day,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: d.allDone ? t.successFg : t.fgSubtle,
          ),
        ),
      ],
    );
  }

  Widget _legendDot(DkTokens t, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: t.fgSubtle,
          ),
        ),
      ],
    );
  }

  Widget _streakCard(DkTokens t) {
    return DkCard(
      padding: 16,
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.warningSubtle,
              borderRadius: BorderRadius.circular(14),
            ),
            child: DkIcon(
              'flame',
              size: 24,
              color: t.warningFg,
              strokeWidth: 1.9,
              fill: t.warningFg,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: t.fg,
                    ),
                    children: <InlineSpan>[
                      const TextSpan(text: '스트릭 '),
                      TextSpan(
                        text: '$streak일',
                        style: TextStyle(color: t.warningFg),
                      ),
                      const TextSpan(text: ' 유지 중'),
                    ],
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '이번 주도 이어가면 최고 기록이에요',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: t.fgSubtle,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final DkReviewDay d in review.byDay)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: d.allDone ? t.warningFg : t.bgPress,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _byCategory(DkTokens t, int catTotal) {
    return DkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 12,
              child: Row(
                children: <Widget>[
                  for (final DkReviewCategory c in review.byCategory)
                    Expanded(
                      flex: c.mins,
                      child: Container(color: DkHue.byName(c.color).color),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final DkReviewCategory c in review.byCategory)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: DkHue.byName(c.color).color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      c.cat,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: t.fg,
                      ),
                    ),
                  ),
                  Text(
                    fmtMins(c.mins),
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: t.fgSubtle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 38,
                    child: Text(
                      '${catTotal == 0 ? 0 : (c.mins / catTotal * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: t.fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _insight(DkTokens t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: t.primarySubtle,
        borderRadius: BorderRadius.circular(t.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: DkIcon('sparkle', size: 20, color: t.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              review.insight,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13.5,
                height: 1.55,
                fontWeight: FontWeight.w600,
                color: t.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
