import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api/api_exception.dart';
import '../data/api/auth_dto.dart';
import '../data/auth/social_auth.dart';
import '../data/api/notif_dto.dart';
import '../data/api/settings_dto.dart';
import '../data/data_controller.dart';
import '../data/format.dart';
import '../data/meta.dart';
import '../data/models.dart';
import '../data/notif_controller.dart';
import '../data/settings_controller.dart';
import '../theme/tokens.dart';
import '../widgets/dk_badge.dart';
import '../widgets/dk_button.dart';
import '../widgets/dk_empty.dart';
import '../widgets/dk_feedback.dart';
import '../widgets/dk_tab_bar.dart';
import 'calc_sheet.dart';
import 'debt/debt_screen.dart';
import 'focus/focus_screen.dart';
import 'me/calendar_sync_screen.dart';
import 'me/me_screen.dart';
import 'plan/plan_screen.dart';
import 'loading_skeleton.dart';
import 'plan/plan_summary.dart';
import 'review/review_screen.dart';
import 'review/week_review_builder.dart';
import 'sheets/event_sheet.dart';
import 'sheets/notif_sheet.dart';
import 'sheets/task_sheet.dart';
import 'today/today_screen.dart';

/// 캘린더 OAuth 동의 화면 실행을 허용하는 host(S2). 서버가 준 URL 이라도 이 집합 밖이면 거부한다.
const Set<String> kAllowedCalendarAuthHosts = <String>{'accounts.google.com'};

/// 메인 4탭 셸. 진입 플로우 이후의 컨테이너.
///
/// 탭바·FAB·토스트 + 탭별 실제 화면 배선. events/tasks/debts 데이터·쓰기는
/// [DataController](server 연동, 이슈 #35)가 공급한다. 서버 엔드포인트가 없는
/// 읽기(외부 캘린더·요약·집중·스트릭·리뷰)는 컨트롤러의 repository 패스스루로 읽는다.
class MainScaffold extends StatefulWidget {
  const MainScaffold({
    super.key,
    required this.controller,
    required this.notif,
    required this.settings,
    required this.user,
    required this.dark,
    required this.onToggleDark,
    required this.onLogout,
    required this.onUpdateProfile,
    required this.onWithdraw,
    this.linkedProviders = const <String>{},
    this.onLinkAccount,
    this.onUnlinkAccount,
  });

  final DataController controller;

  /// 인앱 알림 컨트롤러(이슈 #46). 벨 안읽음 점·알림 시트 데이터를 공급한다.
  final NotifController notif;

  /// 사용자 설정 컨트롤러(이슈 #56). 나 탭 설정 표시·저장에 쓴다.
  final SettingsController settings;

  /// 현재 인증 사용자(이슈 #56). 나 탭 프로필 표시·수정 대상.
  final AuthUser user;
  final bool dark;
  final ValueChanged<bool> onToggleDark;

  /// 로그아웃 콜백(토큰 삭제 + 인증 화면 복귀). 나 탭 → 설정에서 호출.
  final VoidCallback onLogout;

  /// 프로필(닉네임) 저장 콜백(서버 PATCH, 이슈 #56).
  final Future<void> Function(String nickname) onUpdateProfile;

  /// 회원 탈퇴 콜백(DELETE → 로그아웃, 이슈 #56).
  final Future<void> Function() onWithdraw;

  /// 현재 연동된 provider 이름 집합(예: {'email','google','kakao'}, 이슈 #10).
  final Set<String> linkedProviders;

  /// 소셜 계정 연결 콜백(linkIdentity, 브라우저+딥링크). null 이면 연동 섹션 비노출.
  final Future<void> Function(SocialProvider provider)? onLinkAccount;

  /// 소셜 계정 연결 해제 콜백(unlinkIdentity).
  final Future<void> Function(SocialProvider provider)? onUnlinkAccount;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

/// 서브화면(탭 위에 덮어 표시).
enum _Sub { none, debt, focus, calendar }

class _MainScaffoldState extends State<MainScaffold>
    with WidgetsBindingObserver {
  DkTab _tab = DkTab.today;
  _Sub _sub = _Sub.none;
  final GlobalKey<DkToastHostState> _toastKey = GlobalKey<DkToastHostState>();

  /// Google 캘린더 OAuth 를 외부 브라우저로 시작했는지(복귀 시 연결 재로딩 트리거, 이슈 #9).
  bool _pendingCalendarConnect = false;

  /// 집중 탭에 연결된 태스크.
  DkTask? _linkedTask;

  /// 외부 캘린더 연동 상태(이슈 #59). server /calendar/* 에서 로드, 실패 시 빈 목록(graceful).
  List<DkCalendarConnection> _connections = const <DkCalendarConnection>[];
  List<DkExternal> _externals = const <DkExternal>[];
  bool _syncing = false;

  DataController get _c => widget.controller;
  NotifController get _n => widget.notif;
  SettingsController get _s => widget.settings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _c.addListener(_onData);
    _n.addListener(_onData);
    _s.addListener(_onData);
    // 진입 시 서버 데이터·알림·설정 로드(인증 게이트가 main 진입을 보장).
    _c.load();
    _n.load();
    _s.load();
    _loadCalendar();
  }

