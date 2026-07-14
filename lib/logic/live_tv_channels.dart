/// Danh sach kenh video cho man "Truc tiep". Dung [video_player] phat thang
/// stream HLS (.m3u8) / MP4 — KHONG qua YouTube (YouTube chan nhung video
/// ban quyen bong da).
///
/// [url] la link stream truc tiep. Muon doi noi dung (vd link truc tiep tran
/// dau ban co ban quyen), chi thay [url] o day — khong dung sua UI. Stream
/// phai cho phep truy cap truc tiep (hotlink) va la dinh dang ExoPlayer doc
/// duoc (HLS / MP4 H.264).
class LiveTvChannel {
  final String url;
  final String title;
  final String subtitle;
  final bool isLive; // stream truc tiep that (hien nhan "LIVE")
  const LiveTvChannel({
    required this.url,
    required this.title,
    required this.subtitle,
    this.isLive = false,
  });
}

/// Kenh demo (stream cong khai, on dinh, cho hotlink). Thay url bang nguon
/// cua ban khi trinh dien.
const List<LiveTvChannel> kLiveTvChannels = [
  LiveTvChannel(
    url:
        'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8',
    title: 'Kênh Trực Tiếp',
    subtitle: 'Đang phát',
    isLive: true,
  ),
  LiveTvChannel(
    url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
    title: 'Kênh Thể Thao',
    subtitle: 'Phát lại',
  ),
];
