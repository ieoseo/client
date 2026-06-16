import 'format.dart';
import 'models.dart';

/// 프로토타입 `daykit-data.jsx`의 목 데이터를 이식. `MockRepository`가 노출한다(ADR-0005).
/// 실제 값은 server 권위. 날짜는 [kToday](실제 오늘) 기준 상대 오프셋으로 만들어, 데모가
/// 항상 "오늘"을 중심으로 보이게 한다(이슈 #52 — 옛 고정 기준 2026-06-01 제거).

/// [kToday] 에서 [offset]일 떨어진 날짜의 `YYYY-MM-DD`.
String _d(int offset) => ymd(addDays(kToday, offset));

/// D-Day 이벤트.
List<DkEvent> get kEvents => <DkEvent>[
  DkEvent(
    id: 'e1',
    type: DkEventType.single,
    title: '정보처리기사 실기',
    category: '자격증',
    date: _d(28),
    pinned: true,
    memo: '필답형 + 실무. 기출 5개년 정리하기.',
    color: 'blue',
    remindDays: const <int>[7, 3, 1],
  ),
  DkEvent(
    id: 'e2',
    type: DkEventType.single,
    title: '토익 정기시험',
    category: '어학',
    date: _d(12),
    memo: 'RC 파트5 시간 단축 연습.',
    color: 'violet',
    remindDays: const <int>[3, 1],
  ),
  DkEvent(
    id: 'e3',
    type: DkEventType.period,
    title: '정처기 실기 접수',
    category: '자격증',
    start: _d(7),
    end: _d(11),
    memo: '접수 기간 안에 신청·결제 완료하기.',
    color: 'orange',
    remindDays: const <int>[3],
  ),
  DkEvent(
    id: 'e4',
    type: DkEventType.progress,
    title: '헬스 100일 챌린지',
    category: '건강',
    start: _d(-61),
    end: _d(38),
    memo: '주 4회 이상 인증.',
    color: 'green',
  ),
];

/// 할 일.
List<DkTask> get kTasks => <DkTask>[
  DkTask(
    id: 't1',
    title: '알고리즘 문제 5개',
    mins: 90,
    date: _d(0),
    state: DkTaskState.done,
    category: '공부',
    actualMins: 80,
  ),
  DkTask(
    id: 't2',
    title: '영단어 30개 암기',
    mins: 30,
    date: _d(0),
    state: DkTaskState.done,
    category: '어학',
    actualMins: 25,
  ),
  DkTask(
    id: 't3',
    title: '정처기 실기 기출 1회',
    mins: 120,
    date: _d(0),
    state: DkTaskState.today,
    category: '자격증',
    eventId: 'e1',
  ),
  DkTask(
    id: 't4',
    title: '헬스 — 하체',
    mins: 60,
    date: _d(0),
    state: DkTaskState.today,
    category: '건강',
    eventId: 'e4',
  ),
  DkTask(
    id: 't5',
    title: '이력서 1차 수정',
    mins: 45,
    date: _d(0),
    state: DkTaskState.carried,
    category: '취업',
    fromDate: _d(-3),
    fromLabel: '지난주 금요일',
  ),
  DkTask(
    id: 't6',
    title: '블로그 회고 글쓰기',
    mins: 60,
    date: _d(0),
    state: DkTaskState.overdue,
    category: '기타',
    fromDate: _d(-5),
    fromLabel: '지난주 수요일',
  ),
  DkTask(
    id: 't7',
    title: '포트폴리오 케이스 1',
    mins: 120,
    date: _d(1),
    state: DkTaskState.pending,
    category: '취업',
  ),
  DkTask(
    id: 't8',
    title: '토익 RC 모의 1회',
    mins: 75,
    date: _d(2),
    state: DkTaskState.pending,
    category: '어학',
  ),
  DkTask(
    id: 't9',
    title: '헬스 — 등',
    mins: 60,
    date: _d(3),
    state: DkTaskState.pending,
    category: '건강',
  ),
];

/// 미룬 시간(부채).
List<DkDebt> get kDebts => <DkDebt>[
  DkDebt(
    id: 'd1',
    title: '이력서 1차 수정',
    mins: 45,
    fromDate: _d(-3),
    status: DkDebtStatus.assigned,
    assignedTo: _d(0),
    fromLabel: '금요일',
  ),
  DkDebt(
    id: 'd2',
    title: '디자인 시안 검토',
    mins: 90,
    fromDate: _d(-4),
    status: DkDebtStatus.assigned,
    assignedTo: _d(5),
    fromLabel: '목요일',
  ),
  DkDebt(
    id: 'd3',
    title: '블로그 회고 글쓰기',
    mins: 60,
    fromDate: _d(-5),
    status: DkDebtStatus.overdue,
    fromLabel: '수요일',
  ),
  DkDebt(
    id: 'd4',
    title: '강의 노트 정리',
    mins: 75,
    fromDate: _d(-2),
    status: DkDebtStatus.pending,
    fromLabel: '토요일',
  ),
];

/// 외부 캘린더 이벤트(읽기 전용).
List<DkExternal> get kExternal => <DkExternal>[
  DkExternal(
    id: 'x1',
    title: '팀 스프린트 회의',
    date: _d(1),
    time: '10:00',
    source: DkSource.google,
  ),
  DkExternal(
    id: 'x2',
    title: '점심 약속 — 민지',
    date: _d(2),
    time: '12:30',
    source: DkSource.google,
  ),
  DkExternal(
    id: 'x3',
    title: '스터디 모임',
    date: _d(4),
    time: '19:00',
    source: DkSource.apple,
  ),
  DkExternal(
    id: 'x4',
    title: '독서 정리',
    date: _d(8),
    time: '21:00',
    source: DkSource.notion,
  ),
  DkExternal(
    id: 'x5',
    title: '1:1 미팅',
    date: _d(10),
    time: '15:00',
    source: DkSource.google,
  ),
];

/// 주간 요약(시간).
const DkWeekSummary kWeekSummary = DkWeekSummary(
  planned: 18.0,
  done: 11.0,
  debt: 4.5,
);

/// 연속 달성(스트릭) 일수.
const int kStreak = 6;

/// 집중 통계.
const DkFocusStats kFocusStats = DkFocusStats(
  todaySessions: 3,
  todayMinutes: 75,
  goal: 6,
);

/// 포모도로 기본 설정.
const DkPomodoro kPomodoro = DkPomodoro();
