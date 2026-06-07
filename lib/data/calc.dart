/// 이어서 계산기 식 평가기. 프로토타입 `daykit-calc.jsx`의
/// tokenize → shunting-yard RPN → eval 파이프라인을 Dart로 이식한다.
///
/// 지원: 사칙연산·거듭제곱(`^`, 우결합)·단항 마이너스·암묵 곱셈·괄호,
/// 후위 연산자(`!` 팩토리얼=감마, `%` 백분율), 상수(π·e),
/// 함수(sin/cos/tan/asin/acos/atan/ln/log/√). 삼각함수는 [deg] 모드.
library;

import 'dart:math' as math;

/// 토큰 종류.
enum _TokKind { num, func, lp, rp, post, op }

class _Tok {
  const _Tok(this.kind, {this.num, this.text});
  final _TokKind kind;
  final double? num;
  final String? text;
}

/// 함수명(긴 이름이 짧은 이름의 prefix가 아니므로 순서 무관).
const List<String> _funcs = <String>[
  'asin',
  'acos',
  'atan',
  'sin',
  'cos',
  'tan',
  'ln',
  'log',
];

bool _isNumChar(String c) =>
    (c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39) || c == '.';

/// 입력 문자열을 토큰 리스트로 분해한다. 잘못된 문자는 [FormatException].
List<_Tok> _tokenize(String s) {
  final List<_Tok> toks = <_Tok>[];
  int i = 0;
  while (i < s.length) {
    final String c = s[i];
    if (c == ' ') {
      i++;
      continue;
    }
    if (_isNumChar(c)) {
      int j = i + 1;
      while (j < s.length && _isNumChar(s[j])) {
        j++;
      }
      final double? v = double.tryParse(s.substring(i, j));
      if (v == null) throw const FormatException('bad number');
      toks.add(_Tok(_TokKind.num, num: v));
      i = j;
      continue;
    }
    if (c == 'π') {
      toks.add(_Tok(_TokKind.num, num: math.pi));
      i++;
      continue;
    }
    if (c == 'e') {
      toks.add(_Tok(_TokKind.num, num: math.e));
      i++;
      continue;
    }
    if (c == '√') {
      toks.add(const _Tok(_TokKind.func, text: 'sqrt'));
      i++;
      continue;
    }
    final String? f = _matchFunc(s, i);
    if (f != null) {
      toks.add(_Tok(_TokKind.func, text: f));
      i += f.length;
      continue;
    }
    if (c == '(') {
      toks.add(const _Tok(_TokKind.lp));
      i++;
      continue;
    }
    if (c == ')') {
      toks.add(const _Tok(_TokKind.rp));
      i++;
      continue;
    }
    if (c == '!') {
      toks.add(const _Tok(_TokKind.post, text: '!'));
      i++;
      continue;
    }
    if (c == '%') {
      toks.add(const _Tok(_TokKind.post, text: '%'));
      i++;
      continue;
    }
    final String? op = _opMap[c];
    if (op != null) {
      toks.add(_Tok(_TokKind.op, text: op));
      i++;
      continue;
    }
    throw FormatException('bad char: $c');
  }
  return toks;
}

const Map<String, String> _opMap = <String, String>{
  '+': '+',
  '−': '-',
  '-': '-',
  '×': '*',
  '*': '*',
  '÷': '/',
  '/': '/',
  '^': '^',
};

String? _matchFunc(String s, int i) {
  for (final String fn in _funcs) {
    if (s.startsWith(fn, i)) return fn;
  }
  return null;
}

const Map<String, int> _prec = <String, int>{
  '+': 2,
  '-': 2,
  '*': 3,
  '/': 3,
  'u': 4, // 단항 마이너스
  '^': 5,
};
const Map<String, bool> _rightAssoc = <String, bool>{'^': true, 'u': true};

/// 토큰 리스트를 RPN(후위) 출력 리스트로 변환한다.
/// 출력 원소는 [_Tok](num/post) 또는 연산자 문자열("+", "u", "f:sin" 등).
List<Object> _toRpn(List<_Tok> toks) {
  final List<Object> out = <Object>[];
  final List<String> ops = <String>[];
  bool prevVal = false;

  String top() => ops.last;

  void popWhile(bool Function(String) cond) {
    while (ops.isNotEmpty && top() != '(' && cond(top())) {
      out.add(ops.removeLast());
    }
  }

  void implicitMul() {
    popWhile(
      (String o) =>
          o.startsWith('f:') ||
          (_prec.containsKey(o) && _prec[o]! >= _prec['*']!),
    );
    ops.add('*');
  }

  for (final _Tok tk in toks) {
    switch (tk.kind) {
      case _TokKind.num:
        if (prevVal) implicitMul();
        out.add(tk);
        prevVal = true;
      case _TokKind.func:
        if (prevVal) implicitMul();
        ops.add('f:${tk.text}');
        prevVal = false;
      case _TokKind.lp:
        if (prevVal) implicitMul();
        ops.add('(');
        prevVal = false;
      case _TokKind.rp:
        popWhile((_) => true);
        if (ops.isNotEmpty && top() == '(') ops.removeLast();
        if (ops.isNotEmpty && top().startsWith('f:')) out.add(ops.removeLast());
        prevVal = true;
      case _TokKind.post:
        out.add(tk);
        prevVal = true;
      case _TokKind.op:
        String op = tk.text!;
        if (op == '-' && !prevVal) {
          op = 'u';
        } else if (op == '+' && !prevVal) {
          continue;
        }
        final int p = _prec[op]!;
        final bool right = _rightAssoc[op] ?? false;
        popWhile(
          (String o) =>
              o.startsWith('f:') ||
              (_prec.containsKey(o) &&
                  (right ? _prec[o]! > p : _prec[o]! >= p)),
        );
        ops.add(op);
        prevVal = false;
    }
  }
  while (ops.isNotEmpty) {
    final String o = ops.removeLast();
    if (o == '(') throw const FormatException('mismatched paren');
    out.add(o);
  }
  return out;
}

