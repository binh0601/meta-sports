# UI Glow-Up — Splash, World Cup, Effects "10k-dollar" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Nâng giao diện lên chuẩn sportsbook thương mại: splash động, font gaming, giải World Cup song song, match card v2 phát sáng, hero carousel ảnh action, hiệu ứng tiền + micro-interactions.

**Design system đã chốt (ui-ux-pro-max):** pattern Immersive, style Vibrant & Block-based, GIỮ brand xanh royal + gold hiện có; font display **Russo One**, body **Chakra Petch**; hiệu ứng 150-300ms, chỉ animate transform/opacity, mỗi màn 1-2 hiệu ứng chủ đạo; tôn trọng `MediaQuery.disableAnimations`.

**User đã chốt:** 2 giải song song (Cup Châu Á + World Cup 2026, tab chuyển); phạm vi đủ 3 lớp A+B+C.

## Global Constraints

- Branch: `feat/ui-glow-up` (từ `dev`). PR vào `dev`. KHÔNG commit thẳng main/dev.
- Sau mỗi task: `flutter analyze` sạch + full `flutter test` pass + commit conventional.
- Flutter chạy qua Windows: `/mnt/c/Windows/System32/cmd.exe /c "cd /d D:\FPTk8\PRM\PE_PRM393_EXAMPLE\DeTest\DeTest\house_edge_demo && D:\FPTk8\PRM\flutter\bin\flutter.bat <cmd>"`. Git qua git.exe gọi thẳng từ bash. Test theo FILE, không --plain-name.
- Widget test KHÔNG dùng pumpAndSettle trên cây chứa SportsbookScreen (SpinningBallIcon lặp vô hạn) — dùng bounded pumps như test hiện có.
- Animation lặp vô hạn PHẢI cancel/dispose controller trong dispose() (tránh pending-timer trong test).
- Chuỗi UI tiếng Việt có dấu; comment code tiếng Việt không dấu; file mới <200 dòng.
- KHÔNG đụng google-services.json, không hardcode key.
- Hiệu ứng: chỉ transform/opacity; duration 150-300ms (splash được phép ~1800ms tổng); mọi hiệu ứng lặp/splash skip khi `MediaQuery.of(context).disableAnimations`.
- UI task được phép tinh chỉnh giá trị thị giác (màu alpha, blur, offset) quanh spec ±20% — logic/interface thì tuân thủ đúng.

---

### Task 1: Tải assets — fonts, cờ World Cup, ảnh action

**Files:**
- Create: `assets/fonts/RussoOne-Regular.ttf`, `assets/fonts/ChakraPetch-Regular.ttf`, `assets/fonts/ChakraPetch-Bold.ttf`
- Create: 16 cờ mới trong `assets/flags/` (list dưới)
- Create: `assets/images/action_worldcup.jpg`, `assets/images/action_stadium_flare.jpg`
- Modify: `pubspec.yaml` (khai báo fonts + assets/fonts/)

**Interfaces:**
- Produces: font family `'RussoOne'` và `'ChakraPetch'` dùng được trong ThemeData; cờ `assets/flags/<code>.png` cho các code: `de fr gb-eng es it pt nl be hr dk br ar uy us mx ma`; 2 ảnh action nền hero.

- [ ] **Step 1: Tải fonts** (nguồn: repo google/fonts trên GitHub, license OFL):
```bash
cd /mnt/d/FPTk8/PRM/PE_PRM393_EXAMPLE/DeTest/DeTest/house_edge_demo
mkdir -p assets/fonts
curl -fsSL -o assets/fonts/RussoOne-Regular.ttf "https://github.com/google/fonts/raw/main/ofl/russoone/RussoOne-Regular.ttf"
curl -fsSL -o assets/fonts/ChakraPetch-Regular.ttf "https://github.com/google/fonts/raw/main/ofl/chakrapetch/ChakraPetch-Regular.ttf"
curl -fsSL -o assets/fonts/ChakraPetch-Bold.ttf "https://github.com/google/fonts/raw/main/ofl/chakrapetch/ChakraPetch-Bold.ttf"
```
Verify: mỗi file `file <path>` ra "TrueType Font" và >50KB. Nếu URL 404, tìm đường dẫn đúng trong repo google/fonts (WebSearch/WebFetch) — KHÔNG bịa URL.

