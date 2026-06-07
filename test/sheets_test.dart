import 'package:ieoseo/data/api/notif_dto.dart';
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
}
