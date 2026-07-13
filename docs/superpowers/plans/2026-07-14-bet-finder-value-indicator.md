# Trợ lý tìm kèo + Value indicator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm 2 tính năng cho người chơi trên sân kèo: (1) trợ lý tìm kèo bằng
câu hỏi tự nhiên tiếng Việt, lọc danh sách trận hiện có; (2) chỉ số
"Edge"/badge "VALUE" cạnh mỗi cửa cược 1x2, cho thấy chênh lệch giữa ước tính
chuyên gia và tỷ lệ ngầm của odds.

**Architecture:** Mirror pattern đã có ở `AiAnalysisService`: câu hỏi được
dịch thành `BetQueryFilter` (Dart thuần) qua Groq LLM nếu có API key, fallback
rule-based parser nội bộ nếu không — không bao giờ throw ra UI. Value edge là
hàm thuần trên `MatchInsights` (đã tồn tại), chỉ áp dụng cho
`MarketType.match1x2` vì kèo chấp không có xác suất thắng gốc để so sánh.

**Tech Stack:** Flutter/Dart, gói `http` (đã có trong `pubspec.yaml`), Groq API
(OpenAI-compatible) qua `String.fromEnvironment('GROQ_API_KEY')`.

## Global Constraints

- Logic tính toán đặt trong `lib/logic/`, Dart thuần, không import Flutter —
  để unit test được (theo CLAUDE.md).
- Chuỗi hiển thị UI viết tiếng Việt; tên biến/hàm/class viết tiếng Anh.
- Giữ mỗi file dưới ~200 dòng; file phình to thì tách module.
- Sửa logic trong `lib/logic/` phải có test tương ứng trong `test/`.
- Không skip/xóa test để cho build xanh. `flutter analyze` phải sạch,
  `flutter test` phải pass hết trước khi coi 1 task là xong.
- Chạy test cả file (`flutter test test/x_test.dart`), không dùng
  `--plain-name` (tên test có dấu cách crash trên Windows).
- KISS/YAGNI: không thêm market mới (tài/xỉu, giải theo quốc gia), không
  thêm abstraction ngoài phạm vi spec.
- Package name của project: `house_edge_demo` (dùng trong import test:
  `package:house_edge_demo/...`).
- Commit nhỏ, tập trung, theo conventional commits (`feat:`, `test:`, ...).

---

### Task 1: `BetQueryFilter` — model lọc thuần Dart

**Files:**
- Create: `lib/logic/bet_query_filter.dart`
- Test: `test/bet_query_filter_test.dart`

**Interfaces:**
- Produces: `String normalizeVi(String s)` (top-level, bỏ dấu tiếng Việt +
  hạ chữ thường — dùng lại ở Task 2). `class BetQueryFilter` với
  constructor `BetQueryFilter({List<String> teamKeywords = const [],
  bool? sideHome, double? maxOdds, double? minOdds, League? league})`,
  `const BetQueryFilter.empty()`, getter `bool get isEmpty`, method
  `bool matchesSide(FootballMatch m, bool onHome, League currentLeague)`.
  `League` và `FootballMatch` import từ `football_market.dart` (đã có).

- [ ] **Step 1: Write the failing test**

```dart
// test/bet_query_filter_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/bet_query_filter.dart';
import 'package:house_edge_demo/logic/football_market.dart';

void main() {
  group('normalizeVi', () {
    test('bo dau + ha chu thuong', () {
      expect(normalizeVi('Việt Nam'), 'viet nam');
      expect(normalizeVi('ĐỨC'), 'duc');
    });
  });

  group('BetQueryFilter.matchesSide', () {
    final matches = generateRound(Random(1), 1);
    final m = matches.first;

    test('filter rong -> luon khop', () {
      const f = BetQueryFilter.empty();
      expect(f.isEmpty, true);
      expect(f.matchesSide(m, true, League.asianCup), true);
      expect(f.matchesSide(m, false, League.asianCup), true);
    });

    test('loc theo cua nha/khach', () {
      const f = BetQueryFilter(sideHome: true);
      expect(f.matchesSide(m, true, League.asianCup), true);
      expect(f.matchesSide(m, false, League.asianCup), false);
    });

    test('loc theo khoang odds', () {
      final f = BetQueryFilter(maxOdds: m.oddsHome - 0.01);
      expect(f.matchesSide(m, true, League.asianCup), false);
      final f2 = BetQueryFilter(minOdds: m.oddsHome + 0.01);
      expect(f2.matchesSide(m, true, League.asianCup), false);
    });

    test('loc theo giai khac giai dang xem -> khong khop', () {
      const f = BetQueryFilter(league: League.worldCup);
      expect(f.matchesSide(m, true, League.asianCup), false);
      expect(f.matchesSide(m, true, League.worldCup), true);
    });

    test('loc theo ten doi (khong phan biet dau/hoa thuong)', () {
      final f = BetQueryFilter(teamKeywords: [m.home.toUpperCase()]);
      expect(f.matchesSide(m, true, League.asianCup), true);
      expect(f.matchesSide(m, false, League.asianCup), false);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/bet_query_filter_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'house_edge_demo'` hoặc