- [ ] **Step 2: Tải 16 cờ World Cup** (flagcdn.com, public domain, w80):
```bash
for c in de fr gb-eng es it pt nl be hr dk br ar uy us mx ma; do
  curl -fsSL -o "assets/flags/$c.png" "https://flagcdn.com/w80/$c.png"; done
```
Verify: 16 file, mỗi file `file` ra PNG và >1KB.

- [ ] **Step 3: Tải 2 ảnh action** — nguồn Wikimedia Commons (CC/PD) hoặc nguồn free-license khác, chủ đề: cầu thủ sút bóng/ăn mừng (đặt `action_worldcup.jpg`), sân vận động pháo sáng/đèn flare (đặt `action_stadium_flare.jpg`). Dùng WebSearch tìm file Commons phù hợp rồi curl bản ~1200px. Verify: JPEG, 60KB-800KB, xem được (không phải HTML lỗi). Nếu sau 3 lần không tải được ảnh hợp lệ → fallback: copy `stadium_night.jpg` thành 2 tên trên (app vẫn chạy, ghi concern trong report).

- [ ] **Step 4: Khai báo pubspec** — thêm vào `flutter:` (giữ assets dir sẵn có, thêm fonts):
```yaml
  assets:
    - assets/flags/
    - assets/images/
    - assets/fonts/
  fonts:
    - family: RussoOne
      fonts:
        - asset: assets/fonts/RussoOne-Regular.ttf
    - family: ChakraPetch
      fonts:
        - asset: assets/fonts/ChakraPetch-Regular.ttf
        - asset: assets/fonts/ChakraPetch-Bold.ttf
          weight: 700
```

- [ ] **Step 5: `flutter.bat pub get` OK + `flutter.bat analyze` sạch + full test pass. Commit:**
```bash
git add assets/ pubspec.yaml
git commit -m "feat: bundle gaming fonts, world cup flags and action imagery"
```

---

### Task 2: Logic — giải đấu World Cup song song (TDD)

**Files:**
- Modify: `lib/logic/football_market.dart`, `lib/logic/game_state.dart`
- Test: `test/football_market_test.dart` (thêm case), `test/game_state_wallet_test.dart` HOẶC file mới `test/league_switch_test.dart`

**Interfaces:**
- Produces: `enum League { asianCup, worldCup }` với extension `label` ('CUP CHÂU Á 2026' / 'WORLD CUP 2026'); `generateRound(Random rng, int startId, {League league = League.asianCup})`; `GameState.league` (mặc định asianCup), `bool switchLeague(League l)` — false + không đổi gì khi `pending.isNotEmpty`; switch thành công: sinh trận mới theo giải, clear slip + lastResults, `roundPlayed = false`, giữ nguyên balance/wallet/roundNumber, notifyListeners.

- [ ] **Step 1: Test fail trước** (file `test/league_switch_test.dart`):
```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/football_market.dart';
import 'package:house_edge_demo/logic/game_state.dart';

void main() {
  test('generateRound theo giai: world cup ra doi Au-My', () {
    final wc = generateRound(Random(1), 1, league: League.worldCup);
    final teams = wc.expand((m) => [m.home, m.away]).toSet();
    expect(teams.contains('Brazil') || teams.contains('Đức'), true);
    expect(teams.contains('Việt Nam'), false);
    expect(wc.length, 8);
  });

  test('switchLeague doi tran, giu vi, clear slip', () {
    final g = GameState();
    g.toggleSelection(g.matches.first, true);
    final balanceBefore = g.balance;
    expect(g.switchLeague(League.worldCup), true);
    expect(g.league, League.worldCup);
    expect(g.slip, isEmpty);
    expect(g.balance, balanceBefore);
    final teams = g.matches.expand((m) => [m.home, m.away]).toSet();
    expect(teams.contains('Việt Nam'), false);
  });

  test('con phieu pending -> khong cho doi giai', () {
    final g = GameState();
    g.toggleSelection(g.matches.first, true);
    g.setStake(100);
    g.placeBet();
    expect(g.switchLeague(League.worldCup), false);
    expect(g.league, League.asianCup);
  });
}
```
Run FAIL (League chưa tồn tại).