  /// 외부 캘린더 연결·일정을 server 에서 로드한다(이슈 #59). 실패해도 앱 일정만으로 동작(graceful).
  Future<void> _loadCalendar() async {
    try {
      final List<DkCalendarConnection> connections = await _c.repository
          .calendarConnections();
      final List<DkExternal> externals = await _c.repository
          .externalEventsRange(from: _calendarFrom, to: _calendarTo);
      if (!mounted) return;
      setState(() {
        _connections = connections;
        _externals = externals;
      });
    } on ApiException {
      // 연동 미설정/네트워크 — 앱 일정만 표시(외부 일정 비움).
      if (mounted) setState(() => _externals = const <DkExternal>[]);
    }
  }

  /// 외부 일정 조회 창(오늘 기준 과거 30일 ~ 미래 120일). server 동기화 창과 정렬.
  String get _calendarFrom =>
      ymd(DateTime.now().subtract(const Duration(days: 30)));
  String get _calendarTo => ymd(DateTime.now().add(const Duration(days: 120)));

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.removeListener(_onData);
    _n.removeListener(_onData);
    _s.removeListener(_onData);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 서버 주도 OAuth 후 브라우저→앱 복귀 시 연결 상태를 다시 읽는다(이슈 #9 Phase B).
    if (state == AppLifecycleState.resumed && _pendingCalendarConnect) {
      _pendingCalendarConnect = false;
      _loadCalendar();
    }
  }

  void _onData() {
    if (mounted) setState(() {});
  }

  void _toast(String message, {String? icon, DkTone? tone}) {
    _toastKey.currentState?.show(DkToastData(message, icon: icon, tone: tone));
  }

  void _toastNamed(String message, String icon, String tone) {
    _toast(message, icon: icon, tone: _toneFromName(tone));
  }

  DkTone _toneFromName(String name) => switch (name) {
    'success' => DkTone.success,
    'warning' => DkTone.warning,
    'danger' => DkTone.danger,
    'info' => DkTone.info,
    'primary' => DkTone.primary,
    _ => DkTone.neutral,
  };

  /// 쓰기 작업 공통 래퍼: 성공/실패 토스트. 오류는 ApiException 메시지를 그대로 보여준다.
  Future<void> _run(
    Future<void> Function() action, {
    required String success,
    String successIcon = 'check',
    DkTone successTone = DkTone.success,
  }) async {
    try {
      await action();
      _toast(success, icon: successIcon, tone: successTone);
    } on ApiException catch (e) {
      _toast(e.message, icon: 'x', tone: DkTone.danger);
    } on Exception {
      // 네트워크/파싱 등 ApiException 외 예외도 사용자에게 알린다(조용한 실패 방지).
      _toast('문제가 생겼어요. 잠시 후 다시 시도해 주세요.', icon: 'x', tone: DkTone.danger);
    }
  }

  Future<void> _toggleTask(DkTask task) async {
    final bool willBeDone = task.state != DkTaskState.done;
    await _run(
      () => _c.toggleComplete(task),
      success: willBeDone ? '완료했어요. 잘했어요!' : '완료를 취소했어요',
      successIcon: willBeDone ? 'check' : 'reset',
      successTone: willBeDone ? DkTone.success : DkTone.neutral,
    );
  }

  Future<void> _completeTask(DkTask task) async {
    await _run(
      () => _c.toggleComplete(task.copyWith(state: DkTaskState.today)),
      success: '‘${task.title}’ 완료!',
    );
  }

  void _startFocus(DkTask task) {
    setState(() {
      _linkedTask = task;
      _sub = _Sub.focus; // 집중은 더 이상 탭이 아니라 서브화면(뽀모도로)
    });
    _toast('집중 타이머에 연결했어요', icon: 'focus', tone: DkTone.primary);
  }

