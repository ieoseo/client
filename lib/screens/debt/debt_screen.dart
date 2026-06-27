import 'package:flutter/widgets.dart';

import '../../data/format.dart';
import '../../data/meta.dart';
import '../../data/models.dart';
import '../../theme/tokens.dart';
import '../../widgets/dk_badge.dart';
import '../../widgets/dk_button.dart';
import '../../widgets/dk_card.dart';
import '../../widgets/dk_empty.dart';
import '../../widgets/dk_icon.dart';
import '../../widgets/dk_section.dart';

/// 미룬 시간 상세 서브화면. 프로토타입 `DebtScreen`.
///
/// 총합 히어로 + 미뤄둔 일 리스트(날짜 옮기기/내려놓기) + 규칙 안내문.
/// 옮기기·내려놓기는 화면 로컬 상태로 즉시 반영(목업).
class DebtScreen extends StatefulWidget {
  const DebtScreen({
    super.key,
    required this.debts,
    required this.onBack,
    required this.onAutoCarry,
    required this.onAbandon,
  });

  final List<DkDebt> debts;
  final VoidCallback onBack;

  /// 날짜 옮기기(자동 이월). server 가 가장 여유 있는 날을 산출해 배정한다.
  /// 실제 대상 날짜는 응답으로 상위 컨트롤러가 갱신한다(server 권위).
  final ValueChanged<DkDebt> onAutoCarry;

  /// 내려놓기(탕감).
  final ValueChanged<DkDebt> onAbandon;

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  late List<DkDebt> _items = <DkDebt>[...widget.debts];

  @override
  void didUpdateWidget(DebtScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 상위(컨트롤러) 목록이 갱신되면 로컬 표시를 동기화.
    if (!identical(oldWidget.debts, widget.debts)) {
      _items = <DkDebt>[...widget.debts];
    }
  }

  void _carry(DkDebt d) {
    // 낙관적으로 배정 상태만 표시(대상 날짜는 server 응답으로 컨트롤러가 채운다).
    setState(() {
      _items = _items
          .map(
            (DkDebt x) =>
                x.id == d.id ? x.copyWith(status: DkDebtStatus.assigned) : x,
          )
          .toList();
    });
    widget.onAutoCarry(d);
  }

  void _abandon(DkDebt d) {
    setState(() => _items = _items.where((DkDebt x) => x.id != d.id).toList());
    widget.onAbandon(d);
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final int total = _items.fold(0, (int s, DkDebt d) => s + d.mins);
    final int overdue = _items
        .where((DkDebt d) => d.status == DkDebtStatus.overdue)
        .fold(0, (int s, DkDebt d) => s + d.mins);

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        _header(t),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _hero(t, total, overdue),
              const SizedBox(height: 22),
              const DkSectionHead(title: '미뤄둔 일'),
              if (_items.isEmpty)
                const DkEmpty(
                  icon: 'trophy',
                  title: '밀린 일을 다 정리했어요',
                  body: '더 미룬 일이 없어요. 이 페이스를 유지해봐요!',
                )
              else
                Column(
                  children: <Widget>[
                    for (int i = 0; i < _items.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: 8),
                      _debtCard(t, _items[i]),
                    ],
                  ],
                ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '매일 자정에 못 한 일을 감지해, 같은 주 안에서 가장 여유 있는 날로 자동으로 옮겨드려요. '
                  '주말 안에 못 풀면 다음 주로 넘기고 \'계속 밀림\'으로 표시돼요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12.5,
                    height: 1.6,
                    color: t.fgSubtle,
                  ),
                ),
              ),
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
            onTap: widget.onBack,
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
          Text(
            '미룬 시간',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.66,
              color: t.fgStrong,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(DkTokens t, int total, int overdue) {
    const Color white = Color(0xFFFFFFFF);
    return ClipRRect(
      borderRadius: BorderRadius.circular(t.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              t.warningFg,
              Color.lerp(t.warningFg, const Color(0xFF000000), 0.22)!,
            ],
          ),
          borderRadius: BorderRadius.circular(t.radiusLg),
          boxShadow: t.shadows.s2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '아직 못 한 일, 사라지지 않아요',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xD1FFFFFF),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Text(
                  (total / 60).toStringAsFixed(1),
                  style: const TextStyle(
                    fontFamily: 'WantedSans',
                    fontSize: 46,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.84,
                    height: 1,
                    color: white,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '시간',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                _heroStat('대기·배정', fmtMins(total - overdue)),
                Container(
                  width: 1,
                  height: 34,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: const Color(0x40FFFFFF),
                ),
                _heroStat('계속 밀림', fmtMins(overdue)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 12.5,
            color: Color(0xB3FFFFFF),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ],
    );
  }

  Widget _debtCard(DkTokens t, DkDebt d) {
    final DkStateMeta st = debtStateMeta(d.status);
    return DkCard(
      padding: 15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  d.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.15,
                    color: t.fg,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              DkBadge(st.label, tone: st.tone),
            ],
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: t.fgSubtle,
              ),
              children: <InlineSpan>[
                TextSpan(
                  text: '${fmtMins(d.mins)} · ${d.fromLabel ?? '지난 날'}에서 발생',
                ),
                if (d.assignedTo != null)
                  TextSpan(
                    text: ' → ${parseYmd(d.assignedTo!).day}일 배정',
                    style: TextStyle(
                      color: t.infoFg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: DkButton(
                  size: DkButtonSize.sm,
                  variant: DkButtonVariant.subtle,
                  full: true,
                  onPressed: () => _carry(d),
                  leading: DkIcon(
                    'repeat',
                    size: 15,
                    color: t.primary,
                    strokeWidth: 2.1,
                  ),
                  child: const Text('날짜 옮기기'),
                ),
              ),
              const SizedBox(width: 8),
              DkButton(
                size: DkButtonSize.sm,
                variant: DkButtonVariant.ghost,
                onPressed: () => _abandon(d),
                leading: DkIcon(
                  'x',
                  size: 15,
                  color: t.fgMuted,
                  strokeWidth: 2.2,
                ),
                child: const Text('내려놓기'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
