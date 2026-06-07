import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';
import '../widgets/dk_button.dart';
import '../widgets/dk_icon.dart';

/// 온보딩. 프로토타입 `Onboarding` + `OnbArt`.
///
/// 좌우 24. 상단 우측 "건너뛰기". 중앙: 단계 일러스트 + 제목 27/800 + 본문 15.5.
/// 점 인디케이터(활성 22×7). 하단 lg full 버튼("다음"/"시작하기").
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnbCopy {
  const _OnbCopy(this.title, this.body);
  final String title;
  final String body;
}

const List<_OnbCopy> _onb = <_OnbCopy>[
  _OnbCopy('목표까지 며칠?', '시험·자격증·마감을 D-Day로 등록하면\n가장 임박한 목표가 홈에 크게 떠요.'),
  _OnbCopy('못 한 일은 사라지지 않아요', "오늘 못 끝낸 일은 '미룬 시간'으로 모여\n여유 있는 날로 똑똑하게 옮겨드려요."),
  _OnbCopy('캘린더까지 한 화면에', 'Google·Apple·Notion 일정도 함께 모아\n하루를 한눈에 볼 수 있어요.'),
];

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  void _next() {
    if (_step == _onb.length - 1) {
      widget.onDone();
    } else {
      setState(() => _step++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final bool last = _step == _onb.length - 1;

    return Container(
      color: t.bg,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: widget.onDone,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '건너뛰기',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: t.fgSubtle,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  OnbArt(step: _step, key: ValueKey<int>(_step)),
                  const SizedBox(height: 36),
                  Text(
                    _onb[_step].title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.81,
                      color: t.fgStrong,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _onb[_step].body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15.5,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                      color: t.fgSubtle,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int i = 0; i < _onb.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    margin: const EdgeInsets.symmetric(horizontal: 3.5),
                    width: i == _step ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _step ? t.primary : t.borderStrong,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: DkButton(
                size: DkButtonSize.lg,
                full: true,
                onPressed: _next,
                child: Text(last ? '시작하기' : '다음'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 온보딩 일러스트(0/1/2). 프로토타입 `OnbArt`.
class OnbArt extends StatelessWidget {
  const OnbArt({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    switch (step) {
      case 0:
        return _art0(t);
      case 1:
        return _art1(t);
      default:
        return _art2(t);
    }
  }

  Widget _art0(DkTokens t) {
    return SizedBox(
      width: 220,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 168,
            height: 168,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.fgStrong,
              borderRadius: BorderRadius.circular(40),
              boxShadow: t.shadows.s3,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '정보처리기사',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFFFFFF).withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'D-28',
                  style: TextStyle(
                    fontFamily: 'WantedSans',
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -3.2,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 18,
            right: 6,
            child: _floatChip(t, 'D-12 토익', t.primary),
          ),
          Positioned(
            bottom: 14,
            left: 0,
            child: _floatChip(t, 'D-3 마감', t.warningFg),
          ),
        ],
      ),
    );
  }

  Widget _floatChip(DkTokens t, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: t.shadows.s2,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _art1(DkTokens t) {
    return SizedBox(
      width: 240,
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '월요일',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: t.fgSubtle,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: t.borderStrong, width: 2),
                ),
                child: Text(
                  '비었어요',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.fgDisabled,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: DkIcon(
              'arrowR',
              size: 30,
              color: t.primary,
              strokeWidth: 2.2,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '토요일',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: t.primary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 84,
                height: 96,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: t.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: t.shadows.s2,
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    DkIcon(
                      'repeat',
                      size: 20,
                      color: Color(0xFFFFFFFF),
                      strokeWidth: 2.2,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '운동 2시간',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _art2(DkTokens t) {
    const List<Color?> cells = <Color?>[
      null,
      Color(0xFF0066FF),
      null,
      Color(0xFF34A853),
      null,
      null,
      Color(0xFF7B61FF),
      null,
      null,
      Color(0xFF0066FF),
      null,
      Color(0xFF111111),
      null,
      null,
      Color(0xFF34A853),
      null,
      null,
      Color(0xFF0066FF),
      null,
      null,
    ];
    const List<List<String>> sources = <List<String>>[
      <String>['이어서', '#0066FF'],
      <String>['Google', '#34A853'],
      <String>['Apple', '#111111'],
      <String>['Notion', '#7B61FF'],
    ];

    return SizedBox(
      width: 220,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 180,
            height: 168,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.bg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: t.shadows.s3,
              border: Border.all(color: t.borderSubtle),
            ),
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 5,
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
              children: <Widget>[
                for (final Color? c in cells)
                  Container(
                    decoration: BoxDecoration(
                      color: c ?? t.bgPress,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final List<String> s in sources)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _sourceChip(t, s[0], _parseHex(s[1])),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceChip(DkTokens t, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(99),
        boxShadow: t.shadows.s1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: t.fg,
            ),
          ),
        ],
      ),
    );
  }

  Color _parseHex(String hex) {
    final String h = hex.replaceFirst('#', '');
    final String full = h.length == 3
        ? h.split('').map((String c) => '$c$c').join()
        : h;
    return Color(int.parse('FF$full', radix: 16));
  }
}