- [ ] **Step 2: football_market.dart** — thêm sau `_teams`:
```dart
/// Giai dau: 2 pool doi khac nhau, cung co che odds.
enum League { asianCup, worldCup }

extension LeagueInfo on League {
  String get label =>
      this == League.asianCup ? 'CUP CHÂU Á 2026' : 'WORLD CUP 2026';
}

/// 16 doi Au-My cho World Cup — co tai tu flagcdn (Task 1).
const List<(String, String)> _wcTeams = [
  ('Đức', 'de'), ('Pháp', 'fr'), ('Anh', 'gb-eng'), ('Tây Ban Nha', 'es'),
  ('Ý', 'it'), ('Bồ Đào Nha', 'pt'), ('Hà Lan', 'nl'), ('Bỉ', 'be'),
  ('Croatia', 'hr'), ('Đan Mạch', 'dk'), ('Brazil', 'br'),
  ('Argentina', 'ar'), ('Uruguay', 'uy'), ('Mỹ', 'us'),
  ('Mexico', 'mx'), ('Morocco', 'ma'),
];
```
`generateRound` thêm param `{League league = League.asianCup}`, chọn pool `league == League.worldCup ? _wcTeams : _teams` (giữ nguyên phần còn lại).

- [ ] **Step 3: game_state.dart** — field `League league = League.asianCup;`; các chỗ gọi `generateRound(_rng, X)` thêm `league: league`; thêm method:
```dart
  /// Doi giai dau. Tra ve false khi con phieu cho ket qua (tien dang nam
  /// trong cuoc — khong duoc doi san).
  bool switchLeague(League l) {
    if (pending.isNotEmpty) return false;
    if (l == league) return true;
    league = l;
    matches = generateRound(_rng, roundNumber * 100, league: league);
    slip.clear();
    lastResults = [];
    roundPlayed = false;
    notifyListeners();
    return true;
  }
```

- [ ] **Step 4: Test PASS + analyze sạch + full suite. Commit:**
```bash
git add lib/logic/football_market.dart lib/logic/game_state.dart test/league_switch_test.dart
git commit -m "feat: parallel world cup league with guarded league switching"
```

---

### Task 3: Splash screen động

**Files:**
- Create: `lib/screens/splash_screen.dart`
- Modify: `lib/main.dart`
- Test: `test/widget_test.dart` (thêm 1 test splash; test cũ giữ nguyên nhờ cờ `showSplash: false`)

**Interfaces:**
- Produces: `SplashScreen({required Widget next})` — tự `pushReplacement` sang `next` sau ~1.8s hoặc khi user tap; khi `MediaQuery.disableAnimations` → chuyển ngay lập tức. `HouseEdgeApp` thêm `final bool showSplash` (default `true`); `home = showSplash ? SplashScreen(next: <man cu>) : <man cu>`.

- [ ] **Step 1: Test trước** (thêm vào widget_test.dart — các test cũ pump `HouseEdgeApp(showSplash: false)`? KHÔNG — giữ nguyên `const HouseEdgeApp()` sẽ hiện splash và phá test cũ. Cách làm: default `showSplash = true`, NHƯNG mọi test cũ đổi sang `const HouseEdgeApp(showSplash: false)` bằng find-replace `const HouseEdgeApp()` → `const HouseEdgeApp(showSplash: false)`. Thêm test mới):
```dart
  testWidgets('splash hien logo roi tu vao man dang nhap', (tester) async {
    await tester.pumpWidget(const HouseEdgeApp());
    expect(find.text('MEGA SPORTS'), findsOneWidget); // splash logo
    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget); // sang login
  });
```
Run FAIL trước, PASS sau khi implement.

- [ ] **Step 2: splash_screen.dart** — StatefulWidget, SingleTickerProviderStateMixin:
  - Nền: `kBrandGradient` full màn + `Image.asset('assets/images/stadium_night.jpg')` opacity .25.
  - `AnimationController` ~1400ms: BrandCrest (size 84) scale 0.6→1.0 elastic-out + fade-in; chữ 'MEGA SPORTS' (fontFamily 'RussoOne', size 34, letterSpacing 4, trắng) fade + slide lên; dưới cùng `SpinningBallIcon(size: 26, color: kGold)` + text 'CUP CHÂU Á • WORLD CUP 2026' (fontSize 11, gold, letterSpacing 2).
  - Shimmer quét: ShaderMask LinearGradient trắng alpha .35 translate -1→2 chạy 1 lần qua chữ (dùng cùng controller, Interval(0.5, 1.0)).
  - Sau 1800ms (Timer, cancel trong dispose) hoặc onTap toàn màn → `_go()`: `Navigator.pushReplacement` MaterialPageRoute sang `widget.next` (guard `_navigated` bool tránh gọi 2 lần).
  - `initState`: nếu sau frame đầu `MediaQuery.of(context).disableAnimations` → `_go()` ngay (dùng addPostFrameCallback).
  - File <170 dòng.

