import 'package:ieoseo/data/format.dart';
import 'package:ieoseo/data/models.dart';
import 'package:ieoseo/parts/app_header.dart';
import 'package:ieoseo/parts/dday_hero.dart';
import 'package:ieoseo/parts/metric_bar.dart';
import 'package:ieoseo/parts/task_row.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

const DkTask _task = DkTask(
  id: 't',
  title: '알고리즘 문제 5개',
  mins: 90,
  date: '2026-06-01',
  state: DkTaskState.today,
  category: '공부',
);

/// kToday +28일(이슈 #52). 'D-28' 단언이 실제 오늘과 무관히 성립하도록 상대 날짜로 만든다.
DkEvent get _event => DkEvent(
  id: 'e',
  type: DkEventType.single,
  title: '정보처리기사 실기',
  category: '자격증',
  date: ymd(addDays(kToday, 28)),
  pinned: true,
  color: 'blue',
);

void main() {
  testWidgets('AppHeader는 제목·부제를 렌더한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapForTest(const AppHeader(title: '오늘', subtitle: '6월 1일 월요일')),
    );

    expect(find.text('오늘'), findsOneWidget);
    expect(find.text('6월 1일 월요일'), findsOneWidget);
  });

  testWidgets('TaskRow는 제목·시간·카테고리를 렌더한다', (WidgetTester tester) async {
    await tester.pumpWidget(wrapForTest(const TaskRow(task: _task)));

    expect(find.text('알고리즘 문제 5개'), findsOneWidget);
    expect(find.text('1시간 30분'), findsOneWidget);
    expect(find.text('공부'), findsOneWidget);
  });

  testWidgets('TaskRow 체크박스 탭은 onToggle을 호출한다', (WidgetTester tester) async {
    DkTask? toggled;
    await tester.pumpWidget(
      wrapForTest(TaskRow(task: _task, onToggle: (DkTask t) => toggled = t)),
    );

    await tester.tap(find.byType(DkCheckbox));
    expect(toggled, _task);
  });

  testWidgets('완료 태스크는 "완료" 뱃지를 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapForTest(
        const TaskRow(
          task: DkTask(
            id: 't',
            title: '끝난 일',
            mins: 30,
            date: '2026-06-01',
            state: DkTaskState.done,
            category: '어학',
          ),
        ),
      ),
    );
    expect(find.text('완료'), findsOneWidget);
  });

  testWidgets('DdayHero는 제목과 D-라벨을 렌더하고 탭을 알린다', (WidgetTester tester) async {
    DkEvent? opened;
    final DkEvent event = _event;
    await tester.pumpWidget(
      wrapForTest(DdayHero(event: event, onOpen: (DkEvent e) => opened = e)),
    );

    expect(find.text('정보처리기사 실기'), findsOneWidget);
    expect(find.text('D-28'), findsOneWidget);

    await tester.tap(find.byType(DdayHero));
    expect(opened, event);
  });

  testWidgets('MetricBar는 완료율과 안내문을 계산한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapForTest(
        const MetricBar(
          summary: DkWeekSummary(planned: 18, done: 9, debt: 4.5),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    // 9/18 = 50%
    expect(find.textContaining('50%'), findsOneWidget);
    expect(find.textContaining('밀린 일은 주말로 옮겨드릴게요'), findsOneWidget);
  });
}
