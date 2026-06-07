import 'package:flutter/widgets.dart';

import '../data/calc.dart';
import '../theme/tokens.dart';
import '../widgets/dk_icon.dart';
import '../widgets/dk_segmented.dart';
import '../widgets/dk_sheet.dart';

/// 계산기 본문(일반 + 공학). 프로토타입 `Calculator`.
///
/// 실제 동작 파서([dkEval])로 라이브 프리뷰와 결과를 계산한다.
class Calculator extends StatefulWidget {
  const Calculator({super.key});

  @override
  State<Calculator> createState() => _CalculatorState();
}

/// 키 종류(색 매핑).
enum _KeyKind { num, fn, op, eq, clr }

/// `del`이 한 번에 지울 함수 토큰들.
const List<String> _funcTokens = <String>[
  'sin(',
  'cos(',
  'tan(',
  'asin(',
  'acos(',
  'atan(',
  'ln(',
  'log(',
  '√(',
];

const String _opChars = '+−×÷^';

class _CalculatorState extends State<Calculator> {
  String _expr = '';
  bool _deg = true;
  bool _sci = false;
  bool _justEq = false;

  String? _preview() {
    if (_expr.trim().isEmpty) return null;
    try {
      return dkFmt(dkEval(_expr, deg: _deg));
    } on FormatException {
      return null;
    }
  }

  bool _isNumStart(String s) =>
      s.isNotEmpty && RegExp(r'[0-9.]').hasMatch(s[0]);

  void _ins(String s) {
    setState(() {
      String base = _expr;
      if (_justEq && _isNumStart(s)) base = '';
      _justEq = false;
      _expr = base + s;
    });
  }

  void _insOp(String op) {
    setState(() {
      _justEq = false;
      if (_expr.isEmpty && op != '−') return;
      if (_expr.isNotEmpty && _opChars.contains(_expr[_expr.length - 1])) {
        _expr = _expr.substring(0, _expr.length - 1) + op;
      } else {
        _expr = _expr + op;
      }
    });
  }

  void _clearAll() => setState(() {
    _expr = '';
    _justEq = false;
  });

  void _del() {
    setState(() {
      _justEq = false;
      for (final String f in _funcTokens) {
        if (_expr.endsWith(f)) {
          _expr = _expr.substring(0, _expr.length - f.length);
          return;
        }
      }
      if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
    });
  }

  void _equals() {
    try {
      final double r = dkEval(_expr, deg: _deg);
      setState(() {
        _expr = dkFmt(r).replaceAll(',', '');
        _justEq = true;
      });
    } on FormatException {
      // 식이 잘못되면 그대로 둔다.
    }
  }