/// 팩토리얼. 음수/비정수는 감마 함수(Lanczos 근사)로 계산.
double dkFact(double n) {
  if (n < 0 || n != n.floorToDouble()) return math.exp(_lnGamma(n + 1));
  double r = 1;
  for (int k = 2; k <= n; k++) {
    r *= k;
  }
  return r;
}

const List<double> _g = <double>[
  676.5203681218851,
  -1259.1392167224028,
  771.32342877765313,
  -176.61502916214059,
  12.507343278686905,
  -0.13857109526572012,
  9.9843695780195716e-6,
  1.5056327351493116e-7,
];

double _lnGamma(double xIn) {
  double x = xIn;
  if (x < 0.5) {
    return math.log(math.pi / math.sin(math.pi * x)) - _lnGamma(1 - x);
  }
  x -= 1;
  double a = 0.99999999999980993;
  final double t = x + 7.5;
  for (int k = 0; k < _g.length; k++) {
    a += _g[k] / (x + k + 1);
  }
  return 0.5 * math.log(2 * math.pi) +
      (x + 0.5) * math.log(t) -
      t +
      math.log(a);
}

double _log10(double x) => math.log(x) / math.ln10;

/// 식 [expr]을 평가한다. [deg]면 삼각함수를 도(degree) 단위로 처리.
/// 파싱·평가 실패는 [FormatException].
double dkEval(String expr, {bool deg = true}) {
  final List<Object> rpn = _toRpn(_tokenize(expr));
  final List<double> st = <double>[];
  double conv(double x) => deg ? x * math.pi / 180 : x;
  double inv(double x) => deg ? x * 180 / math.pi : x;

  for (final Object it in rpn) {
    if (it is _Tok) {
      if (it.kind == _TokKind.num) {
        st.add(it.num!);
      } else if (it.kind == _TokKind.post) {
        if (st.isEmpty) throw const FormatException('eval');
        final double x = st.removeLast();
        st.add(it.text == '!' ? dkFact(x) : x / 100);
      }
    } else if (it is String && it.startsWith('f:')) {
      final String f = it.substring(2);
      if (st.isEmpty) throw const FormatException('eval');
      final double x = st.removeLast();
      st.add(switch (f) {
        'sin' => math.sin(conv(x)),
        'cos' => math.cos(conv(x)),
        'tan' => math.tan(conv(x)),
        'asin' => inv(math.asin(x)),
        'acos' => inv(math.acos(x)),
        'atan' => inv(math.atan(x)),
        'ln' => math.log(x),
        'log' => _log10(x),
        'sqrt' => math.sqrt(x),
        _ => throw FormatException('unknown func: $f'),
      });
    } else if (it == 'u') {
      if (st.isEmpty) throw const FormatException('eval');
      st.add(-st.removeLast());
    } else {
      if (st.length < 2) throw const FormatException('eval');
      final double b = st.removeLast();
      final double a = st.removeLast();
      st.add(switch (it as String) {
        '+' => a + b,
        '-' => a - b,
        '*' => a * b,
        '/' => a / b,
        '^' => math.pow(a, b).toDouble(),
        _ => throw FormatException('unknown op: $it'),
      });
    }
  }
  if (st.length != 1 || !st[0].isFinite) throw const FormatException('eval');
  return st[0];
}

/// 결과 숫자를 표시 문자열로 포맷한다. 큰 수/작은 수는 지수 표기,
/// 그 외엔 정밀도 12자리 정리 + 정수부 천 단위 콤마.
String dkFmt(double n) {
  if (!n.isFinite) return '오류';
  if (n.abs() >= 1e15 || (n != 0 && n.abs() < 1e-9)) {
    return n.toStringAsExponential(6).replaceAll(RegExp(r'\.?0+e'), 'e');
  }
  String s = double.parse(n.toStringAsPrecision(12)).toString();
  if (s.endsWith('.0')) s = s.substring(0, s.length - 2);
  final List<String> parts = s.split('.');
  final String grouped = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (Match m) => ',',
  );
  return parts.length > 1 ? '$grouped.${parts[1]}' : grouped;
}
