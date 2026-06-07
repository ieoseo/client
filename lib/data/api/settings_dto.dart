import 'package:flutter/foundation.dart';

/// 사용자 설정(서버 연동, 이슈 #56). `docs/05-API/auth.md` GET/PUT /auth/me/settings.
///
/// 다크모드는 클라이언트 로컬 테마(TweakSettings)로 유지하므로 서버 설정에 포함하지 않는다.
@immutable
class DkSettings {
  const DkSettings({
    this.autoCarry = true,
    this.dayDeadlineHour = 0,
    this.weekStart = 'MON',
    this.maxDailyMinutes = 480,
    this.pomodoroFocus = 25,
    this.pomodoroShortBreak = 5,
    this.pomodoroLongBreak = 15,
    this.completionSound = true,
  });

  /// 자동 이월(미룬 시간) ON/OFF.
  final bool autoCarry;

  /// 하루 마감 시각(시, 0~23).
  final int dayDeadlineHour;

  /// 주간 시작 요일(`MON`/`SUN`).
  final String weekStart;

  /// 하루 최대 예약 시간(분).
  final int maxDailyMinutes;

  /// 포모도로 집중 길이(분).
  final int pomodoroFocus;

  /// 포모도로 짧은 휴식(분).
  final int pomodoroShortBreak;

  /// 포모도로 긴 휴식(분).
  final int pomodoroLongBreak;

  /// 완료음 ON/OFF.
  final bool completionSound;

  factory DkSettings.fromJson(Map<String, dynamic> json) => DkSettings(
    autoCarry: json['autoCarry'] as bool? ?? true,
    dayDeadlineHour: (json['dayDeadlineHour'] as num?)?.toInt() ?? 0,
    weekStart: (json['weekStart'] as String?) ?? 'MON',
    maxDailyMinutes: (json['maxDailyMinutes'] as num?)?.toInt() ?? 480,
    pomodoroFocus: (json['pomodoroFocus'] as num?)?.toInt() ?? 25,
    pomodoroShortBreak: (json['pomodoroShortBreak'] as num?)?.toInt() ?? 5,
    pomodoroLongBreak: (json['pomodoroLongBreak'] as num?)?.toInt() ?? 15,
    completionSound: json['completionSound'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'autoCarry': autoCarry,
    'dayDeadlineHour': dayDeadlineHour,
    'weekStart': weekStart,
    'maxDailyMinutes': maxDailyMinutes,
    'pomodoroFocus': pomodoroFocus,
    'pomodoroShortBreak': pomodoroShortBreak,
    'pomodoroLongBreak': pomodoroLongBreak,
    'completionSound': completionSound,
  };

  DkSettings copyWith({
    bool? autoCarry,
    int? dayDeadlineHour,
    String? weekStart,
    int? maxDailyMinutes,
    int? pomodoroFocus,
    int? pomodoroShortBreak,
    int? pomodoroLongBreak,
    bool? completionSound,
  }) => DkSettings(
    autoCarry: autoCarry ?? this.autoCarry,
    dayDeadlineHour: dayDeadlineHour ?? this.dayDeadlineHour,
    weekStart: weekStart ?? this.weekStart,
    maxDailyMinutes: maxDailyMinutes ?? this.maxDailyMinutes,
    pomodoroFocus: pomodoroFocus ?? this.pomodoroFocus,
    pomodoroShortBreak: pomodoroShortBreak ?? this.pomodoroShortBreak,
    pomodoroLongBreak: pomodoroLongBreak ?? this.pomodoroLongBreak,
    completionSound: completionSound ?? this.completionSound,
  );

  @override
  bool operator ==(Object other) =>
      other is DkSettings &&
      other.autoCarry == autoCarry &&
      other.dayDeadlineHour == dayDeadlineHour &&
      other.weekStart == weekStart &&
      other.maxDailyMinutes == maxDailyMinutes &&
      other.pomodoroFocus == pomodoroFocus &&
      other.pomodoroShortBreak == pomodoroShortBreak &&
      other.pomodoroLongBreak == pomodoroLongBreak &&
      other.completionSound == completionSound;

  @override
  int get hashCode => Object.hash(
    autoCarry,
    dayDeadlineHour,
    weekStart,
    maxDailyMinutes,
    pomodoroFocus,
    pomodoroShortBreak,
    pomodoroLongBreak,
    completionSound,
  );
}
