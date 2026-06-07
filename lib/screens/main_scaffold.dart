import 'package:flutter/widgets.dart';

import '../data/api/api_exception.dart';
import '../data/api/auth_dto.dart';
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
import '../widgets/dk_fab.dart';
import '../widgets/dk_feedback.dart';
import '../widgets/dk_tab_bar.dart';
import 'calc_sheet.dart';
import 'debt/debt_screen.dart';
import 'focus/focus_screen.dart';
import 'me/calendar_sync_screen.dart';
import 'me/me_screen.dart';
import 'plan/plan_screen.dart';
import 'review/review_screen.dart';
import 'sheets/event_sheet.dart';
import 'sheets/notif_sheet.dart';
import 'sheets/task_sheet.dart';
import 'today/today_screen.dart';

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

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

/// 서브화면(탭 위에 덮어 표시).
enum _Sub { none, debt, review, calendar }

class _MainScaffoldState extends State<MainScaffold> {
  DkTab _tab = DkTab.today;
  _Sub _sub = _Sub.none;
  final GlobalKey<DkToastHostState> _toastKey = GlobalKey<DkToastHostState>();

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
    _c.removeListener(_onData);
    _n.removeListener(_onData);
    _s.removeListener(_onData);
    super.dispose();
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
      _tab = DkTab.focus;
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

  /// provider 연결(토큰 등록). 본 트랙은 소셜 토큰 미보유 시 데모 placeholder 로 등록한다
  /// (server 는 토큰을 저장만 하고 동기화 때 검증 — 실패 시 SYNC_FAILED). 성공 후 재로딩.
  Future<void> _connectCalendar(DkSource source) async {
    await _run(
      () async {
        await _c.repository.connectCalendar(
          source,
          accessToken: 'demo-token-placeholder',
        );
        await _loadCalendar();
      },
      success: '${sourceMeta(source).label} 캘린더를 연결했어요',
      successIcon: 'check',
    );
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

  bool get _showsFab => _tab == DkTab.today || _tab == DkTab.plan;

  @override
  Widget build(BuildContext context) {
    final DkTokens t = DkTheme.of(context);

    if (_sub != _Sub.none) {
      return Container(color: t.page, child: _buildSub());
    }

    final bool empty = _c.tasks.isEmpty && _c.events.isEmpty;

    // 초기 로딩(데이터 없음) / 오류 게이트.
    if (_c.isLoading && empty) {
      return Container(
        color: t.page,
        alignment: Alignment.center,
        child: Text(
          '불러오는 중…',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: t.fgMuted,
          ),
        ),
      );
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
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: KeyedSubtree(
                    key: ValueKey<DkTab>(_tab),
                    child: _buildTabBody(),
                  ),
                ),
              ),
              DkTabBar(
                active: _tab,
                onChanged: (DkTab tb) => setState(() => _tab = tb),
              ),
            ],
          ),
          if (_showsFab)
            Positioned(
              right: 18,
              bottom: 92,
              child: DkFab(onPressed: _addTask),
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
      case _Sub.review:
        return ReviewScreen(
          review: _c.repository.weekReview(),
          streak: _c.repository.streak(),
          onBack: () => setState(() => _sub = _Sub.none),
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
          tasks: _c.tasks,
          events: _c.events,
          debts: _c.debts,
          unread: unread,
          onToggle: _toggleTask,
          onOpenTask: _openTaskSheet,
          onOpenEvent: _openEventSheet,
          onAddTask: _addTask,
          onBell: _openNotif,
          onOpenCalc: _openCalc,
          onFocus: _startFocus,
          onOpenDebt: () => setState(() => _sub = _Sub.debt),
        );
      case DkTab.plan:
        return PlanScreen(
          tasks: _c.tasks,
          events: _c.events,
          // 외부 일정은 server /calendar/external 에서 로드(이슈 #59).
          // 연결 0이면 빈 목록 → 앱 일정만 표시(graceful).
          externals: _externals,
          summary: _c.repository.weekSummary(),
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
      case DkTab.focus:
        return FocusScreen(
          pomodoro: _c.repository.pomodoro(),
          focusStats: _c.repository.focusStats(),
          linkedTask: _linkedTask,
          unread: unread,
          onClearTask: () => setState(() => _linkedTask = null),
          onBell: _openNotif,
          onCompleteTask: _completeTask,
          onToast: _toastNamed,
        );
      case DkTab.me:
        return MeScreen(
          user: widget.user,
          summary: _c.repository.weekSummary(),
          streak: _c.repository.streak(),
          focusStats: _c.repository.focusStats(),
          settings: _s.settings,
          dark: widget.dark,
          unread: unread,
          onToggleDark: widget.onToggleDark,
          onBell: _openNotif,
          onOpenCalc: _openCalc,
          onOpenReview: () => setState(() => _sub = _Sub.review),
          onOpenCalendar: _openCalendarSync,
          onStub: () => _toast('곧 제공될 기능이에요', icon: 'sparkle'),
          onLogout: widget.onLogout,
          onUpdateProfile: _updateProfile,
          onSaveSettings: _saveSettings,
          onWithdraw: _withdraw,
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
}
