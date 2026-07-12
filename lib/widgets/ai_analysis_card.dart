import 'package:flutter/material.dart';

import '../logic/ai_match_analysis.dart';
import '../logic/football_market.dart';
import '../services/ai_analysis_service.dart';
import '../theme/brand_colors.dart';

/// Card "AI nhan dinh": bam nut -> goi service (Groq hoac local),
/// hien doan phan tich + badge nguon.
class AiAnalysisCard extends StatefulWidget {
  final FootballMatch match;
  const AiAnalysisCard({super.key, required this.match});

  @override
  State<AiAnalysisCard> createState() => _AiAnalysisCardState();
}

class _AiAnalysisCardState extends State<AiAnalysisCard> {
  AiMatchAnalysis? _result;
  bool _loading = false;

  Future<void> _run() async {
    setState(() => _loading = true);
    final r = await AiAnalysisService.instance.analyze(widget.match);
    if (!mounted) return;
    setState(() {
      _result = r;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18, color: kGold),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('AI nhận định',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                if (r != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: kGold),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      r.source == 'groq' ? 'Groq AI' : 'AI nội bộ',
                      style: const TextStyle(fontSize: 10, color: kGold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (r == null)
              Center(
                child: FilledButton.tonalIcon(
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.psychology),
                  label: Text(
                      _loading ? 'Đang phân tích...' : 'Phân tích trận này'),
                  onPressed: _loading ? null : _run,
                ),
              )
            else
              Text(r.text,
                  style: const TextStyle(fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