`Target of URI doesn't exist: 'package:house_edge_demo/logic/bet_query_filter.dart'`.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/logic/bet_query_filter.dart
import 'football_market.dart';

const String _from =
    'aàáạảãăằắặẳẵâầấậẩẫeèéẹẻẽêềếệểễiìíịỉĩoòóọỏõôồốộổỗơờớợởỡ'
    'uùúụủũưừứựửữyỳýỵỷỹđ';
const String _to =
    'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooo'
    'uuuuuuuuuuuyyyyyd';

/// Bo dau tieng Viet + ha chu thuong — dung chung cho so khop tu khoa
/// khong phan biet dau (parser lan bo loc).
String normalizeVi(String s) {
  var out = s.toLowerCase();
  for (var i = 0; i < _from.length; i++) {
    out = out.replaceAll(_from[i], _to[i]);
  }
  return out;
}

/// Bo loc rut ra tu cau hoi tim keo tu nhien — dung chung cho ca parser
/// noi bo va ket qua Groq tra ve. Rong (moi field null/list rong) = khong
/// loc gi, hien tat ca.
class BetQueryFilter {
  final List<String> teamKeywords;
  final bool? sideHome; // null = ca 2 cua
  final double? maxOdds;
  final double? minOdds;
  final League? league;

  const BetQueryFilter({
    this.teamKeywords = const [],
    this.sideHome,
    this.maxOdds,
    this.minOdds,
    this.league,
  });

  const BetQueryFilter.empty() : this();

  bool get isEmpty =>
      teamKeywords.isEmpty &&
      sideHome == null &&
      maxOdds == null &&
      minOdds == null &&
      league == null;

