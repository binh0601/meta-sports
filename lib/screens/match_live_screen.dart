import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../logic/live_tv_matches.dart';
import '../theme/brand_colors.dart';
import '../widgets/live_match_card.dart' show TeamAvatar;
import '../widgets/motion_effects.dart';

/// Man xem 1 tran truc tiep: video bong da that + header ty so + dien bien.
/// Phut/ty so tu tang cho sinh dong. Chi xem — khong ca cuoc.
class MatchLiveScreen extends StatefulWidget {
  final LiveTvMatch match;
  const MatchLiveScreen({super.key, required this.match});

  @override
  State<MatchLiveScreen> createState() => _MatchLiveScreenState();
}

class _MatchLiveScreenState extends State<MatchLiveScreen> {
  late final LiveMatchRun _run = LiveMatchRun(widget.match);
  VideoPlayerController? _video;
  bool _ready = false;
  Timer? _timer;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _initVideo();
    if (widget.match.isLive) {
      _timer = Timer.periodic(
          const Duration(milliseconds: 2500), (_) => setState(() => _run.tick(_rng)));
    }
  }

  Future<void> _initVideo() async {
    final c = VideoPlayerController.asset(widget.match.videoAsset);
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.play();
    } catch (_) {
      // Loi giai ma -> giu khung loading, khong crash.
    }
    if (!mounted) {
      c.dispose();
      return;
    }
    setState(() {
      _video = c;
      _ready = c.value.isInitialized;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      appBar: AppBar(
        flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: kBrandGradient)),
        title: Text('${m.home} — ${m.away}',
            style: const TextStyle(
                fontFamily: kDisplayFont, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(aspectRatio: 16 / 9, child: _player()),
          ),
          const SizedBox(height: 14),
          _scoreHeader(),
          const SizedBox(height: 18),
          _eventsSection(),
        ],
      ),
    );
  }

  Widget _player() {
    final c = _video;
    if (!_ready || c == null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: kGold),
      );
    }
    return GestureDetector(
      onTap: () => c.value.isPlaying ? c.pause() : c.play(),
      child: Stack(alignment: Alignment.center, children: [
        VideoPlayer(c),
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: c,
          builder: (_, v, _) => v.isPlaying
              ? const SizedBox.shrink()
              : const DecoratedBox(
                  decoration: BoxDecoration(
                      color: Colors.black38, shape: BoxShape.circle),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child:
                        Icon(Icons.play_arrow, color: Colors.white, size: 44),
                  ),
                ),
        ),
        if (widget.match.isLive)
          const Positioned(top: 10, left: 10, child: _LiveTag()),
      ]),
    );
  }

  Widget _scoreHeader() {
    final m = widget.match;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E2749), Color(0xFF121834)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Column(children: [
        Text(m.competition.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: .55))),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _teamCol(m.home)),
          Column(children: [
            Text(m.isLive ? _run.score : 'VS',
                style: const TextStyle(
                    fontFamily: kDisplayFont,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: kGold,
                    fontFeatures: [FontFeature.tabularFigures()])),
            const SizedBox(height: 6),
            if (m.isLive)
              Row(mainAxisSize: MainAxisSize.min, children: [
                const PulseDot(Colors.redAccent),
                const SizedBox(width: 5),
                Text("Phút ${_run.minute}'",
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent)),
              ]),
          ]),
          Expanded(child: _teamCol(m.away)),
        ]),
      ]),
    );
  }

  Widget _teamCol(String name) => Column(children: [
        TeamAvatar(name),
        const SizedBox(height: 8),
        Text(name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
      ]);

  Widget _eventsSection() {
    if (_run.events.isEmpty) {
      return Text('Chỉ xem — không cá cược trận thật.',
          style: TextStyle(
              fontSize: 12, color: Colors.white.withValues(alpha: .5)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 4, height: 16, color: kGold),
          const SizedBox(width: 8),
          const Text('Diễn biến',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
        ]),
        const SizedBox(height: 10),
        for (final e in _run.events)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              const Icon(Icons.sports_soccer, size: 15, color: kGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(e,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: .85))),
              ),
            ]),
          ),
        const SizedBox(height: 8),
        Text('Chỉ xem — không cá cược trận thật.',
            style: TextStyle(
                fontSize: 12, color: Colors.white.withValues(alpha: .5))),
      ],
    );
  }
}

/// Nhan "● LIVE" tren video.
class _LiveTag extends StatelessWidget {
  const _LiveTag();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: Colors.red, borderRadius: BorderRadius.circular(5)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.circle, size: 7, color: Colors.white),
          SizedBox(width: 5),
          Text('LIVE',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
        ]),
      );
}