- [ ] **Step 3: main.dart** — thêm field + route như Interfaces. Import splash_screen.

- [ ] **Step 4: analyze + full test (test cũ đã chuyển showSplash:false) PASS. Commit:**
```bash
git add lib/screens/splash_screen.dart lib/main.dart test/widget_test.dart
git commit -m "feat: animated splash screen with shimmer brand intro"
```

---

### Task 4: Typography gaming toàn app

**Files:**
- Modify: `lib/main.dart` (ThemeData), `lib/theme/brand_colors.dart` (thêm helper style)

**Interfaces:**
- Produces: ThemeData `fontFamily: 'ChakraPetch'`; `brand_colors.dart` thêm:
```dart
/// Chu display kieu esports cho tieu de, odds, so tien.
const String kDisplayFont = 'RussoOne';

TextStyle displayStyle({double size = 20, Color color = Colors.white,
        double spacing = 1}) =>
    TextStyle(fontFamily: kDisplayFont, fontSize: size, color: color,
        letterSpacing: spacing);
```

- [ ] **Step 1:** main.dart ThemeData thêm `fontFamily: 'ChakraPetch'`. brand_colors.dart thêm block trên.
- [ ] **Step 2:** Áp `kDisplayFont` vào các điểm nhấn (sửa tại chỗ, mỗi chỗ 1 dòng thêm `fontFamily: kDisplayFont`):
  - `sportsbook_screen.dart`: title 'MEGA SPORTS', số dư `AnimatedMoneyText` style.
  - `match_card.dart` OddsSelectButton: dòng odds `@x.xx`.
  - `wallet_screen.dart`: số dư lớn trong `_balanceCard`.
  - `match_detail_screen.dart`: tỷ số/giờ đá ở hero (`fontSize 26` hiện tại).
  - `login_screen.dart`: chữ 'MEGA SPORTS' (đọc file tìm đúng chỗ).
- [ ] **Step 3:** analyze + full test PASS (chú ý test tìm text theo string — không đổi string nào). Commit:
```bash
git add lib/main.dart lib/theme/brand_colors.dart lib/screens/sportsbook_screen.dart lib/widgets/match_card.dart lib/screens/wallet_screen.dart lib/screens/match_detail_screen.dart lib/screens/login_screen.dart
git commit -m "feat: esports display typography across brand surfaces"
```

---

### Task 5: Sảnh kèo v2 — tab giải + match card phát sáng + hero theo giải

**Files:**
- Create: `lib/widgets/league_switcher.dart`
- Modify: `lib/screens/sportsbook_screen.dart`, `lib/widgets/hero_banner.dart`, `lib/widgets/match_card.dart`, `lib/widgets/motion_effects.dart`
- Test: `test/widget_test.dart` (+1 test đổi giải)

**Interfaces:**
- Consumes: `gameState.league`, `gameState.switchLeague`, `League.label` (Task 2); ảnh Task 1.
- Produces: `LeagueSwitcher()` widget (2 pill: CUP CHÂU Á / WORLD CUP 2026, active = gradient brand + viền gold, inactive = surface; bấm khi có pending → SnackBar 'Đá xong vòng này mới đổi giải được.'); `HeroBanner({required int roundNumber, required League league})`; `PulseDot(color)` trong motion_effects (chấm 6px scale 1→1.35 + fade lặp 1.2s, controller dispose đúng).

- [ ] **Step 1: Test trước** (widget_test.dart, sau login demo bounded pumps):
```dart
  testWidgets('doi giai sang World Cup doi label va doi bong', (tester) async {
    await tester.pumpWidget(const HouseEdgeApp(showSplash: false));
    await tester.enterText(find.byType(TextField).at(0), 'demo');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('ĐĂNG NHẬP'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('WORLD CUP 2026').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(gameState.league, League.worldCup);
  });
```
(import football_market nếu thiếu). FAIL trước.