  void _plusMinus() {
    setState(() {
      final RegExpMatch? m = RegExp(r'(\d*\.?\d+)$').firstMatch(_expr);
      if (m == null) return;
      final int start = _expr.length - m.group(1)!.length;
      final String before = start - 1 >= 0 ? _expr[start - 1] : '';
      final String before2 = start - 2 >= 0 ? _expr[start - 2] : '';
      final bool isSign =
          before == '−' &&
          (start - 1 == 0 || before2 == '(' || _opChars.contains(before2));
      if (isSign) {
        _expr = _expr.substring(0, start - 1) + _expr.substring(start);
      } else if (start == 0 || before == '(' || _opChars.contains(before)) {
        _expr = '${_expr.substring(0, start)}−${m.group(1)}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final String display = _expr.isEmpty ? '0' : _expr;
    final String? preview = _preview();
    final bool endsOp =
        _expr.isNotEmpty && _opChars.contains(_expr[_expr.length - 1]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // 모드 토글
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            DkSegmented<bool>(
              value: _sci,
              onChanged: (bool v) => setState(() => _sci = v),
              options: const <DkSegment<bool>>[
                DkSegment<bool>(false, '일반'),
                DkSegment<bool>(true, '공학'),
              ],
            ),
            if (_sci)
              GestureDetector(
                onTap: () => setState(() => _deg = !_deg),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: t.bg,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: t.border, width: 1.5),
                  ),
                  child: Text(
                    _deg ? 'DEG' : 'RAD',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: t.fgMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // 디스플레이
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          constraints: const BoxConstraints(minHeight: 96),
          decoration: BoxDecoration(
            color: t.bgSubtle,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.borderSubtle),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                _pretty(display),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'WantedSans',
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.02,
                  height: 1.1,
                  color: t.fgStrong,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 20,
                child: Text(
                  (preview != null && !_justEq && !endsOp) ? '= $preview' : '',
                  style: TextStyle(
                    fontFamily: 'WantedSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: t.fgSubtle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 공학 그리드
        if (_sci) ...<Widget>[
          _SciGrid(onIns: _ins, onInsOp: _insOp),
          const SizedBox(height: 8),
        ],

        // 메인 키패드
        _MainKeypad(
          onIns: _ins,
          onInsOp: _insOp,
          onClear: _clearAll,
          onDel: _del,
          onPlusMinus: _plusMinus,
          onEquals: _equals,
        ),
      ],
    );
  }
}

/// 숫자 런에 천 단위 콤마를 넣어 보기 좋게.
String _pretty(String s) {
  return s.replaceAllMapped(RegExp(r'\d+(\.\d+)?'), (Match m) {
    final List<String> parts = m.group(0)!.split('.');
    final String grouped = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (Match _) => ',',
    );
    return parts.length > 1 ? '$grouped.${parts[1]}' : grouped;
  });
}

class _SciGrid extends StatelessWidget {
  const _SciGrid({required this.onIns, required this.onInsOp});

  final ValueChanged<String> onIns;
  final ValueChanged<String> onInsOp;

  @override
  Widget build(BuildContext context) {
    final List<_CalcKey> keys = <_CalcKey>[
      _CalcKey('(', () => onIns('('), kind: _KeyKind.fn),
      _CalcKey(')', () => onIns(')'), kind: _KeyKind.fn),
      _CalcKey('x²', () => onIns('^2'), kind: _KeyKind.fn),
      _CalcKey('xʸ', () => onInsOp('^'), kind: _KeyKind.fn),
      _CalcKey('√', () => onIns('√('), kind: _KeyKind.fn),
      _CalcKey('sin', () => onIns('sin('), kind: _KeyKind.fn),
      _CalcKey('cos', () => onIns('cos('), kind: _KeyKind.fn),
      _CalcKey('tan', () => onIns('tan('), kind: _KeyKind.fn),
      _CalcKey('ln', () => onIns('ln('), kind: _KeyKind.fn),
      _CalcKey('log', () => onIns('log('), kind: _KeyKind.fn),
      _CalcKey('π', () => onIns('π'), kind: _KeyKind.fn),
      _CalcKey('e', () => onIns('e'), kind: _KeyKind.fn),
      _CalcKey('1/x', () => onIns('^(−1)'), kind: _KeyKind.fn),
      _CalcKey('n!', () => onIns('!'), kind: _KeyKind.fn),
      _CalcKey('%', () => onIns('%'), kind: _KeyKind.fn),
    ];
    return _KeyGrid(columns: 5, keys: keys);
  }
}

class _MainKeypad extends StatelessWidget {
  const _MainKeypad({
    required this.onIns,
    required this.onInsOp,
    required this.onClear,
    required this.onDel,
    required this.onPlusMinus,
    required this.onEquals,
  });

  final ValueChanged<String> onIns;
  final ValueChanged<String> onInsOp;
  final VoidCallback onClear;
  final VoidCallback onDel;
  final VoidCallback onPlusMinus;
  final VoidCallback onEquals;

  @override
  Widget build(BuildContext context) {
    final List<_CalcKey> keys = <_CalcKey>[
      _CalcKey('AC', onClear, kind: _KeyKind.clr),
      _CalcKey.icon('backspace', onDel, kind: _KeyKind.clr),
      _CalcKey('±', onPlusMinus, kind: _KeyKind.op),
      _CalcKey('÷', () => onInsOp('÷'), kind: _KeyKind.op),
      _CalcKey('7', () => onIns('7')),
      _CalcKey('8', () => onIns('8')),
      _CalcKey('9', () => onIns('9')),
      _CalcKey('×', () => onInsOp('×'), kind: _KeyKind.op),
      _CalcKey('4', () => onIns('4')),
      _CalcKey('5', () => onIns('5')),
      _CalcKey('6', () => onIns('6')),
      _CalcKey('−', () => onInsOp('−'), kind: _KeyKind.op),
      _CalcKey('1', () => onIns('1')),
      _CalcKey('2', () => onIns('2')),
      _CalcKey('3', () => onIns('3')),
      _CalcKey('+', () => onInsOp('+'), kind: _KeyKind.op),
      _CalcKey('0', () => onIns('0')),
      _CalcKey('.', () => onIns('.')),
      _CalcKey('=', onEquals, kind: _KeyKind.eq, span: 2),
    ];
    return _KeyGrid(columns: 4, keys: keys);
  }
}

/// 키 한 개의 명세.
class _CalcKey {
  _CalcKey(this.label, this.onTap, {this.kind = _KeyKind.num, this.span = 1})
    : icon = null;
  _CalcKey.icon(this.icon, this.onTap, {this.kind = _KeyKind.num})
    : label = '',
      span = 1;

  final String label;
  final String? icon;
  final VoidCallback onTap;
  final _KeyKind kind;
  final int span;
}

/// 키들을 [columns]열 그리드로 배치(span 지원). 행 단위로 Row를 쌓는다.
class _KeyGrid extends StatelessWidget {
  const _KeyGrid({required this.columns, required this.keys});

  final int columns;
  final List<_CalcKey> keys;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    final List<Widget> current = <Widget>[];
    int used = 0;

    void flush() {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: List<Widget>.from(current)),
        ),
      );
      current.clear();
      used = 0;
    }