  /// True neu cua [onHome] cua tran [m] thoa moi dieu kien filter.
  /// [currentLeague]: giai dang hien thi tren san keo.
  bool matchesSide(FootballMatch m, bool onHome, League currentLeague) {
    if (league != null && league != currentLeague) return false;
    if (sideHome != null && sideHome != onHome) return false;
    final odds = onHome ? m.oddsHome : m.oddsAway;
    if (maxOdds != null && odds > maxOdds!) return false;
    if (minOdds != null && odds < minOdds!) return false;
    if (teamKeywords.isNotEmpty) {
      final team = normalizeVi(onHome ? m.home : m.away);
      final ok = teamKeywords.any((k) => team.contains(normalizeVi(k)));
      if (!ok) return false;
    }
    return true;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/bet_query_filter_test.dart`
Expected: PASS (7 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/logic/bet_query_filter.dart test/bet_query_filter_test.dart
git commit -m "feat: add BetQueryFilter for bet search filtering"
```

---

### Task 2: `BetQueryParser` — parser rule-based tiếng Việt

**Files:**
- Create: `lib/logic/bet_query_parser.dart`
- Test: `test/bet_query_parser_test.dart`

**Interfaces:**
- Consumes: `normalizeVi` từ `bet_query_filter.dart` (Task 1),
  `BetQueryFilter` (Task 1), `League` từ `football_market.dart`.
- Produces: `class BetQueryParser` với
  `static BetQueryFilter parse(String query, List<String> teamNames)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/bet_query_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/bet_query_parser.dart';
import 'package:house_edge_demo/logic/football_market.dart';

void main() {
  const teams = ['Việt Nam', 'Thái Lan', 'Đức', 'Pháp'];

  test('cau rong -> filter rong', () {
    final f = BetQueryParser.parse('', teams);
    expect(f.isEmpty, true);
  });

  test('nhan dien cua nha + odds duoi', () {
    final f = BetQueryParser.parse('kèo cửa nhà dưới 2.0', teams);
    expect(f.sideHome, true);
    expect(f.maxOdds, 2.0);
  });

  test('nhan dien cua khach + odds tren', () {
    final f = BetQueryParser.parse('kèo đội khách trên 1.85', teams);
    expect(f.sideHome, false);
    expect(f.minOdds, 1.85);
  });

  test('nhan dien giai world cup', () {
    final f = BetQueryParser.parse('trận world cup tối nay', teams);
    expect(f.league, League.worldCup);
  });

  test('nhan dien giai chau a', () {
    final f = BetQueryParser.parse('kèo châu Á đêm nay', teams);
    expect(f.league, League.asianCup);
  });

  test('nhan dien ten doi trong danh sach', () {
    final f = BetQueryParser.parse('cửa Việt Nam thắng', teams);
    expect(f.teamKeywords, contains('Việt Nam'));
  });

  test('cau vo nghia khong khop gi -> filter rong', () {
    final f = BetQueryParser.parse('asdkjaslkdj random text', teams);
    expect(f.isEmpty, true);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/bet_query_parser_test.dart`
Expected: FAIL — `bet_query_parser.dart` chưa tồn tại.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/logic/bet_query_parser.dart
import 'bet_query_filter.dart';
import 'football_market.dart';

/// Parser tu ngu rule-based cho cau hoi tim keo tieng Viet — chay hoan
/// toan offline, dung khi khong co GROQ_API_KEY hoac goi LLM that bai.
class BetQueryParser {
  BetQueryParser._();

  /// [teamNames]: ten doi dang hien thi trong vong dau hien tai — dung de
  /// nhan dien tu khoa ten doi trong cau hoi.
  static BetQueryFilter parse(String query, List<String> teamNames) {
    final q = normalizeVi(query);
    if (q.trim().isEmpty) return const BetQueryFilter.empty();

    bool? sideHome;
    if (q.contains('cua nha') ||
        q.contains('doi nha') ||
        q.contains('chu nha')) {
      sideHome = true;
    } else if (q.contains('cua khach') || q.contains('doi khach')) {
      sideHome = false;
    }

    double? maxOdds;
    final duoi = RegExp(r'duoi\s+(\d+(?:[.,]\d+)?)').firstMatch(q);
    if (duoi != null) {
      maxOdds = double.parse(duoi.group(1)!.replaceAll(',', '.'));
    }
    double? minOdds;
    final tren = RegExp(r'tren\s+(\d+(?:[.,]\d+)?)').firstMatch(q);
    if (tren != null) {
      minOdds = double.parse(tren.group(1)!.replaceAll(',', '.'));
    }

    League? league;
    if (q.contains('world cup')) {
      league = League.worldCup;
    } else if (q.contains('chau a') || q.contains('asian cup')) {
      league = League.asianCup;
    }

    final teamKeywords =
        teamNames.where((t) => q.contains(normalizeVi(t))).toList();

    return BetQueryFilter(
      teamKeywords: teamKeywords,
      sideHome: sideHome,
      maxOdds: maxOdds,
      minOdds: minOdds,
      league: league,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/bet_query_parser_test.dart`
Expected: PASS (7 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/logic/bet_query_parser.dart test/bet_query_parser_test.dart
git commit -m "feat: add rule-based Vietnamese bet query parser"
```

---

### Task 3: `BetFinderService` — Groq + fallback

**Files:**
- Create: `lib/services/bet_finder_service.dart`
- Test: `test/bet_finder_service_test.dart`

**Interfaces:**
- Consumes: `BetQueryFilter`, `BetQueryParser.parse` (Task 1-2),
  `FootballMatch`, `League` (`football_market.dart`).
- Produces: `class BetFinderService` singleton (`BetFinderService.instance`)
  với `Future<BetQueryFilter> find(String query, List<FootballMatch> matches)`
  và `static BetQueryFilter filterFromJson(Map<String, dynamic> json)` (public,
  pure — dùng để test phần parse JSON mà không cần gọi mạng thật).

- [ ] **Step 1: Write the failing test**

```dart
// test/bet_finder_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/football_market.dart';
import 'package:house_edge_demo/services/bet_finder_service.dart';

void main() {
  group('BetFinderService.filterFromJson', () {
    test('parse day du field', () {
      final f = BetFinderService.filterFromJson({
        'teamKeywords': ['Việt Nam'],
        'sideHome': true,
        'maxOdds': 2.0,
        'minOdds': null,
        'league': 'worldCup',
      });
      expect(f.teamKeywords, ['Việt Nam']);
      expect(f.sideHome, true);
      expect(f.maxOdds, 2.0);
      expect(f.minOdds, null);
      expect(f.league, League.worldCup);
    });

    test('thieu field -> mac dinh rong/null', () {
      final f = BetFinderService.filterFromJson({});
      expect(f.isEmpty, true);
    });
  });

  group('BetFinderService.find (khong co GROQ_API_KEY trong test)', () {
    test('cau hoi ro rang -> dung parser noi bo, tra dung filter', () async {
      final matches = generateRound(Random(1), 1);
      final f = await BetFinderService.instance
          .find('kèo cửa nhà dưới 3.0', matches);
      expect(f.sideHome, true);
      expect(f.maxOdds, 3.0);
    });
  });
}
```

Lưu ý: cần thêm `import 'dart:math';` ở đầu file test cho `Random`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/bet_finder_service_test.dart`
Expected: FAIL — `bet_finder_service.dart` chưa tồn tại.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/services/bet_finder_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../logic/bet_query_filter.dart';
import '../logic/bet_query_parser.dart';
import '../logic/football_market.dart';

/// Dich cau hoi tim keo tu nhien thanh BetQueryFilter. Co GROQ_API_KEY ->
/// goi Groq yeu cau tra JSON dung schema; khong key / loi / sai format ->
/// fallback BetQueryParser (luon co ket qua, khong bao gio throw).
class BetFinderService {
  BetFinderService._();
  static final BetFinderService instance = BetFinderService._();

  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  static const String _systemPrompt =
      'Ban dich cau hoi tim keo bong da thanh JSON loc. Chi tra ve JSON, '
      'khong giai thich them, khong markdown. Schema: '
      '{"teamKeywords": [string], "sideHome": true|false|null, '
      '"maxOdds": number|null, "minOdds": number|null, '
      '"league": "asianCup"|"worldCup"|null}.';

  Future<BetQueryFilter> find(
      String query, List<FootballMatch> matches) async {
    if (query.trim().isEmpty) return const BetQueryFilter.empty();
    final teamNames = [for (final m in matches) ...[m.home, m.away]];
    if (_apiKey.isEmpty) return BetQueryParser.parse(query, teamNames);
    try {
      final resp = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'max_tokens': 200,
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                {
                  'role': 'user',
                  'content': 'Danh sach doi dang thi dau: '
                      '${teamNames.join(", ")}. Cau hoi: "$query"'
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        final content =
            (data['choices'] as List).first['message']['content'] as String;
        return filterFromJson(jsonDecode(content) as Map<String, dynamic>);
      }
    } catch (_) {
      debugPrint('Bet finder Groq loi, dung parser noi bo');
    }
    return BetQueryParser.parse(query, teamNames);
  }

  /// Chuyen JSON (tu Groq) thanh BetQueryFilter. Tach rieng khoi [find] de
  /// test duoc ma khong can goi mang that.
  static BetQueryFilter filterFromJson(Map<String, dynamic> json) {
    League? league;
    if (json['league'] == 'asianCup') league = League.asianCup;
    if (json['league'] == 'worldCup') league = League.worldCup;
    return BetQueryFilter(
      teamKeywords:
          (json['teamKeywords'] as List?)?.cast<String>() ?? const [],
      sideHome: json['sideHome'] as bool?,
      maxOdds: (json['maxOdds'] as num?)?.toDouble(),
      minOdds: (json['minOdds'] as num?)?.toDouble(),
      league: league,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/bet_finder_service_test.dart`
Expected: PASS (3 tests) — trong môi trường test không truyền
`--dart-define=GROQ_API_KEY`, nên `find()` luôn đi qua nhánh parser nội bộ.

- [ ] **Step 5: Commit**

```bash
git add lib/services/bet_finder_service.dart test/bet_finder_service_test.dart
git commit -m "feat: add BetFinderService with Groq + local fallback"
```

---

### Task 4: `BetFinderBar` widget + wiring vào `SportsbookScreen`

**Files:**
- Create: `lib/widgets/bet_finder_bar.dart`
- Modify: `lib/screens/sportsbook_screen.dart`
- Test: thêm vào `test/widget_test.dart`

**Interfaces:**
- Consumes: `BetQueryFilter`, `BetFinderService.instance.find` (Task 1-3),
  `FootballMatch`, `League` (`football_market.dart`), `gameState`
  (`game_state.dart`).
- Produces: `class BetFinderBar extends StatefulWidget` với props
  `{required List<FootballMatch> matches, required BetQueryFilter filter,
  required ValueChanged<BetQueryFilter> onFilterChanged}`.

- [ ] **Step 1: Write the failing test**

Thêm vào cuối `test/widget_test.dart` (trước dấu `}` cuối file):

```dart
  testWidgets('tim keo: go cau hoi loc dung cua nha, xoa loc tra ve du tran',
      (tester) async {
    await tester.pumpWidget(const HouseEdgeApp(showSplash: false));
    await tester.enterText(find.byType(TextField).at(0), 'demo');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('ĐĂNG NHẬP'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final totalBefore = find.byType(MatchCard).evaluate().length;
    expect(totalBefore, 8);

    // BetFinderBar la TextField duy nhat tren man san keo (2 TextField dang
    // nhap da bi thay the sau khi dang nhap thanh cong).
    await tester.enterText(find.byType(TextField), 'kèo cửa nhà');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Xoá lọc'), findsOneWidget);
    final totalAfterFilter = find.byType(MatchCard).evaluate().length;
    expect(totalAfterFilter, lessThan(totalBefore));

    await tester.tap(find.text('Xoá lọc'));
    await tester.pump();
    expect(find.byType(MatchCard).evaluate().length, totalBefore);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL — không tìm thấy `TextField` với hint "Tìm kèo..." (chưa có
`BetFinderBar` trong cây widget).

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/widgets/bet_finder_bar.dart
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
```

Sửa `lib/screens/sportsbook_screen.dart`: chuyển `SportsbookScreen` từ
`StatelessWidget` sang `StatefulWidget` để giữ state filter, và lọc
`g.matches` trước khi render:

```dart
import 'package:flutter/material.dart';

import '../logic/bet_query_filter.dart';
import '../logic/football_market.dart';
import '../logic/game_state.dart';
import '../theme/brand_colors.dart';
import '../widgets/bet_finder_bar.dart';
import '../widgets/bet_slip_drawer.dart';
import '../widgets/bet_slip_panel.dart';
import '../widgets/brand_crest.dart';
import '../widgets/coin_burst.dart';
import '../widgets/gold_rain.dart';
import '../widgets/hero_banner.dart';
import '../widgets/league_switcher.dart';
import '../widgets/match_card.dart';
import '../widgets/motion_effects.dart';
import '../widgets/promo_banner_carousel.dart';

class SportsbookScreen extends StatefulWidget {
  const SportsbookScreen({super.key});

  @override
  State<SportsbookScreen> createState() => _SportsbookScreenState();
}

class _SportsbookScreenState extends State<SportsbookScreen> {
  BetQueryFilter _filter = const BetQueryFilter.empty();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameState,
      builder: (context, _) {
        final g = gameState;
        final wonThisRound =
            g.roundPlayed && g.lastResults.any((b) => b.won);
        final visibleMatches = _filter.isEmpty
            ? g.matches
            : g.matches
                .where((m) =>
                    _filter.matchesSide(m, true, g.league) ||
                    _filter.matchesSide(m, false, g.league))
                .toList();
        return Scaffold(
          endDrawer: const BetSlipDrawer(),
          appBar: AppBar(
            flexibleSpace: Container(
                decoration: const BoxDecoration(gradient: kBrandGradient)),
            titleSpacing: 8,
            title: Row(
              children: [
                const BrandCrest(size: 26),
                const SizedBox(width: 8),
                const Text('MEGA SPORTS',
                    style: TextStyle(
                        fontFamily: kDisplayFont,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    border: Border.all(color: kGold),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                      g.league == League.worldCup
                          ? 'WORLD CUP'
                          : 'CUP CHÂU Á',
                      style: const TextStyle(fontSize: 9, color: kGold)),
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  _walletBar(context, g),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            children: [
                              const LeagueSwitcher(),
                              const SizedBox(height: 8),
                              BetFinderBar(
                                matches: g.matches,
                                filter: _filter,
                                onFilterChanged: (f) =>
                                    setState(() => _filter = f),
                              ),
                              const SizedBox(height: 8),
                              const PromoBannerCarousel(),
                            ],
                          ),
                        ),
                        HeroBanner(
                            roundNumber: g.roundNumber, league: g.league),
                        if (visibleMatches.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'Không tìm thấy kèo phù hợp, thử câu hỏi khác.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13),
                            ),
                          )
                        else
                          for (var i = 0; i < visibleMatches.length; i++)
                            MatchCard(
                              key: ValueKey(visibleMatches[i].id),
                              match: visibleMatches[i],
                              index: i,
                            ),
                      ],
                    ),
                  ),
                  const BetSlipPanel(),
                ],
              ),
              if (wonThisRound)
                Positioned.fill(
                  child: GoldRainOverlay(
                      key: ValueKey('gold-rain-${g.roundNumber}')),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _walletBar(BuildContext context, GameState g) {
    return Container(
      decoration: const BoxDecoration(gradient: kBrandGradient),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: CoinBurst(
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet, size: 18, color: kGold),
            const SizedBox(width: 6),
            AnimatedMoneyText(
              value: g.balance,
              style: const TextStyle(
                fontFamily: kDisplayFont,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: kGold,
              ),
            ),
            const Spacer(),
            Builder(
              builder: (ctx) => GestureDetector(
                onTap: () => Scaffold.of(ctx).openEndDrawer(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    g.pending.isEmpty
                        ? 'Vòng ${g.roundNumber}'
                        : 'Vòng ${g.roundNumber} • ${g.pending.length} phiếu chờ',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS (tất cả test trong file, kể cả test mới)

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/bet_finder_bar.dart lib/screens/sportsbook_screen.dart test/widget_test.dart
git commit -m "feat: wire natural-language bet finder into sportsbook screen"
```

---

### Task 5: `MatchInsights.edgeFor` — công thức edge thuần

**Files:**
- Modify: `lib/logic/match_insights.dart`
- Test: `test/match_insights_test.dart` (mới)

**Interfaces:**
- Consumes: `BettingMath.impliedProb` (`betting_math.dart`, đã có).
- Produces: method `double edgeFor(bool onHome, double odds)` trên
  `MatchInsights`.

- [ ] **Step 1: Write the failing test**

```dart
// test/match_insights_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/football_market.dart';
import 'package:house_edge_demo/logic/match_insights.dart';

void main() {
  group('MatchInsights.edgeFor', () {
    test('odds dung dung xac suat that -> edge ~0', () {
      final m = generateRound(Random(1), 1).first;
      final ins = MatchInsights.of(m);
      // expertHomePct suy tu chinh odds hien tai (khong overround-adjust
      // rieng) nen edge cho ca 2 cua phai gan 0.
      expect(ins.edgeFor(true, m.oddsHome).abs(), lessThan(0.001));
      expect(ins.edgeFor(false, m.oddsAway).abs(), lessThan(0.001));
    });

    test('odds cao hon xac suat ngam that -> edge duong', () {
      final m = generateRound(Random(1), 1).first;
      final ins = MatchInsights.of(m);
      // Odds gia dinh cao hon (it "hoi" hon) -> xac suat ngam thap hon
      // expert -> edge duong.
      final inflatedOdds = m.oddsHome * 1.2;
      expect(ins.edgeFor(true, inflatedOdds), greaterThan(0));
    });

    test('odds thap hon xac suat ngam that -> edge am', () {
      final m = generateRound(Random(1), 1).first;
      final ins = MatchInsights.of(m);
      final deflatedOdds = m.oddsHome * 0.8;
      expect(ins.edgeFor(true, deflatedOdds), lessThan(0));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/match_insights_test.dart`
Expected: FAIL — `The method 'edgeFor' isn't defined for the class 'MatchInsights'`.

- [ ] **Step 3: Write minimal implementation**

Thay toàn bộ nội dung `lib/logic/match_insights.dart` bằng (chỉ thêm import
`betting_math.dart` và method `edgeFor`; phần `factory MatchInsights.of` giữ
nguyên y hệt bản hiện tại):

```dart
import 'dart:math';

import 'betting_math.dart';
import 'football_market.dart';

/// Thong ke "soi keo" cho 1 tran — sinh tat dinh tu id tran nen moi lan
/// mo deu giong nhau. Diem giao duc: du lieu nay PHAN ANH DUNG xac suat
/// that (soi chuan den may cung khong thang duoc bien 5% cua nha cai).
class MatchInsights {
  final List<bool> formHome; // 5 tran gan nhat, true = thang
  final List<bool> formAway;
  final List<String> h2h; // 3 lan doi dau gan nhat
  final int expertHomePct; // "chuyen gia" = xac suat ngam chuan hoa
  final int communityHomePct; // % cong dong chon doi nha (co nhieu)

  MatchInsights._({
    required this.formHome,
    required this.formAway,
    required this.h2h,
    required this.expertHomePct,
    required this.communityHomePct,
  });

  /// Edge cam nhan: chenh lech xac suat "chuyen gia" vs xac suat ngam
  /// tu odds hien thi. KHONG phai loi nhuan that — moi keo van co EV that
  /// am ~5% vi overround. Chi ap dung y nghia voi keo 1x2 (thang/thua),
  /// khong dung cho keo chap.
  double edgeFor(bool onHome, double odds) {
    final expertProb = (onHome ? expertHomePct : 100 - expertHomePct) / 100;
    return expertProb - BettingMath.impliedProb(odds);
  }

  factory MatchInsights.of(FootballMatch m) {
    final rng = Random(m.id * 7919); // seed theo tran -> on dinh
    final p = m.trueProbHome;

    List<bool> form(double winProb) =>
        List.generate(5, (_) => rng.nextDouble() < winProb);

    // Doi dau: ket qua qua khu cung rut tu xac suat that
    String h2hLine() {
      final homeWin = rng.nextDouble() < p;
      final w = 1 + rng.nextInt(3);
      final l = rng.nextInt(w);
      return homeWin
          ? '${m.home}  $w - $l  ${m.away}'
          : '${m.home}  $l - $w  ${m.away}';
    }

    // "Chuyen gia": xac suat ngam da chuan hoa (bo bien nha cai)
    final ihome = 1 / m.oddsHome;
    final iaway = 1 / m.oddsAway;
    final expert = (ihome / (ihome + iaway) * 100).round();
    // Cong dong: quanh chuyen gia +- 12 diem (tam ly dam dong)
    final community =
        (expert + (rng.nextDouble() - .5) * 24).clamp(5, 95).round();

    return MatchInsights._(
      formHome: form(p),
      formAway: form(1 - p),
      h2h: List.generate(3, (_) => h2hLine()),
      expertHomePct: expert,
      communityHomePct: community,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/match_insights_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/logic/match_insights.dart test/match_insights_test.dart
git commit -m "feat: add MatchInsights.edgeFor for value indicator"
```

---

### Task 6: Value indicator trong `OddsSelectButton`

**Files:**
- Modify: `lib/widgets/match_card.dart`
- Test: thêm vào `test/widget_test.dart`

**Interfaces:**
- Consumes: `MatchInsights.of`, `MatchInsights.edgeFor` (Task 5),
  `fmtPct` (`betting_math.dart`, đã có), `MarketType` (`football_market.dart`).

- [ ] **Step 1: Write the failing test**

Thêm vào cuối `test/widget_test.dart`:

```dart
  testWidgets('keo 1x2 chua da hien dong Edge, keo chap khong hien',
      (tester) async {
    await tester.pumpWidget(const HouseEdgeApp(showSplash: false));
    await tester.enterText(find.byType(TextField).at(0), 'demo');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('ĐĂNG NHẬP'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final btn1x2 = tester.widgetList<OddsSelectButton>(find.byWidgetPredicate(
        (w) => w is OddsSelectButton && w.market == MarketType.match1x2));
    expect(btn1x2, isNotEmpty);
    expect(find.textContaining('edge'), findsWidgets);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL — không tìm thấy text chứa "edge" (chưa có dòng edge trong
`OddsSelectButton`).

- [ ] **Step 3: Write minimal implementation**

Sửa `lib/widgets/match_card.dart` — thêm import:

```dart
import '../logic/betting_math.dart';
import '../logic/match_insights.dart';
```

Trong `OddsSelectButton.build`, ngay sau dòng tính `label` (trước
`final selected = ...`), thêm:

```dart
    final showEdge = market == MarketType.match1x2 && !match.played;
    final edge =
        showEdge ? MatchInsights.of(match).edgeFor(onHome, odds) : null;
```

Trong nhánh chưa đá (return `ScaleTap(...)`), sửa `Row` chứa tên đội để
thêm badge VALUE, và thêm dòng Edge sau dòng odds:

```dart
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (placed) ...[
                  const Icon(Icons.check_circle, size: 12, color: kGold),
                  const SizedBox(width: 3),
                ],
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected || placed
                            ? Colors.white
                            : scheme.onSurfaceVariant,
                      )),
                ),
                if (edge != null && edge >= 0.03) ...[
                  const SizedBox(width: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: kGold.withValues(alpha: .2),
                      border: Border.all(color: kGold, width: .8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('VALUE',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: kGold)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
                placed && !selected
                    ? '@${odds.toStringAsFixed(2)} • ĐÃ ĐẶT'
                    : '@${odds.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: kDisplayFont,
                  fontSize: placed && !selected ? 13 : 16,
                  fontWeight: FontWeight.w800,
                  color: selected || placed ? kGold : scheme.primary,
                )),
            if (edge != null)
              Text(
                '${edge >= 0 ? '+' : ''}${fmtPct(edge, 1)} edge',
                style: TextStyle(
                  fontSize: 8,
                  color: edge > 0
                      ? Colors.lightGreenAccent
                      : scheme.outline,
                ),
              ),
          ],
        ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS (tất cả test, kể cả test mới)

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/match_card.dart test/widget_test.dart
git commit -m "feat: show edge/value badge on 1x2 odds buttons"
```

---

### Task 7: Disclaimer "Về chỉ số Edge"

**Files:**
- Modify: `lib/screens/sportsbook_screen.dart`
- Test: thêm vào `test/widget_test.dart`

**Interfaces:**
- Không thêm interface mới — chỉ thêm 1 `IconButton` vào `AppBar.actions`
  của `_SportsbookScreenState` (Task 4) và 1 method riêng tư `_showEdgeInfo`.

- [ ] **Step 1: Write the failing test**

Thêm vào cuối `test/widget_test.dart`:

```dart
  testWidgets('bam icon info hien dialog giai thich Edge', (tester) async {
    await tester.pumpWidget(const HouseEdgeApp(showSplash: false));
    await tester.enterText(find.byType(TextField).at(0), 'demo');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('ĐĂNG NHẬP'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    expect(find.text('Về chỉ số Edge'), findsOneWidget);
    await tester.tap(find.text('Đã hiểu'));
    await tester.pumpAndSettle();
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL — không tìm thấy `Icons.info_outline` trong `AppBar`.

- [ ] **Step 3: Write minimal implementation**

Sửa `AppBar` trong `_SportsbookScreenState.build` (Task 4), thêm `actions`:

```dart
          appBar: AppBar(
            flexibleSpace: Container(
                decoration: const BoxDecoration(gradient: kBrandGradient)),
            titleSpacing: 8,
            title: Row(
              children: [
                const BrandCrest(size: 26),
                const SizedBox(width: 8),
                const Text('MEGA SPORTS',
                    style: TextStyle(
                        fontFamily: kDisplayFont,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    border: Border.all(color: kGold),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                      g.league == League.worldCup
                          ? 'WORLD CUP'
                          : 'CUP CHÂU Á',
                      style: const TextStyle(fontSize: 9, color: kGold)),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showEdgeInfo(context),
              ),
            ],
          ),
```

Thêm method riêng tư trong `_SportsbookScreenState` (sau `build` hoặc trước
`_walletBar`):

```dart
  void _showEdgeInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Về chỉ số Edge'),
        content: const Text(
            'Edge tính từ chênh lệch giữa ước tính chuyên gia và tỷ lệ '
            'ngầm của kèo — không phải lợi nhuận thật. Biên nhà cái '
            '(~5%) vẫn luôn trừ vào kỳ vọng dài hạn, dù Edge dương hay âm.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget_test.dart`
Expected: PASS (toàn bộ file)

- [ ] **Step 5: Commit**

```bash
git add lib/screens/sportsbook_screen.dart test/widget_test.dart
git commit -m "feat: add edge disclaimer dialog to sportsbook app bar"
```

---

### Task 8: Kiểm tra toàn diện + `flutter analyze`

**Files:** không tạo/sửa file mới — chỉ chạy kiểm tra toàn bộ.

- [ ] **Step 1: Chạy phân tích tĩnh**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: Chạy toàn bộ test suite**

Run: `flutter test`
Expected: tất cả test PASS (bao gồm các file cũ không liên quan tính năng
này — đảm bảo không phá vỡ hành vi sẵn có).

- [ ] **Step 3: Nếu có lỗi analyze/test, sửa và chạy lại**

Sửa lỗi tại đúng file bị báo, không nới lỏng test hay dùng `--no-verify`.
Chạy lại Step 1-2 đến khi sạch.

- [ ] **Step 4: Commit (nếu có sửa đổi từ Step 3)**

```bash
git add -A
git commit -m "fix: address analyzer/test issues from bet finder + value indicator"
```

## Sau khi hoàn thành plan

Theo Git Flow của CLAUDE.md: push branch `feat/bet-finder-value-indicator`
lên remote, mở Pull Request vào `dev` (mô tả rõ làm gì + test thế nào), chờ
review trước khi merge (squash and merge).