- [ ] **Step 2: league_switcher.dart** (~80 dòng): Row 2 `Expanded` pill, `AnimatedContainer` 200ms, ScaleTap; onTap: `final ok = gameState.switchLeague(l); if (!ok) ScaffoldMessenger...showSnackBar(...)`. Label dùng `displayStyle(size: 11, spacing: 1.5)`.

- [ ] **Step 3: sportsbook_screen.dart**: chèn `const LeagueSwitcher()` + SizedBox(8) ngay TRƯỚC `PromoBannerCarousel` (trong Padding hiện có); `HeroBanner(roundNumber: g.roundNumber, league: g.league)`; badge cạnh title 'MEGA SPORTS' đổi text cứng 'CUP CHÂU Á' → `g.league == League.worldCup ? 'WORLD CUP' : 'CUP CHÂU Á'` (import football_market).

- [ ] **Step 4: hero_banner.dart**: nhận `league`; ảnh `league == League.worldCup ? 'assets/images/action_worldcup.jpg' : 'assets/images/player_volley.jpg'`; label chip = `league.label`; thêm **Ken Burns**: bọc ảnh trong widget `_KenBurns` nội bộ (AnimationController 9s repeat(reverse: true), scale 1.0→1.08, alignment giữ nguyên; skip repeat khi disableAnimations — build ảnh tĩnh). Controller dispose chuẩn.

- [ ] **Step 5: match_card.dart**: (a) trong `_centerBadge`, khi `!match.played`: thay text 'HÔM NAY' bằng Row [PulseDot(Colors.lightGreen), 4px, Text('MỞ CƯỢC', xanh lá)]; (b) OddsSelectButton `AnimatedContainer` thêm khi `selected`: `boxShadow: [BoxShadow(color: kGold.withValues(alpha: .45), blurRadius: 14, spreadRadius: 1)]`; cờ tăng 30x20 → 34x23.

- [ ] **Step 6: motion_effects.dart** thêm `PulseDot` (StatefulWidget ~35 dòng, controller repeat, dispose cancel; khi disableAnimations → chấm tĩnh).

- [ ] **Step 7:** analyze + full test PASS (test cũ 'admin', 'demo' vẫn chạy — LeagueSwitcher mount thêm controller lặp? PulseDot lặp → giống SpinningBallIcon, bounded pumps OK). Commit:
```bash
git add lib/widgets/league_switcher.dart lib/widgets/hero_banner.dart lib/widgets/match_card.dart lib/widgets/motion_effects.dart lib/screens/sportsbook_screen.dart test/widget_test.dart
git commit -m "feat: league switcher, glowing odds and ken burns hero"
```

---

### Task 6: Banner shimmer + hiệu ứng tiền bay

**Files:**
- Modify: `lib/widgets/promo_banner_carousel.dart`, `lib/screens/sportsbook_screen.dart` (wallet bar)
- Create: `lib/widgets/coin_burst.dart`

**Interfaces:**
- Consumes: `gameState.balance`.
- Produces: `CoinBurst({required Widget child})` — bọc wallet bar; theo dõi `gameState.balance`, khi TĂNG: bắn 4 icon `Icons.monetization_on` (gold, 14px) bay lên 28px + fade 500ms từ vị trí số dư (Stack overlay, mỗi coin lệch ngang ±12px, stagger 60ms), rồi tự dọn. Không dùng timer lặp — one-shot controller, dispose an toàn.

- [ ] **Step 1: promo_banner_carousel.dart** — thêm shimmer sweep trên banner active: Positioned.fill IgnorePointer + AnimationController 2600ms repeat (dispose cancel; disableAnimations → bỏ) → Transform.translate dx từ -width→width một dải `Container(width: 60, decoration: gradient trắng alpha 0→.18→0, transform xiên -0.3 rad)`. Chỉ 1 lớp shimmer chung cho cả PageView (không per-item).
- [ ] **Step 2: coin_burst.dart** (~90 dòng) như Interfaces; lắng nghe qua `ListenableBuilder(listenable: gameState)` — lưu `_lastBalance`, so sánh trong build, trigger bằng addPostFrameCallback (tránh setState trong build).
- [ ] **Step 3: sportsbook_screen.dart** — bọc Row trong `_walletBar` bằng `CoinBurst(child: ...)`.
- [ ] **Step 4:** analyze + full test PASS (coin burst one-shot không treo test). Commit:
```bash
git add lib/widgets/promo_banner_carousel.dart lib/widgets/coin_burst.dart lib/screens/sportsbook_screen.dart
git commit -m "feat: banner shimmer sweep and coin burst on balance gain"
```

