/// Danh sach kenh video bong da cho man "Truc tiep". Dung [video_player] phat
/// clip bong da that dong goi trong app (assets/videos) — KHONG qua YouTube va
/// khong phu thuoc mang (nhung stream single-file hay bi loi Range 416).
///
/// Nguon clip: Wikimedia Commons (bong da that, giay phep tu do). Muon them
/// kenh: bo file .webm/.mp4 vao assets/videos/ roi them dong o day.
class LiveTvChannel {
  final String asset; // duong dan asset video trong app
  final String title;
  final String subtitle;
  final bool isLive; // hien nhan "LIVE"
  const LiveTvChannel({
    required this.asset,
    required this.title,
    required this.subtitle,
    this.isLive = false,
  });
}

/// Nhieu kenh bong da that de chuyen tab.
const List<LiveTvChannel> kLiveTvChannels = [
  LiveTvChannel(
    asset: 'assets/videos/dynamo_penalty.webm',
    title: 'Dynamo — Partizan',
    subtitle: 'Cúp châu Âu • Phạt đền',
    isLive: true,
  ),
  LiveTvChannel(
    asset: 'assets/videos/fifa_u17.webm',
    title: 'FIFA U-17 Nữ',
    subtitle: 'New Zealand — Canada',
    isLive: true,
  ),
  LiveTvChannel(
    asset: 'assets/videos/derby_goal.webm',
    title: 'Bàn thắng đẹp',
    subtitle: 'Derby County — Blackburn',
  ),
  LiveTvChannel(
    asset: 'assets/videos/training.webm',
    title: 'Sân tập',
    subtitle: 'Buổi tập bóng đá',
  ),
];
