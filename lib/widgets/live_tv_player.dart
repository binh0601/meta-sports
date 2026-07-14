import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../logic/live_tv_channels.dart';
import '../theme/brand_colors.dart';

/// Khoi "Xem truc tiep (TV)": khung video (video_player) phat stream HLS/MP4
/// + hang chip chon kenh. Controller do man cha so huu (tao lai moi khi doi
/// kenh); day chi hien va bat/tat phat.
class LiveTvSection extends StatelessWidget {
  final VideoPlayerController? controller;
  final bool ready; // controller da initialize xong chua
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const LiveTvSection({
    super.key,
    required this.controller,
    required this.ready,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(aspectRatio: 16 / 9, child: _video()),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(children: [
            Icon(Icons.live_tv, size: 16, color: kGold),
            SizedBox(width: 6),
            Text('Chọn kênh',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87)),
          ]),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: kLiveTvChannels.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = kLiveTvChannels[i];
              final active = i == selectedIndex;
              return ChoiceChip(
                selected: active,
                selectedColor: kGold,
                label: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (c.isLive) ...[
                    const Icon(Icons.circle, size: 8, color: Colors.red),
                    const SizedBox(width: 4),
                  ],
                  Text(c.title,
                      style: TextStyle(
                          fontSize: 12,
                          color: active ? Colors.white : Colors.black87)),
                ]),
                onSelected: (_) {
                  if (!active) onSelect(i);
                },
              );
            },
          ),
        ),
        const Divider(height: 20),
      ],
    );
  }

  Widget _video() {
    final c = controller;
    if (!ready || c == null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: kGold),
      );
    }
    return GestureDetector(
      onTap: () => c.value.isPlaying ? c.pause() : c.play(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(c),
          // Nut play hien khi dang tam dung; badge LIVE goc tren.
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: c,
            builder: (_, v, _) => v.isPlaying
                ? const SizedBox.shrink()
                : const DecoratedBox(
                    decoration: BoxDecoration(
                        color: Colors.black38, shape: BoxShape.circle),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.play_arrow,
                          color: Colors.white, size: 40),
                    ),
                  ),
          ),
          if (kLiveTvChannels[selectedIndex].isLive)
            const Positioned(
              top: 8,
              left: 8,
              child: _LiveBadge(),
            ),
        ],
      ),
    );
  }
}

/// Badge "● LIVE" do goc video khi kenh la stream truc tiep.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: Colors.red, borderRadius: BorderRadius.circular(4)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.circle, size: 7, color: Colors.white),
          SizedBox(width: 4),
          Text('LIVE',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
        ]),
      );
}