  void _openTaskSheet(DkTask task) {
    showTaskSheet(
      context,
      task: task,
      isNew: false,
      onToggle: _toggleTask,
      onDelete: (DkTask t) => _run(
        () => _c.deleteTask(t.id),
        success: '태스크를 삭제했어요',
        successIcon: 'trash',
        successTone: DkTone.danger,
      ),
      onSubmit: (DkTask draft) =>
          _run(() => _c.updateTask(draft), success: '태스크를 저장했어요'),
      onFocus: _startFocus,
      onCarry: (DkTask t, String toDate) => _run(
        () => _c.carryTask(t.id, toDate: toDate),
        success: '${fmtDate(toDate)}로 옮겼어요',
        successIcon: 'repeat',
        successTone: DkTone.info,
      ),
      onToast: _toastNamed,
    );
  }

  void _addTask() {
    showTaskSheet(
      context,
      isNew: true,
      onToast: _toastNamed,
      onSubmit: (DkTask draft) => _run(
        () => _c.createTask(draft),
        success: '태스크를 추가했어요',
        successIcon: 'plus',
        successTone: DkTone.primary,
      ),
    );
  }

  void _openEventSheet(DkEvent ev) {
    showEventSheet(
      context,
      event: ev,
      isNew: false,
      onDelete: (DkEvent e) => _run(
        () => _c.deleteEvent(e.id),
        success: '이벤트를 삭제했어요',
        successIcon: 'trash',
        successTone: DkTone.danger,
      ),
      onSubmit: (DkEvent draft) =>
          _run(() => _c.updateEvent(draft), success: '이벤트를 저장했어요'),
    );
  }

  void _addEvent() {
    showEventSheet(
      context,
      isNew: true,
      onSubmit: (DkEvent draft) => _run(
        () => _c.createEvent(draft),
        success: '이벤트를 추가했어요',
        successIcon: 'plus',
        successTone: DkTone.primary,
      ),
    );
  }

  /// 알림 시트 열기. 열람 시 안읽음을 모두 읽음 처리(벨 점 해소)하고,
  /// 항목 탭 시에도 개별 읽음 처리한다. 실패는 조용히 무시(다음 load 가 보정).
  void _openNotif() {
    showNotifSheet(
      context,
      _n,
      onTapItem: (DkNotif item) => _markReadSilently(item.id),
    );
    _markAllReadSilently();
  }

  Future<void> _markAllReadSilently() async {
    try {
      await _n.markAllRead();
    } on ApiException {
      // 벨 점 보정은 다음 load 에서. 시트 열람 흐름을 막지 않는다.
    }
  }

  Future<void> _markReadSilently(String id) async {
    try {
      await _n.markRead(id);
    } on ApiException {
      // 무시(낙관적 갱신은 롤백되며 다음 load 가 보정).
    }
  }

  void _openCalc() => showCalcSheet(context);

  // ── 외부 캘린더 연동(이슈 #59) ────────────────────────────
  void _openCalendarSync() => setState(() => _sub = _Sub.calendar);

  /// Google 캘린더 연결: 서버 주도 OAuth(이슈 #9 Phase B). 서버에서 동의 URL 을 받아 외부
  /// 브라우저로 열고, 완료 후 딥링크로 앱에 복귀하면 [didChangeAppLifecycleState] 가 연결을
  /// 재로딩한다. (서버가 토큰을 보유하므로 앱은 placeholder 토큰을 보내지 않는다.)
  Future<void> _connectCalendar(DkSource source) async {
    try {
      final String url = await _c.repository.googleCalendarConnectUrl();
      // 서버 응답 URL 이라도 외부 실행 전 scheme·host 를 검증한다(침해/MITM 시 비-https
      // 또는 임의 host 로의 실행 방지, S2). 동의 화면은 항상 Google 호스트다.
      final Uri? parsed = Uri.tryParse(url);
      if (parsed == null ||
          parsed.scheme != 'https' ||
          !kAllowedCalendarAuthHosts.contains(parsed.host)) {
        _toast('유효하지 않은 연동 URL이에요', icon: 'x', tone: DkTone.danger);
        return;
      }
      final bool launched = await launchUrl(
        parsed,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _toast('브라우저를 열 수 없어요', icon: 'x', tone: DkTone.danger);
        return;
      }
      _pendingCalendarConnect = true;
      _toast('브라우저에서 Google 로그인을 완료해 주세요', icon: 'repeat', tone: DkTone.info);
    } on ApiException catch (e) {
      _toast(e.message, icon: 'x', tone: DkTone.danger);
    }
  }

