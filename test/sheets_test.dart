import 'package:ieoseo/data/api/notif_dto.dart';
import 'package:ieoseo/data/format.dart';
import 'package:ieoseo/data/models.dart';
import 'package:ieoseo/screens/sheets/event_sheet.dart';
import 'package:ieoseo/screens/sheets/notif_sheet.dart';
import 'package:ieoseo/screens/sheets/task_sheet.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

Future<void> _pumpTall(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(440, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(wrapForTest(SingleChildScrollView(child: child)));
  await tester.pump();
}

void main() {
  testWidgets('태스크 추가 시트는 필드와 추가하기 버튼을 보인다', (WidgetTester tester) async {
    await _pumpTall(
      tester,
      TaskSheetBody(isNew: true, onClose: () {}, onToast: (_, _, _) {}),
    );

    expect(find.text('제목'), findsOneWidget);
    expect(find.text('예상 소요시간'), findsOneWidget);
    expect(find.text('추가하기'), findsOneWidget);
  });

  testWidgets('태스크 시트는 하루/기간 날짜 토글을 보인다(#50)', (WidgetTester tester) async {
    await _pumpTall(
      tester,
      TaskSheetBody(isNew: true, onClose: () {}, onToast: (_, _, _) {}),
    );

    expect(find.text('하루'), findsOneWidget);
    expect(find.text('기간'), findsOneWidget);
  });

  testWidgets('범위 태스크 편집 시 시작~종료를 보인다(#50)', (WidgetTester tester) async {
    await _pumpTall(
      tester,
      TaskSheetBody(
        task: const DkTask(
          id: 't-r',
          title: '여행 준비',
          mins: 120,
          date: '2026-06-07',
          startDate: '2026-06-04',
          state: DkTaskState.today,
          category: '개인',
        ),
        isNew: false,
        onClose: () {},
        onToast: (_, _, _) {},
      ),
    );

    // 범위 모드라 날짜 필드에 "시작 ~ 종료" 구분자가 보인다.
    expect(find.textContaining(' ~ '), findsOneWidget);
  });

  testWidgets('태스크 상세는 완료 처리를 호출한다', (WidgetTester tester) async {
    DkTask? toggled;
    await _pumpTall(
      tester,
      TaskSheetBody(
        task: const DkTask(
          id: 't',
          title: '기출 1회',
          mins: 120,
          date: '2026-06-01',
          state: DkTaskState.today,
          category: '자격증',
        ),
        isNew: false,
        onClose: () {},
        onToggle: (DkTask t) => toggled = t,
        onToast: (_, _, _) {},
      ),
    );

    await tester.tap(find.text('완료 처리'));
    expect(toggled?.id, 't');
  });

  testWidgets('이월 태스크는 이월 배너를 보인다', (WidgetTester tester) async {
    await _pumpTall(
      tester,
      TaskSheetBody(
        task: const DkTask(
          id: 't',
          title: '이력서',
          mins: 45,
          date: '2026-06-01',
          state: DkTaskState.carried,
          category: '취업',
          fromLabel: '지난주 금요일',
        ),
        isNew: false,
        onClose: () {},
        onToast: (_, _, _) {},
      ),
    );

    expect(find.textContaining('옮겨온 할 일이에요'), findsOneWidget);
  });

  testWidgets('이벤트 추가 시트는 타입 세그먼트와 추가하기를 보인다', (WidgetTester tester) async {
    await _pumpTall(tester, EventSheetBody(isNew: true, onClose: () {}));

    expect(find.text('이벤트 타입'), findsOneWidget);
    expect(find.text('D-Day'), findsOneWidget);
    expect(find.text('추가하기'), findsOneWidget);
  });

  testWidgets('생성 시트 이벤트 타입에 진행률 옵션이 없다(D-Day/기간만)', (
    WidgetTester tester,
  ) async {
    await _pumpTall(tester, EventSheetBody(isNew: true, onClose: () {}));

    // 진행률은 생성 타입에서 제거(보기 토글로 이동).
    expect(find.text('기간 진행률'), findsNothing);
    expect(find.text('기간'), findsOneWidget);
  });

  testWidgets('D-Day 추가 시 목표일 기본값은 오늘이다(먼 미래 아님)', (
    WidgetTester tester,
  ) async {
    await _pumpTall(tester, EventSheetBody(isNew: true, onClose: () {}));

    // 기본 타입은 D-Day(single) → 목표일 필드가 오늘 날짜를 보인다.
    expect(find.text(fmtDate(ymd(kToday))), findsOneWidget);
  });

  testWidgets('기간 이벤트 상세는 보기 토글을 보이고 진행률로 전환하면 %를 보인다', (
    WidgetTester tester,
  ) async {
    final DkEvent ev = DkEvent(
      id: 'p1',
      type: DkEventType.period,
      title: '집중 챌린지',
      category: '건강',
      start: ymd(addDays(kToday, -10)),
      end: ymd(addDays(kToday, 10)),
    );
    await _pumpTall(
      tester,
      EventSheetBody(event: ev, isNew: false, onClose: () {}),
    );

    // 보기 토글 노출(마감 D-Day ↔ 진행률).
    expect(find.text('마감 D-Day'), findsWidgets);
    expect(find.text('진행률'), findsOneWidget);

    // 진행률로 전환 → 히어로에 % 표시.
    await tester.tap(find.text('진행률'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('%'), findsOneWidget);
  });

  testWidgets('알림 시트는 실데이터 목록을 렌더한다', (WidgetTester tester) async {
    await _pumpTall(
      tester,
      NotifSheetBody(
        items: const <DkNotif>[
          DkNotif(
            id: 'n-1',
            type: DkNotifType.dday,
            title: '토익 시험',
            body: '토익 시험이 3일 남았어요',
            read: false,
            createdAt: '2026-06-04T09:00:00Z',
          ),
          DkNotif(
            id: 'n-2',
            type: DkNotifType.streak,
            title: '스트릭 달성!',
            body: '7일 연속 달성했어요',
            read: true,
            createdAt: '2026-06-03T09:00:00Z',
          ),
        ],
        onTapItem: (_) {},
      ),
    );

    expect(find.textContaining('토익 시험이 3일'), findsOneWidget);
    expect(find.textContaining('7일 연속'), findsOneWidget);
  });

  testWidgets('알림 시트는 빈 상태를 보인다', (WidgetTester tester) async {
    await _pumpTall(
      tester,
      NotifSheetBody(items: const <DkNotif>[], onTapItem: (_) {}),
    );

    expect(find.textContaining('알림'), findsWidgets);
  });

  testWidgets('알림 항목 탭 시 읽음 콜백을 호출한다', (WidgetTester tester) async {
    DkNotif? tapped;
    await _pumpTall(
      tester,
      NotifSheetBody(
        items: const <DkNotif>[
          DkNotif(
            id: 'n-1',
            type: DkNotifType.dday,
            title: '토익 시험',
            body: '토익 시험이 3일 남았어요',
            read: false,
            createdAt: '2026-06-04T09:00:00Z',
          ),
        ],
        onTapItem: (DkNotif n) => tapped = n,
      ),
    );

    await tester.tap(find.textContaining('토익 시험이 3일'));
    expect(tapped?.id, 'n-1');
  });

  testWidgets('안 읽은 알림이 있으면 모두 읽음 액션을 노출하고 콜백을 호출한다', (
    WidgetTester tester,
  ) async {
    bool marked = false;
    await _pumpTall(
      tester,
      NotifSheetBody(
        items: const <DkNotif>[
          DkNotif(
            id: 'n-1',
            type: DkNotifType.dday,
            title: '토익 시험',
            body: '토익 시험이 3일 남았어요',
            read: false,
            createdAt: '2026-06-04T09:00:00Z',
          ),
        ],
        onTapItem: (_) {},
        onMarkAllRead: () => marked = true,
      ),
    );

    expect(find.text('모두 읽음'), findsOneWidget);
    await tester.tap(find.text('모두 읽음'));
    expect(marked, true);
  });

  testWidgets('모두 읽은 상태면 모두 읽음 액션이 없다', (WidgetTester tester) async {
    await _pumpTall(
      tester,
      NotifSheetBody(
        items: const <DkNotif>[
          DkNotif(
            id: 'n-2',
            type: DkNotifType.streak,
            title: '스트릭 달성!',
            body: '7일 연속 달성했어요',
            read: true,
            createdAt: '2026-06-03T09:00:00Z',
          ),
        ],
        onTapItem: (_) {},
        onMarkAllRead: () {},
      ),
    );

    expect(find.text('모두 읽음'), findsNothing);
  });
}
