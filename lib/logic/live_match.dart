import 'dart:math';

/// 1 su kien trong tran dang da (ban thang, the phat...).
class LiveEvent {
  final int minute;
  final String text;
  const LiveEvent(this.minute, this.text);
}

/// Tran dang da (hoac da ket thuc) de hien thi — KHONG dung de cuoc.
/// homeFlag/awayFlag: emoji co hoac duong dan asset, co the de trong.
class LiveMatch {
  final String home;
  final String away;
  final String homeFlag;
  final String awayFlag;
  int homeGoals;
  int awayGoals;
  int minute;
  final bool isLive; // dang da
  final String status; // 'LIVE' | 'HT' | 'FT' | 'NS'
  final List<LiveEvent> events;

  LiveMatch({
    required this.home,
    required this.away,
    this.homeFlag = '',
    this.awayFlag = '',
    this.homeGoals = 0,
    this.awayGoals = 0,
    this.minute = 0,
    this.isLive = true,
    this.status = 'LIVE',
    List<LiveEvent>? events,
  }) : events = events ?? [];

  /// Tran "fake live" mac dinh khi khong co API key hoac khong co tran that.
  factory LiveMatch.demo() {
    return LiveMatch(
      home: 'Việt Nam',
      away: 'Thái Lan',
      homeFlag: '🇻🇳',
      awayFlag: '🇹🇭',
      homeGoals: 1,
      awayGoals: 0,
      minute: 34,
      isLive: true,
      status: 'LIVE',
      events: const [
        LiveEvent(12, 'Bàn thắng! Việt Nam vươn lên dẫn trước 1-0'),
        LiveEvent(29, 'Thẻ vàng cho Thái Lan'),
      ],
    );
  }

  /// Tien vai phut (2-5) va thinh thoang them su kien moi. Thuan/deterministic
  /// theo Random truyen vao — dung cho timer cua man hinh.
  static LiveMatch tickDemo(LiveMatch m, Random rng) {
    if (!m.isLive) return m;
    final nextMinute = m.minute + 2 + rng.nextInt(4);

    if (nextMinute >= 90) {
      return LiveMatch(
        home: m.home,
        away: m.away,
        homeFlag: m.homeFlag,
        awayFlag: m.awayFlag,
        homeGoals: m.homeGoals,
        awayGoals: m.awayGoals,
        minute: 90,
        isLive: false,
        status: 'FT',
        events: [...m.events, LiveEvent(90, 'Kết thúc trận đấu')],
      );
    }

    var homeGoals = m.homeGoals;
    var awayGoals = m.awayGoals;
    final events = [...m.events];

    // ~18% co su kien moi moi lan tick
    if (rng.nextDouble() < 0.18) {
      final roll = rng.nextDouble();
      if (roll < 0.4) {
        homeGoals++;
        events.add(LiveEvent(nextMinute,
            'Bàn thắng! ${m.home} ghi bàn, tỉ số $homeGoals-$awayGoals'));
      } else if (roll < 0.8) {
        awayGoals++;
        events.add(LiveEvent(nextMinute,
            'Bàn thắng! ${m.away} ghi bàn, tỉ số $homeGoals-$awayGoals'));
      } else {
        final team = rng.nextBool() ? m.home : m.away;
        events.add(LiveEvent(nextMinute, 'Thẻ vàng cho $team'));
      }
    }

    return LiveMatch(
      home: m.home,
      away: m.away,
      homeFlag: m.homeFlag,
      awayFlag: m.awayFlag,
      homeGoals: homeGoals,
      awayGoals: awayGoals,
      minute: nextMinute,
      isLive: true,
      status: nextMinute >= 45 && nextMinute < 47 ? 'HT' : 'LIVE',
      events: events,
    );
  }
}
