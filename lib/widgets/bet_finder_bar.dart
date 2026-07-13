import 'package:flutter/material.dart';

import '../logic/bet_query_filter.dart';
import '../logic/football_market.dart';
import '../services/bet_finder_service.dart';

/// Thanh tim keo bang cau hoi tu nhien: go xong bam tim (hoac Enter) ->
/// dich thanh BetQueryFilter va bao ve cho SportsbookScreen loc danh sach.
class BetFinderBar extends StatefulWidget {
  final List<FootballMatch> matches;
  final BetQueryFilter filter;
  final ValueChanged<BetQueryFilter> onFilterChanged;

  const BetFinderBar({
    super.key,
    required this.matches,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<BetFinderBar> createState() => _BetFinderBarState();
}

class _BetFinderBarState extends State<BetFinderBar> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    setState(() => _loading = true);
    final filter = await BetFinderService.instance.find(text, widget.matches);
    if (!mounted) return;
    setState(() => _loading = false);
    widget.onFilterChanged(filter);
  }

  void _clear() {
    _controller.clear();
    widget.onFilterChanged(const BetQueryFilter.empty());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _search(),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Tìm kèo: "kèo cửa nhà dưới 2.0"...',
                  prefixIcon: Icon(Icons.search, size: 18),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _search,
                  ),
          ],
        ),
        if (!widget.filter.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(_summary(widget.filter),
                      style: const TextStyle(fontSize: 11)),
                ),
                TextButton(onPressed: _clear, child: const Text('Xoá lọc')),
              ],
            ),
          ),
      ],
    );
  }

  String _summary(BetQueryFilter f) {
    final parts = <String>[
      if (f.sideHome == true) 'Cửa nhà',
      if (f.sideHome == false) 'Cửa khách',
      if (f.maxOdds != null) 'Dưới ${f.maxOdds}',
      if (f.minOdds != null) 'Trên ${f.minOdds}',
      if (f.league != null) f.league!.label,
      if (f.teamKeywords.isNotEmpty) f.teamKeywords.join(', '),
    ];
    return parts.join(' · ');
  }
}
