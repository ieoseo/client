import 'package:ieoseo/data/models.dart';
import 'package:ieoseo/screens/me/calendar_sync_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

/// CalendarSyncScreen 위젯 테스트(이슈 #59).
///
/// 미연결 안내·provider 행·연결/해제·동기화 콜백을 검증한다(외부 호출 없음).
Future<void> _pumpTall(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(440, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(wrapForTest(child));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('미연결이면 안내 문구와 제공자 3개 행을 보여준다', (WidgetTester tester) async {
    await _pumpTall(
      tester,
      CalendarSyncScreen(
        connections: const <DkCalendarConnection>[],
        syncing: false,
        onBack: () {},
        onConnect: (_) {},
        onDisconnect: (_) {},
        onSync: () {},
      ),
    );

    expect(find.textContaining('연결된 캘린더가 없어요'), findsOneWidget);
    // MVP(이슈 #67): Google만 노출, Apple·Notion 은 숨김.
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Apple'), findsNothing);
    expect(find.text('Notion'), findsNothing);
    expect(find.text('연결하기'), findsNWidgets(1));
  });

  testWidgets('연결된 provider 는 연결됨 뱃지와 연결 해제 버튼을 보여준다', (
    WidgetTester tester,
  ) async {
    DkSource? disconnected;
    await _pumpTall(
      tester,
      CalendarSyncScreen(
        connections: const <DkCalendarConnection>[
          DkCalendarConnection(
            source: DkSource.google,
            status: DkConnectionStatus.connected,
            lastSyncedAt: '2026-06-04T09:00:00Z',
          ),
        ],
        syncing: false,
        onBack: () {},
        onConnect: (_) {},
        onDisconnect: (DkSource s) => disconnected = s,
        onSync: () {},
      ),
    );

    expect(find.text('연결됨'), findsOneWidget);
    expect(find.text('연결 해제'), findsOneWidget);

    await tester.tap(find.text('연결 해제'));
    await tester.pump();
    expect(disconnected, DkSource.google);
  });

  testWidgets('연결이 있으면 동기화 버튼이 onSync 를 호출한다', (WidgetTester tester) async {
    bool synced = false;
    await _pumpTall(
      tester,
      CalendarSyncScreen(
        connections: const <DkCalendarConnection>[
          DkCalendarConnection(
            source: DkSource.notion,
            status: DkConnectionStatus.connected,
          ),
        ],
        syncing: false,
        onBack: () {},
        onConnect: (_) {},
        onDisconnect: (_) {},
        onSync: () => synced = true,
      ),
    );

    await tester.tap(find.text('지금 동기화'));
    await tester.pump();
    expect(synced, true);
  });
}
