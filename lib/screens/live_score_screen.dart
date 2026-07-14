import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../logic/live_match.dart';
import '../logic/live_tv_channels.dart';
import '../services/live_score_service.dart';
import '../theme/brand_colors.dart';
import '../widgets/live_tv_player.dart';
import '../widgets/motion_effects.dart';

/// Man hinh ty so truc tiep — CHI XEM, khong dung de dat cuoc. Vao tu icon
/// live_tv tren AppBar cua SportsbookScreen (push, khong phai tab) de Timer
/// chi chay khi man hinh dang mo, huy khi pop.
class LiveScoreScreen extends StatefulWidget {
  /// Tat khoi video YouTube (WebView) — dat false trong widget test vi
  /// WebView khong khoi tao duoc trong moi truong flutter test.
  final bool enableLiveTv;
  const LiveScoreScreen({super.key, this.enableLiveTv = true});

  @override
  State<LiveScoreScreen> createState() => _LiveScoreScreenState();
}

class _LiveScoreScreenState extends State<LiveScoreScreen> {
  List<LiveMatch> _matches = [];
  bool _loading = true;
  Timer? _timer;
  int _tickCount = 0;
  final _rng = Random();

  // Trinh phat video cho khoi "Xem truc tiep (TV)". Null khi enableLiveTv=false.
  VideoPlayerController? _video;
  bool _videoReady = false;
  int _channelIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.enableLiveTv) {
      _openChannel(0);
    }
    // Moi 4s: neu la du lieu demo (1 tran, dang da, khong co API key that)
    // -> tick cho tran demo tien trien. Cu ~10 tick (~40s) goi lai _load()
    // mot lan de mo phong polling du lieu that.
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _onTick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _video?.dispose();
    super.dispose();
  }

  bool get _isDemoMode =>
      _matches.length == 1 && _matches.first.home == 'Việt Nam';

  Future<void> _load() async {
    final matches = await LiveScoreService.instance.fetchLive();
    if (!mounted) return;
    setState(() {
      _matches = matches;
      _loading = false;
    });
  }

  /// Mo 1 kenh: huy controller cu, tao moi cho url kenh [i], phat lap lai.
  /// video_player khong doi nguon duoc nen phai tao lai controller.
  Future<void> _openChannel(int i) async {
    final old = _video;
    setState(() {
      _channelIndex = i;
      _videoReady = false;
      _video = null;
    });
    await old?.dispose();
    final c = VideoPlayerController.networkUrl(
        Uri.parse(kLiveTvChannels[i].url));
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.play();
    } catch (_) {
      // Stream loi/timeout -> giu khung loading, khong crash.
    }
    if (!mounted) {
      c.dispose();
      return;
    }
    setState(() {
      _video = c;
      _videoReady = c.value.isInitialized;
    });
  }

  void _onTick() {
    _tickCount++;
    if (_isDemoMode) {
      // Demo: tick den het tran roi moi sang tran moi (khong reset giua chung).
      final m = _matches.first;
      setState(() {
        _matches = [m.isLive ? LiveMatch.tickDemo(m, _rng) : LiveMatch.demo()];
      });
      return;
    }
    // Che do that: dinh ky lay lai ty so live tu API.
    if (_tickCount % 10 == 0) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _scaffold(
      tvSection: !widget.enableLiveTv
          ? null
          : LiveTvSection(
              controller: _video,
              ready: _videoReady,
              selectedIndex: _channelIndex,
              onSelect: _openChannel,
            ),
    );
  }

  Widget _scaffold({required Widget? tvSection}) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: kBrandGradient)),
        title: const Text('Trực tiếp',
            style: TextStyle(
                fontFamily: kDisplayFont, fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.amber.withValues(alpha: .12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const Text(
              'Chỉ xem — không đặt cược trận thật',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),
          ?tvSection,
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_matches.isEmpty) {
      return const Center(
        child: Text('Chưa có trận trực tiếp',
            style: TextStyle(color: Colors.black54)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _matchTile(_matches[i]),
    );
  }

  Widget _matchTile(LiveMatch m) {
    final recentEvents = m.events.length > 2
        ? m.events.sublist(m.events.length - 2)
        : m.events;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _teamLabel(m.homeFlag, m.home)),
              Text('${m.homeGoals} - ${m.awayGoals}',
                  style: displayStyle(size: 22, color: Colors.black87)),
              Expanded(child: _teamLabel(m.awayFlag, m.away, alignEnd: true)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (m.isLive) ...[
                const PulseDot(Colors.lightGreen),
                const SizedBox(width: 6),
                Text("Phút ${m.minute}'",
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600)),
              ] else
                Text(m.status,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600)),
            ],
          ),
          if (recentEvents.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final e in recentEvents)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text("${e.minute}' ${e.text}",
                    style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _teamLabel(String flag, String name, {bool alignEnd = false}) {
    final flagText = flag.isEmpty ? '' : '$flag ';
    return Text(
      alignEnd ? '$name $flagText' : '$flagText$name',
      textAlign: alignEnd ? TextAlign.right : TextAlign.left,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      overflow: TextOverflow.ellipsis,
    );
  }
}
