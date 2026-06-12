import 'package:ieoseo/data/api/auth_dto.dart';
import 'package:ieoseo/data/api/settings_dto.dart';
import 'package:ieoseo/data/meta.dart';
import 'package:ieoseo/data/mock_data.dart';
import 'package:ieoseo/data/models.dart';
import 'package:ieoseo/screens/debt/debt_screen.dart';
import 'package:ieoseo/screens/me/me_screen.dart';
import 'package:ieoseo/screens/me/settings_section.dart';
import 'package:ieoseo/screens/review/review_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

const AuthUser _user = AuthUser(
  id: 'u-1',
  email: 'jiwoo@daykit.app',
  nickname: '지우',
  provider: 'LOCAL',
);
const DkSettings _settings = DkSettings();

Future<void> _pumpTall(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(440, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(wrapForTest(child));
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  testWidgets('MeScreen은 프로필·통계·리뷰 진입·설정을 렌더한다', (WidgetTester tester) async {
    bool reviewOpened = false;
    await _pumpTall(
      tester,
      MeScreen(
        user: _user,
        summary: kWeekSummary,
        streak: kStreak,
        focusStats: kFocusStats,
        settings: _settings,
        dark: false,
        onToggleDark: (_) {},
        onBell: () {},
        onOpenCalc: () {},
        onOpenReview: () => reviewOpened = true,
        onOpenCalendar: () {},
        onStub: () {},
        onLogout: () {},
        onUpdateProfile: (_) async {},
        onSaveSettings: (_) {},
        onWithdraw: () async {},
      ),
    );

    expect(find.text('지우'), findsOneWidget);
    expect(find.text('연속 달성'), findsOneWidget);
    expect(find.text('이번 주 돌아보기'), findsOneWidget);
    expect(find.text('다크 모드'), findsOneWidget);
    // 버전은 빌드 메타에서 읽으므로(하드코딩 제거) 테스트 환경에선 fallback "이어서".
    expect(find.textContaining('이어서'), findsOneWidget);

    await tester.tap(find.text('이번 주 돌아보기'));
    expect(reviewOpened, true);
  });

  testWidgets('다크 모드 토글 탭은 onToggleDark를 호출한다', (WidgetTester tester) async {
    bool? toggled;
    await _pumpTall(
      tester,
      MeScreen(
        user: _user,
        summary: kWeekSummary,
        streak: kStreak,
        focusStats: kFocusStats,
        settings: _settings,
        dark: false,
        onToggleDark: (bool v) => toggled = v,
        onBell: () {},
        onOpenCalc: () {},
        onOpenReview: () {},
        onOpenCalendar: () {},
        onStub: () {},
        onLogout: () {},
        onUpdateProfile: (_) async {},
        onSaveSettings: (_) {},
        onWithdraw: () async {},
      ),
    );

    await tester.tap(find.byType(DkToggle).last);
    expect(toggled, true);
  });

  testWidgets('자동 옮기기 토글 탭은 onSaveSettings로 autoCarry를 뒤집는다', (
    WidgetTester tester,
  ) async {
    DkSettings? saved;
    await _pumpTall(
      tester,
      SettingsSection(
        dark: false,
        onToggleDark: (_) {},
        settings: const DkSettings(autoCarry: true),
        onSaveSettings: (DkSettings s) => saved = s,
        onOpenCalc: () {},
        onOpenCalendar: () {},
        onStub: () {},
        onLogout: () {},
        onWithdraw: () async {},
      ),
    );

    // '자동 옮기기' 행의 토글(미룬 시간 그룹 첫 토글)을 탭.
    await tester.tap(find.byType(DkToggle).first);
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.autoCarry, false);
  });

  testWidgets('회원 탈퇴는 2단계 확인을 거쳐 onWithdraw를 호출한다', (
    WidgetTester tester,
  ) async {
    bool withdrawn = false;
    await _pumpTall(
      tester,
      SettingsSection(
        dark: false,
        onToggleDark: (_) {},
        settings: _settings,
        onSaveSettings: (_) {},
        onOpenCalc: () {},
        onOpenCalendar: () {},
        onStub: () {},
        onLogout: () {},
        onWithdraw: () async => withdrawn = true,
      ),
    );

    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();
    // 1단계 확인.
    await tester.tap(find.text('계속'));
    await tester.pumpAndSettle();
    expect(withdrawn, false, reason: '1단계만으로는 탈퇴되지 않아야 한다');
    // 2단계 최종 확인.
    await tester.tap(find.text('탈퇴하기'));
    await tester.pumpAndSettle();

    expect(withdrawn, true);
  });

  testWidgets('ReviewScreen은 완료율·요일별·카테고리·인사이트를 렌더한다', (
    WidgetTester tester,
  ) async {
    await _pumpTall(
      tester,
      ReviewScreen(review: kWeekReview, streak: kStreak, onBack: () {}),
    );

    expect(find.text('주간 리뷰'), findsOneWidget);
    expect(find.text('요일별 실행'), findsOneWidget);
    expect(find.text('카테고리 분포'), findsOneWidget);
    expect(find.textContaining('수요일'), findsOneWidget); // insight
  });

  testWidgets('DebtScreen은 제목과 출처 라벨을 보여준다', (WidgetTester tester) async {
    await _pumpTall(
      tester,
      DebtScreen(
        debts: kDebts,
        onBack: () {},
        onAutoCarry: (_) {},
        onAbandon: (_) {},
      ),
    );

    // 카드 제목(원본 태스크 제목)이 보인다.
    expect(find.text('강의 노트 정리'), findsOneWidget);
    // 출처 라벨이 "…에서 발생" 문구로 보인다.
    expect(find.textContaining('토요일에서 발생'), findsOneWidget);
  });

  testWidgets('DebtScreen 날짜 옮기기는 상태를 배정됨으로 바꾸고 콜백을 호출한다', (
    WidgetTester tester,
  ) async {
    DkDebt? carried;
    await _pumpTall(
      tester,
      DebtScreen(
        debts: kDebts,
        onBack: () {},
        onAutoCarry: (DkDebt d) => carried = d,
        onAbandon: (_) {},
      ),
    );

    // 처음엔 "대기" 1건(d4).
    expect(find.text('대기'), findsOneWidget);

    await tester.tap(find.text('날짜 옮기기').first);
    await tester.pump();

    // 옮기면 "배정됨"이 늘어나고 자동 이월 콜백이 불린다.
    expect(find.text('배정됨'), findsWidgets);
    expect(carried, isNotNull);
  });

  testWidgets('DebtScreen 내려놓기는 항목을 제거한다', (WidgetTester tester) async {
    await _pumpTall(
      tester,
      DebtScreen(
        debts: kDebts,
        onBack: () {},
        onAutoCarry: (_) {},
        onAbandon: (_) {},
      ),
    );

    final int before = tester.widgetList(find.text('내려놓기')).length;
    await tester.tap(find.text('내려놓기').first);
    await tester.pump();
    final int after = tester.widgetList(find.text('내려놓기')).length;
    expect(after, before - 1);
  });
}