    for (final _CalcKey k in keys) {
      if (current.isNotEmpty) current.add(const SizedBox(width: 8));
      current.add(
        Expanded(
          flex: k.span,
          child: _CalcButton(spec: k),
        ),
      );
      used += k.span;
      if (used >= columns) flush();
    }
    if (current.isNotEmpty) flush();

    return Column(children: rows);
  }
}

class _CalcButton extends StatefulWidget {
  const _CalcButton({required this.spec});
  final _CalcKey spec;

  @override
  State<_CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<_CalcButton> {
  bool _down = false;

  ({Color bg, Color fg}) _colors(DkTokens t) {
    switch (widget.spec.kind) {
      case _KeyKind.num:
        return (bg: t.bgPress, fg: t.fg);
      case _KeyKind.fn:
        return (bg: t.bgSubtle, fg: t.fgMuted);
      case _KeyKind.op:
        return (bg: t.primarySubtle, fg: t.primary);
      case _KeyKind.eq:
        return (bg: t.primary, fg: const Color(0xFFFFFFFF));
      case _KeyKind.clr:
        return (bg: t.dangerSubtle, fg: t.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);
    final c = _colors(t);
    final bool isFn = widget.spec.kind == _KeyKind.fn;

    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.spec.onTap,
      child: AnimatedScale(
        scale: _down ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: widget.spec.icon != null
              ? DkIcon(widget.spec.icon!, size: 22, color: c.fg)
              : Text(
                  widget.spec.label,
                  style: TextStyle(
                    fontFamily: isFn ? 'Pretendard' : 'WantedSans',
                    fontWeight: isFn ? FontWeight.w600 : FontWeight.w700,
                    fontSize: isFn ? 14 : 21,
                    letterSpacing: -0.2,
                    color: c.fg,
                  ),
                ),
        ),
      ),
    );
  }
}

/// 계산기 시트를 띄운다. 프로토타입 `CalcSheet`.
Future<void> showCalcSheet(BuildContext context) {
  return showDkSheet<void>(
    context,
    title: '계산기',
    full: true,
    child: const Calculator(),
  );
}
