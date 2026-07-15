import 'dart:math';

/// Mot tran o muc "Truc tiep": clip video bong da that (assets/videos) + thong
/// tin tran (doi, giai, ty so, phut). Bam "Xem" -> mo trinh phat.
class LiveTvMatch {
  final String videoAsset;
  final String home;
  final String away;
  final String competition;
  final int homeScore;
  final int awayScore;
  final int minute; // phut khoi tao khi mo app
  final bool isLive; // dang da (nhan LIVE + phut chay) hay phat lai
  final List<String> events; // dong dien bien, moi nhat truoc

  const LiveTvMatch({
    required this.videoAsset,
    required this.home,
    required this.away,
    required this.competition,
    this.homeScore = 0,
    this.awayScore = 0,
    this.minute = 0,
    this.isLive = true,
    this.events = const [],
  });
}

/// Trang thai chay cua 1 tran — phut/ty so tang dan cho danh sach sinh dong.
class LiveMatchRun {
  final LiveTvMatch seed;
  int minute;
  int homeScore;
  int awayScore;
  final List<String> events;

  LiveMatchRun(this.seed)
      : minute = seed.minute,
        homeScore = seed.homeScore,
        awayScore = seed.awayScore,
        events = [...seed.events];

  /// Tien 1 phut; thinh thoang co ban thang moi -> nhin nhu tran that.
  void tick(Random rng) {
    if (!seed.isLive || minute >= 90) return;
    minute += 1;
    if (homeScore + awayScore < 6 && rng.nextDouble() < 0.05) {
      final home = rng.nextBool();
      if (home) {
        homeScore++;
      } else {
        awayScore++;
      }
      events.insert(0,
          "$minute' Bàn thắng! ${home ? seed.home : seed.away} ghi bàn ($homeScore-$awayScore)");
    }
  }

  String get score => '$homeScore - $awayScore';
}

/// 4 tran demo, gan voi 4 clip bong da that trong assets/videos.
const List<LiveTvMatch> kLiveMatches = [
  LiveTvMatch(
    videoAsset: 'assets/videos/dynamo_penalty.webm',
    home: 'Dynamo Kyiv',
    away: 'Partizan',
    competition: 'UEFA Europa League',
    homeScore: 1,
    awayScore: 1,
    minute: 58,
    events: [
      "40' Bàn thắng! Partizan gỡ hòa (1-1)",
      "12' Bàn thắng! Dynamo Kyiv mở tỉ số (1-0)",
    ],
  ),
  LiveTvMatch(
    videoAsset: 'assets/videos/fifa_u17.webm',
    home: 'New Zealand',
    away: 'Canada',
    competition: 'FIFA U-17 World Cup Nữ',
    homeScore: 0,
    awayScore: 2,
    minute: 63,
    events: [
      "50' Bàn thắng! Canada nhân đôi cách biệt (0-2)",
      "23' Bàn thắng! Canada mở tỉ số (0-1)",
    ],
  ),
  LiveTvMatch(
    videoAsset: 'assets/videos/derby_goal.webm',
    home: 'Derby County',
    away: 'Blackburn',
    competition: "FA Women's Cup",
    homeScore: 1,
    awayScore: 0,
    minute: 74,
    events: ["31' Bàn thắng! Derby County dẫn trước (1-0)"],
  ),
  LiveTvMatch(
    videoAsset: 'assets/videos/training.webm',
    home: 'Học viện trẻ',
    away: 'Buổi tập',
    competition: 'Highlight • Sân tập',
    isLive: false,
  ),
];
