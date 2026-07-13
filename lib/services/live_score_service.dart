import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../logic/live_match.dart';

/// Lay ty so bong da truc tiep de HIEN THI (khong dung de cuoc). Co
/// FOOTBALL_API_KEY (--dart-define) -> goi API-Football (api-sports.io);
/// khong key / khong tran dang da / loi / timeout -> tra tran demo gia lap.
/// Khong bao gio throw.
class LiveScoreService {
  LiveScoreService._();
  static final LiveScoreService instance = LiveScoreService._();

  static const String _apiKey = String.fromEnvironment('FOOTBALL_API_KEY');
  static const String _endpoint =
      'https://v3.football.api-sports.io/fixtures?live=all';

  Future<List<LiveMatch>> fetchLive() async {
    if (_apiKey.isEmpty) {
      return [LiveMatch.demo()];
    }
    try {
      final resp = await http.get(
        Uri.parse(_endpoint),
        headers: {'x-apisports-key': _apiKey},
      ).timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        final list = (data['response'] as List?) ?? [];
        final matches = list
            .map((e) => _parseFixture(e as Map<String, dynamic>))
            .whereType<LiveMatch>()
            .toList();
        if (matches.isNotEmpty) return matches;
      }
    } catch (_) {
      debugPrint('LiveScoreService loi, dung tran demo');
    }
    return [LiveMatch.demo()];
  }

  LiveMatch? _parseFixture(Map<String, dynamic> fixture) {
    try {
      final teams = fixture['teams'] as Map<String, dynamic>;
      final home = teams['home'] as Map<String, dynamic>;
      final away = teams['away'] as Map<String, dynamic>;
      final goals = fixture['goals'] as Map<String, dynamic>;
      final status =
          (fixture['fixture'] as Map<String, dynamic>)['status']
              as Map<String, dynamic>;
      final events = (fixture['events'] as List?) ?? [];

      return LiveMatch(
        home: home['name'] as String? ?? '?',
        away: away['name'] as String? ?? '?',
        homeFlag: home['logo'] as String? ?? '',
        awayFlag: away['logo'] as String? ?? '',
        homeGoals: (goals['home'] as num?)?.toInt() ?? 0,
        awayGoals: (goals['away'] as num?)?.toInt() ?? 0,
        minute: (status['elapsed'] as num?)?.toInt() ?? 0,
        isLive: status['short'] != 'FT' && status['short'] != 'NS',
        status: status['short'] as String? ?? 'NS',
        events: events
            .take(5)
            .map((e) => _parseEvent(e as Map<String, dynamic>))
            .whereType<LiveEvent>()
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  LiveEvent? _parseEvent(Map<String, dynamic> e) {
    try {
      final time = e['time'] as Map<String, dynamic>;
      final type = e['type'] as String? ?? '';
      final detail = e['detail'] as String? ?? '';
      final player = (e['player'] as Map<String, dynamic>?)?['name'] as String?;
      final minute = (time['elapsed'] as num?)?.toInt() ?? 0;
      final text = player != null ? '$type - $detail: $player' : '$type - $detail';
      return LiveEvent(minute, text);
    } catch (_) {
      return null;
    }
  }
}