---

### Task 7: Hiệu ứng luồng cược — nút đặt, thắng glow, thua rung

**Files:**
- Modify: `lib/widgets/bet_slip_panel.dart` và/hoặc `lib/widgets/bet_slip_drawer.dart` (đọc cả 2 trước, tìm nút 'Đặt cược' và chỗ render kết quả `lastResults`)
- Modify: `lib/widgets/motion_effects.dart` (thêm `ShakeOnce`)

**Interfaces:**
- Produces: `ShakeOnce({required Widget child})` trong motion_effects — one-shot: translate X sine ±6px, 350ms, chạy 1 lần khi mount (disableAnimations → tĩnh). Nút đặt cược khi `canPlaceBet`: glow gold `boxShadow blurRadius 12 alpha .4` (AnimatedContainer 250ms). Card kết quả: phiếu `won` → `Border.all(Colors.lightGreen)` + boxShadow xanh alpha .35; phiếu thua → bọc `ShakeOnce`.

- [ ] **Step 1:** Đọc bet_slip_panel.dart + bet_slip_drawer.dart, xác định đúng widget nút đặt và list kết quả (kết quả có thể nằm ở sportsbook/lastResults render — grep `lastResults` để tìm nơi hiển thị).
- [ ] **Step 2:** Thêm ShakeOnce vào motion_effects (~40 dòng, controller forward 1 lần, dispose chuẩn).
- [ ] **Step 3:** Áp glow nút đặt + hiệu ứng thắng/thua như Interfaces (đúng nơi tìm được ở Step 1; nếu kết quả hiển thị dạng SnackBar/section khác, áp vào container từng phiếu trong `lastResults`).
- [ ] **Step 4:** analyze + full test PASS. Commit:
```bash
git add lib/widgets/motion_effects.dart lib/widgets/bet_slip_panel.dart lib/widgets/bet_slip_drawer.dart <file kết quả nếu khác>
git commit -m "feat: bet flow effects - glow cta, win glow, lose shake"
```

---

### Task 8: AI typing effect + chốt nhánh

**Files:**
- Modify: `lib/widgets/ai_analysis_card.dart`
- Cuối: full check + push + PR

**Interfaces:**
- Produces: khi kết quả phân tích hiện ra, text chạy kiểu gõ máy ~700ms (TweenAnimationBuilder<int> 0→text.length, substring; disableAnimations → hiện full ngay). Badge nguồn fade-in sau khi gõ xong.

- [ ] **Step 1:** Sửa ai_analysis_card: thay `Text(r.text)` bằng widget nội bộ `_TypewriterText(text)` (~30 dòng).
- [ ] **Step 2:** analyze + full test PASS.
- [ ] **Step 3:** Chạy app trên emulator xác nhận bằng mắt: splash → login → sảnh (tab giải, banner shimmer, hero Ken Burns) → đổi World Cup → chọn odds glow → đặt cược → đá vòng (coin burst + win glow/lose shake) → AI typing.
- [ ] **Step 4:** Push + PR:
```bash
git push -u origin feat/ui-glow-up
```
PR vào `dev`: mô tả 3 lớp A/B/C, ảnh chụp màn hình, cách test.

---

## Ghi chú cho người thực thi
- Emulator chỉ 2-4GB RAM: không dùng BackdropFilter/blur động; RepaintBoundary quanh Ken Burns + shimmer nếu thấy jank.
- `game_state.dart` sẽ ~260 dòng sau Task 2 — chấp nhận, KHÔNG tách file trong plan này.
- Mọi controller lặp vô hạn: bắt buộc dispose; test dùng bounded pumps.
- Không đổi bất kỳ chuỗi nào test cũ đang assert ('MEGA SPORTS', 'ĐĂNG NHẬP', 'Nạp / Rút tiền', 'Chơi lại từ đầu'...).