  Future<void> _disconnectCalendar(DkSource source) async {
    await _run(
      () async {
        await _c.repository.disconnectCalendar(source);
        await _loadCalendar();
      },
      success: '${sourceMeta(source).label} 연결을 해제했어요',
      successIcon: 'x',
      successTone: DkTone.warning,
    );
  }

  Future<void> _syncCalendars() async {
    setState(() => _syncing = true);
    try {
      await _c.repository.syncCalendars();
      await _loadCalendar();
      _toast('외부 일정을 동기화했어요', icon: 'repeat', tone: DkTone.info);
    } on ApiException catch (e) {
      _toast(e.message, icon: 'x', tone: DkTone.danger);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  /// 안드로이드 시스템 뒤로가기 처리(이슈 #54). 서브화면이 열려 있으면 닫고, 그 외엔
  /// today 가 아닌 탭이면 today 로 복귀한다. today + 서브 없음일 때만 앱 종료를 허용한다.
  void _handleBack() {
    if (_sub != _Sub.none) {
      setState(() => _sub = _Sub.none);
    } else if (_tab != DkTab.today) {
      setState(() => _tab = DkTab.today);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _sub == _Sub.none && _tab == DkTab.today,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _handleBack();
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final DkTokens t = DkTheme.of(context);

    if (_sub != _Sub.none) {
      return Container(color: t.page, child: _buildSub());
    }

    final bool empty = _c.tasks.isEmpty && _c.events.isEmpty;

    // 초기 로딩(데이터 없음): 밋밋한 텍스트 대신 콘텐츠 윤곽 스켈레톤(토스·당근 패턴).
    if (_c.isLoading && empty) {
      return const AppLoadingSkeleton();
    }
    if (_c.error != null && empty) {
      return Container(color: t.page, child: _errorState(t));
    }

    return Container(
      color: t.page,
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              // FAB 는 본문(탭바 위) 영역 안에 둔다 → 하단 탭바를 절대 가리지 않고,
              // 본문 스크롤의 bottom 패딩이 콘텐츠 가림도 막는다(이슈: FAB 겹침).
              Expanded(
                child: Stack(
                  children: <Widget>[
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: KeyedSubtree(
                        key: ValueKey<DkTab>(_tab),
                        child: _buildTabBody(),
                      ),
                    ),
                  ],
                ),
              ),
              DkTabBar(
                active: _tab,
                onChanged: (DkTab tb) => setState(() => _tab = tb),
                onAdd: _addTask,
              ),
            ],
          ),
          DkToastHost(key: _toastKey),
        ],
      ),
    );
  }

  Widget _errorState(DkTokens t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DkEmpty(
              icon: 'alert',
              title: '데이터를 불러오지 못했어요',
              body: _c.error ?? '잠시 후 다시 시도해 주세요.',
            ),
            const SizedBox(height: 16),
            DkButton(
              size: DkButtonSize.lg,
              onPressed: _c.load,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSub() {
    switch (_sub) {
      case _Sub.debt:
        return DebtScreen(
          debts: _c.debts,
          onBack: () => setState(() => _sub = _Sub.none),
          onAutoCarry: (DkDebt d) => _run(
            () => _c.autoCarryDebt(d.id),
            success: '가장 여유 있는 날로 옮겼어요',
            successIcon: 'repeat',
            successTone: DkTone.info,
          ),
          onAbandon: (DkDebt d) => _run(
            () => _c.abandonDebt(d.id),
            success: '이 일을 내려놓았어요. 기록은 남겨둘게요',
            successIcon: 'x',
            successTone: DkTone.warning,
          ),
        );
      case _Sub.focus:
        return FocusScreen(
          focusStats: _focusStats(),
          settings: _s.settings,
          onSaveSettings: _saveSettings,
          linkedTask: _linkedTask,
          unread: _n.unreadCount,
          onClearTask: () => setState(() => _linkedTask = null),
          onBell: _openNotif,
          onCompleteTask: _completeTask,
          onToast: _toastNamed,
          onBack: () => setState(() {
            _sub = _Sub.none;
            _linkedTask = null;
          }),
        );
      case _Sub.calendar:
        return CalendarSyncScreen(
          connections: _connections,
          syncing: _syncing,
          onBack: () => setState(() => _sub = _Sub.none),
          onConnect: _connectCalendar,
          onDisconnect: _disconnectCalendar,
          onSync: _syncCalendars,
        );
      case _Sub.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTabBody() {
    final int unread = _n.unreadCount;
    switch (_tab) {
      case DkTab.today:
        return TodayScreen(
          userName: widget.user.nickname,
          events: _c.events,
          debts: _c.debts,
          unread: unread,
          onOpenEvent: _openEventSheet,
          onBell: _openNotif,
          onOpenCalc: _openCalc,
          onOpenDebt: () => setState(() => _sub = _Sub.debt),
        );
      case DkTab.plan:
        return PlanScreen(
          tasks: _c.tasks,
          events: _c.events,
          // 외부 일정은 server /calendar/external 에서 로드(이슈 #59).
          // 연결 0이면 빈 목록 → 앱 일정만 표시(graceful).
          externals: _externals,
          summary: _weekSummary(),
          debtTotal: _debtTotal(),
          debtOverdue: _debtOverdue(),
          unread: unread,
          onToggle: _toggleTask,
          onOpenTask: _openTaskSheet,
          onOpenEvent: _openEventSheet,
          onAddTask: _addTask,
          onAddEvent: _addEvent,
          onOpenDebt: () => setState(() => _sub = _Sub.debt),
          onBell: _openNotif,
        );
      case DkTab.stats:
        return ReviewScreen(review: _weekReview(), streak: _streakDays());
      case DkTab.me:
        return MeScreen(
          user: widget.user,
          summary: _weekSummary(),
          streak: _streakDays(),
          focusStats: _focusStats(),
          settings: _s.settings,
          dark: widget.dark,
          unread: unread,
          onToggleDark: widget.onToggleDark,
          onBell: _openNotif,
          onOpenCalc: _openCalc,
          onOpenFocus: () => setState(() => _sub = _Sub.focus),
          onOpenCalendar: _openCalendarSync,
          onStub: () => _toast(kComingSoonMessage, icon: 'sparkle'),
          onLogout: widget.onLogout,
          onUpdateProfile: _updateProfile,
          onSaveSettings: _saveSettings,
          onWithdraw: _withdraw,
          linkedProviders: widget.linkedProviders,
          onLinkAccount: widget.onLinkAccount,
          onUnlinkAccount: widget.onUnlinkAccount,
        );
    }
  }

  /// 프로필(닉네임) 저장: 성공/실패 토스트. 실패 시 ApiException 메시지를 보여준다.
  Future<void> _updateProfile(String nickname) =>
      _run(() => widget.onUpdateProfile(nickname), success: '프로필을 저장했어요');

  /// 설정 저장(낙관적): 실패 시 롤백되며 토스트로 안내한다.
  Future<void> _saveSettings(DkSettings next) async {
    try {
      await _s.save(next);
    } on ApiException catch (e) {
      _toast(e.message, icon: 'x', tone: DkTone.danger);
    }
  }

  /// 회원 탈퇴 확정: 서버 DELETE → 로그아웃(인증 화면). 실패 시 토스트.
  Future<void> _withdraw() async {
    try {
      await widget.onWithdraw();
    } on ApiException catch (e) {
      _toast(e.message, icon: 'x', tone: DkTone.danger);
    }
  }

  int _debtTotal() => _c.debts.fold(0, (int s, DkDebt d) => s + d.mins);

  int _debtOverdue() =>
      _c.debts.where((DkDebt d) => d.status == DkDebtStatus.overdue).length;

  // ── 통계: 서버 주간/집중/스트릭 엔드포인트가 없어 목 상수를 쓰지 않고,
  //     로드된 실제 task 에서 계산하거나 0 으로 둔다(하드코딩 제거). ──

  /// 주간 요약: 실제 task 의 전체/완료 수 + 미룬 시간 합계로 계산.
  DkWeekSummary _weekSummary() =>
      buildPlanSummary(tasks: _c.tasks, debtMinutes: _debtTotal());

  /// 집중 통계: 집중 기록 저장/조회 기능이 아직 없어 0(목표는 기본 상수).
  DkFocusStats _focusStats() => const DkFocusStats(
    todaySessions: 0,
    todayMinutes: 0,
    goal: kDefaultFocusGoal,
  );

  /// 연속 달성(스트릭): 이력 데이터가 없어 0.
  int _streakDays() => 0;

  /// 주간 리뷰: 서버 엔드포인트가 없어 목 상수 대신 로드된 실제 task/debt 에서 파생한다.
  DkWeekReview _weekReview() =>
      buildWeekReview(tasks: _c.tasks, debts: _c.debts);
}
