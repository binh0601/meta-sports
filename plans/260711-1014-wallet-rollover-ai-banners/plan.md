# Wallet Rollover + AI Match Analysis + Promo Banners — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ví 500k + rollover 5× (nạp tự do, rút giả lập), tài khoản demo 10 triệu, AI phân tích trận (local + Groq), carousel banner khuyến mãi.

**Architecture:** Logic ví tách vào `wallet_rules.dart` (Dart thuần), `GameState` tích hợp mỏng, `AuthState` thêm bypass `demo`. AI: bộ sinh local từ `MatchInsights` + service Groq fallback. Banner: widget PageView tự vẽ.

**Tech Stack:** Flutter, Firebase (Firestore đã có), package `http` (mới, chỉ cho Groq).

**Spec:** `docs/superpowers/specs/2026-07-11-wallet-rollover-ai-analysis-promo-banners-design.md`

## Global Constraints

- Branch làm việc: `feat/wallet-rollover-ai-banners` (đã tạo). KHÔNG commit lên `main` — theo Git Flow trong `CLAUDE.md`.
- Đơn vị tiền toàn app: **nghìn đồng (k)** — `500` nghĩa là 500k, `10000` là 10 triệu.
- Rollover: `rolloverMultiplier = 5`, không điều kiện odds tối thiểu.
- Chuỗi UI tiếng Việt; tên biến/hàm tiếng Anh. File <~200 dòng. Logic tiền trong `lib/logic/` không import Flutter.
- Sau mỗi task: `flutter analyze` sạch, `flutter test` pass, commit conventional commit.
- Chạy test trên Windows: chạy cả file (`flutter test test/wallet_rules_test.dart`), KHÔNG dùng `--plain-name`.
- API key Groq: chỉ qua `--dart-define=GROQ_API_KEY=...`, không hardcode/commit.

---

### Task 1: WalletRules — logic rollover thuần Dart

**Files:**
- Create: `lib/logic/wallet_rules.dart`
- Test: `test/wallet_rules_test.dart`

**Interfaces:**
- Produces: `class WalletRules { double totalFunded; double totalWagered; double get requirement; double get remaining; double get progress; void deposit(double); void recordWager(double); bool canWithdraw({required double balance, required bool hasPending}); String? withdrawBlockReason({required double balance, required bool hasPending}); void resetAfterWithdraw(); void reset(double initialFund); static const int rolloverMultiplier = 5; }`

- [ ] **Step 1: Viết test fail trước**

```dart
// test/wallet_rules_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/wallet_rules.dart';

void main() {
  test('cap 500 -> can cuoc 2500 moi duoc rut', () {
    final w = WalletRules(totalFunded: 500);
    expect(w.requirement, 2500);
    expect(w.remaining, 2500);
    expect(w.canWithdraw(balance: 500, hasPending: false), false);
  });

  test('nap 200 -> requirement tang them 1000', () {
    final w = WalletRules(totalFunded: 500)..deposit(200);
    expect(w.totalFunded, 700);
    expect(w.requirement, 3500);
  });

  test('cuoc du 5x -> duoc rut khi vi con tien va khong pending', () {
    final w = WalletRules(totalFunded: 500)..recordWager(2500);
    expect(w.canWithdraw(balance: 300, hasPending: false), true);
    expect(w.withdrawBlockReason(balance: 300, hasPending: false), null);
  });

  test('du rollover nhung con phieu pending -> chua duoc rut', () {
    final w = WalletRules(totalFunded: 500)..recordWager(2500);
    expect(w.canWithdraw(balance: 300, hasPending: true), false);
    expect(w.withdrawBlockReason(balance: 300, hasPending: true),
        contains('phiếu chờ'));
  });

  test('vi rong -> khong rut duoc, ly do bao nap tien', () {
    final w = WalletRules(totalFunded: 500)..recordWager(2500);
    expect(w.canWithdraw(balance: 0, hasPending: false), false);
    expect(w.withdrawBlockReason(balance: 0, hasPending: false),
        contains('nạp'));
  });

  test('chua du rollover -> ly do neu ro so tien can cuoc them', () {
    final w = WalletRules(totalFunded: 500)..recordWager(1000);
    expect(w.withdrawBlockReason(balance: 400, hasPending: false),
        contains('cược thêm'));
    expect(w.remaining, 1500);
  });

  test('rut xong reset ve 0, nap moi tao requirement moi', () {
    final w = WalletRules(totalFunded: 500)..recordWager(2500);
    w.resetAfterWithdraw();
    expect(w.totalFunded, 0);
    expect(w.requirement, 0);
    w.deposit(100);
    expect(w.requirement, 500);
    expect(w.canWithdraw(balance: 100, hasPending: false), false);
  });

  test('progress bi chan trong [0,1]', () {
    final w = WalletRules(totalFunded: 500)..recordWager(9999);
    expect(w.progress, 1.0);
    expect(WalletRules(totalFunded: 0).progress, 0.0);
  });
}
```

- [ ] **Step 2: Chạy test — phải FAIL**

Run: `flutter test test/wallet_rules_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'house_edge_demo/logic/wallet_rules.dart'` (file chưa tồn tại).

- [ ] **Step 3: Viết implementation**

```dart
// lib/logic/wallet_rules.dart
import 'dart:math';

import 'betting_math.dart';

/// Quy tac rollover cua nha cai: tien duoc cap/nap phai duoc dat cuoc
/// du [rolloverMultiplier] lan truoc khi cho rut — mo phong dieu khoan
/// bonus that (giu chan nguoi choi nop tien cho house edge nhieu vong).
/// Thuan Dart, khong import Flutter — de unit test.
class WalletRules {
  static const int rolloverMultiplier = 5;

  double totalFunded; // tong tien duoc cap + da nap (k)
  double totalWagered; // tong tien da dat cuoc (k)

  WalletRules({this.totalFunded = 0, this.totalWagered = 0});

  /// Tong tien phai cuoc de duoc rut.
  double get requirement => totalFunded * rolloverMultiplier;

  /// Con phai cuoc them bao nhieu (0 khi da du).
  double get remaining => max(0, requirement - totalWagered);

  /// Tien do rollover 0..1 (ve progress bar).
  double get progress =>
      requirement <= 0 ? 0 : min(1, totalWagered / requirement);

  void deposit(double amount) => totalFunded += amount;

  void recordWager(double stake) => totalWagered += stake;

  bool canWithdraw({required double balance, required bool hasPending}) =>
      withdrawBlockReason(balance: balance, hasPending: hasPending) == null;

  /// Ly do chua duoc rut (tieng Viet, hien tren UI) — null la duoc rut.
  String? withdrawBlockReason(
      {required double balance, required bool hasPending}) {
    if (balance <= 0) return 'Ví trống — nạp tiền để chơi tiếp.';
    if (hasPending) {
      return 'Còn phiếu chờ kết quả — đá xong vòng này mới được rút.';
    }
    if (totalWagered < requirement) {
      return 'Cần cược thêm ${fmtMoney(remaining)} nữa mới đủ điều kiện rút '
          '(đã cược ${fmtMoney(totalWagered)}/${fmtMoney(requirement)}).';
    }
    return null;
  }

  /// Sau khi rut toan bo: ve 0, muon choi tiep phai nap moi.
  void resetAfterWithdraw() {
    totalFunded = 0;
    totalWagered = 0;
  }

  /// Choi lai tu dau voi so tien cap moi.
  void reset(double initialFund) {
    totalFunded = initialFund;
    totalWagered = 0;
  }
}
```

- [ ] **Step 4: Chạy test — phải PASS**

Run: `flutter test test/wallet_rules_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/logic/wallet_rules.dart test/wallet_rules_test.dart
git commit -m "feat: add wallet rollover rules (5x wagering requirement)"
```

---

### Task 2: GameState — cấp 500k, tích hợp ví, nạp/rút, chế độ demo

**Files:**
- Modify: `lib/logic/game_state.dart`

**Interfaces:**
- Consumes: `WalletRules` (Task 1).
- Produces: `GameState.startBalance == 500`, `GameState.demoBalance == 10000`, `wallet` (WalletRules), `bool isDemoWallet`, `void attachDemo()`, `void deposit(double amount)`, `double withdrawAll()`. `placeBet()` tự ghi `wallet.recordWager(stake)`.

- [ ] **Step 1: Sửa hằng số + field**

Trong `lib/logic/game_state.dart`, thêm import và đổi phần đầu class:

```dart
import 'wallet_rules.dart';   // them vao cum import logic
```

```dart
// THAY dong: static const double startBalance = 10000; // 10 trieu (don vi k)
  static const double startBalance = 500; // 500k cap cho tai khoan moi
  static const double demoBalance = 10000; // 10 trieu — rieng tai khoan demo

// THEM sau dong "List<FootballMatch> matches = [];":
  final WalletRules wallet = WalletRules(totalFunded: startBalance);
  bool isDemoWallet = false; // true khi dang nhap tai khoan demo/123456
```

- [ ] **Step 2: Sửa `_resetLocal` dùng số dư theo chế độ**

```dart
  void _resetLocal() {
    balance = isDemoWallet ? demoBalance : startBalance;
    wallet.reset(balance);
    roundNumber = 1;
    roundPlayed = false;
    matches = generateRound(_rng, 1);
    slip.clear();
    pending.clear();
    settled.clear();
    lastResults = [];
    balanceHistory
      ..clear()
      ..add(balance);
    notifyListeners();
  }
```

- [ ] **Step 3: Thêm `attachDemo`, sửa `detachUser`, `attachUser`**

```dart
  /// Dang nhap tai khoan demo (khong Firebase): vi 10 trieu, thuan local.
  void attachDemo() {
    _uid = null;
    isDemoWallet = true;
    _resetLocal();
  }

  void detachUser() {
    _uid = null;
    isDemoWallet = false;
    _resetLocal();
  }
```

Trong `attachUser`, sau `roundNumber = profile.roundNumber;` thêm:

```dart
    isDemoWallet = false;
    wallet.totalFunded = profile.totalFunded;
    wallet.totalWagered = profile.totalWagered;
```

(`profile` có 2 field mới từ Task 3 — Task 2 và 3 compile cùng nhau, xem Step 6.)

- [ ] **Step 4: `placeBet` ghi wager; thêm `deposit`/`withdrawAll`**

Trong `placeBet()`, ngay sau `balance -= stake;` thêm:

```dart
    wallet.recordWager(stake);
```

Thêm 2 method mới (đặt sau `playRound`/trước `newRound`):

```dart
  /// Nap tien gia lap: cong vi ngay; moi dong nap keo theo 5x rollover.
  void deposit(double amount) {
    if (amount <= 0) return;
    balance += amount;
    wallet.deposit(amount);
    _saveStateToCloud();
    notifyListeners();
  }

  /// Rut toan bo (gia lap). Tra ve so tien rut duoc, 0 neu chua du dieu kien.
  double withdrawAll() {
    if (!wallet.canWithdraw(
        balance: balance, hasPending: pending.isNotEmpty)) {
      return 0;
    }
    final amount = balance;
    balance = 0;
    wallet.resetAfterWithdraw();
    balanceHistory.add(balance);
    _saveStateToCloud();
    notifyListeners();
    return amount;
  }
```

- [ ] **Step 5: `_saveStateToCloud` gửi thêm 2 field ví**

```dart
  void _saveStateToCloud({bool markReset = false}) {
    final uid = _uid;
    if (uid == null) return;
    PlayerRepository.instance.saveState(uid,
        balance: balance,
        roundNumber: roundNumber,
        totalFunded: wallet.totalFunded,
        totalWagered: wallet.totalWagered,
        markReset: markReset);
  }
```

- [ ] **Step 6: Task 3 (repository) làm ngay sau đó rồi mới compile + test + commit chung** — vì `attachUser`/`saveState` phụ thuộc chữ ký mới.

---

### Task 3: PlayerRepository — 2 field ví trên Firestore (tương thích ngược)

**Files:**
- Modify: `lib/services/player_repository.dart`

**Interfaces:**
- Produces: `loadOrCreateProfile` trả về `({double balance, int roundNumber, double totalFunded, double totalWagered})`; `saveState` nhận thêm `required double totalFunded, required double totalWagered`.

- [ ] **Step 1: Sửa `loadOrCreateProfile`**

```dart
  /// Tra ve profile vi; user moi duoc tao voi [defaultBalance].
  /// Tai khoan cu thieu field vi -> mac dinh totalFunded=500, wagered=0.
  Future<({
    double balance,
    int roundNumber,
    double totalFunded,
    double totalWagered,
  })> loadOrCreateProfile(User user, double defaultBalance) async {
    final ref = _userDoc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'email': user.email,
        'displayName': user.displayName ?? '',
        'balance': defaultBalance,
        'roundNumber': 1,
        'totalFunded': defaultBalance,
        'totalWagered': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return (
        balance: defaultBalance,
        roundNumber: 1,
        totalFunded: defaultBalance,
        totalWagered: 0.0,
      );
    }
    final d = snap.data()!;
    return (
      balance: (d['balance'] as num?)?.toDouble() ?? defaultBalance,
      roundNumber: (d['roundNumber'] as num?)?.toInt() ?? 1,
      totalFunded: (d['totalFunded'] as num?)?.toDouble() ?? defaultBalance,
      totalWagered: (d['totalWagered'] as num?)?.toDouble() ?? 0.0,
    );
  }
```

- [ ] **Step 2: Sửa `saveState`**

```dart
  Future<void> saveState(String uid,
      {required double balance,
      required int roundNumber,
      required double totalFunded,
      required double totalWagered,
      bool markReset = false}) async {
    if (!firebaseReady) return;
    try {
      await _userDoc(uid).set({
        'balance': balance,
        'roundNumber': roundNumber,
        'totalFunded': totalFunded,
        'totalWagered': totalWagered,
        if (markReset) 'resetAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveState loi: $e');
    }
  }
```

- [ ] **Step 3: Compile + toàn bộ test**

Run: `flutter analyze` → Expected: `No issues found!`
Run: `flutter test` → Expected: PASS toàn bộ (test cũ không phụ thuộc 10000).

- [ ] **Step 4: Commit (chung với Task 2)**

```bash
git add lib/logic/game_state.dart lib/services/player_repository.dart
git commit -m "feat: 500k starting balance, deposit/withdraw with rollover, demo wallet mode"
```

---

### Task 4: AuthState — đăng nhập `demo`/`123456`

**Files:**
- Modify: `lib/logic/auth_state.dart`
- Test: `test/widget_test.dart` (thêm 2 case)

**Interfaces:**
- Produces: `authState.isDemo` (bool), login `demo`/`123456` → role player, `gameState.attachDemo()`.

- [ ] **Step 1: Viết test fail (thêm vào cuối `main()` của `test/widget_test.dart`)**

```dart
  testWidgets('demo/123456 -> vao sanh nguoi choi voi vi 10 trieu',
      (tester) async {
    await tester.pumpWidget(const HouseEdgeApp());
    await tester.enterText(find.byType(TextField).at(0), 'demo');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('ĐĂNG NHẬP'));
    await tester.pumpAndSettle();
    expect(find.text('MEGA SPORTS'), findsOneWidget); // san keo
    expect(authState.role, UserRole.player);
    expect(authState.isDemo, true);
    expect(gameState.balance, GameState.demoBalance);
  });

  testWidgets('demo sai mat khau -> bao loi', (tester) async {
    await tester.pumpWidget(const HouseEdgeApp());
    await tester.enterText(find.byType(TextField).at(0), 'demo');
    await tester.enterText(find.byType(TextField).at(1), 'sai');
    await tester.tap(find.text('ĐĂNG NHẬP'));
    await tester.pumpAndSettle();
    expect(find.text('Sai mật khẩu demo.'), findsOneWidget);
    expect(authState.isLoggedIn, false);
  });
```

Thêm import nếu thiếu: `import 'package:house_edge_demo/logic/game_state.dart';`

- [ ] **Step 2: Chạy test — phải FAIL**

Run: `flutter test test/widget_test.dart`
Expected: FAIL — `isDemo` chưa tồn tại / đăng nhập demo báo lỗi Firebase.

- [ ] **Step 3: Sửa `AuthState.loginEmail` + thêm `isDemo`**

Thêm field sau `String username = '';`:

```dart
  bool isDemo = false; // true khi dang nhap tai khoan thu demo/123456
```

Trong `loginEmail`, sau block `admin` thêm block `demo`:

```dart
    if (id.toLowerCase() == 'demo') {
      if (password != '123456') return 'Sai mật khẩu demo.';
      role = UserRole.player;
      username = 'demo';
      isDemo = true;
      gameState.attachDemo();
      notifyListeners();
      return null;
    }
```

Trong `_onPlayerSignedIn` thêm `isDemo = false;` (đầu hàm). Trong `logout()` thêm `isDemo = false;` trước `notifyListeners();`.

- [ ] **Step 4: Chạy test — phải PASS**

Run: `flutter test test/widget_test.dart` → Expected: PASS tất cả.

- [ ] **Step 5: Commit**

```bash
git add lib/logic/auth_state.dart test/widget_test.dart
git commit -m "feat: demo/123456 local login with 10m trial wallet"
```

---

### Task 5: WalletScreen — màn nạp/rút + lối vào từ tab Tôi

**Files:**
- Create: `lib/screens/wallet_screen.dart`
- Modify: `lib/screens/player_profile_screen.dart`
- Test: `test/widget_test.dart` (case ẩn nút với demo)

**Interfaces:**
- Consumes: `gameState.wallet`, `gameState.deposit()`, `gameState.withdrawAll()`, `authState.isDemo`, `fmtMoney` (betting_math).

- [ ] **Step 1: Tạo `lib/screens/wallet_screen.dart`**

```dart
import 'package:flutter/material.dart';

import '../logic/betting_math.dart';
import '../logic/game_state.dart';
import '../theme/brand_colors.dart';

/// Man vi tien: so du, tien do rollover, nap tu do, rut toan bo (gia lap).
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _amountCtrl = TextEditingController();
  String? _inputError;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví của tôi'),
        flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: kBrandGradient)),
      ),
      body: ListenableBuilder(
        listenable: gameState,
        builder: (context, _) {
          final g = gameState;
          final w = g.wallet;
          final blockReason = w.withdrawBlockReason(
              balance: g.balance, hasPending: g.pending.isNotEmpty);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _balanceCard(g.balance),
              const SizedBox(height: 16),
              _rolloverCard(w),
              const SizedBox(height: 16),
              _depositCard(),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.savings),
                label: Text(blockReason == null
                    ? 'Rút toàn bộ ${fmtMoney(g.balance)}'
                    : 'Rút tiền'),
                onPressed: blockReason == null ? _withdraw : null,
              ),
              if (blockReason != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(blockReason,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.error)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _balanceCard(double balance) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: kBrandGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            const Text('SỐ DƯ HIỆN TẠI',
                style: TextStyle(
                    fontSize: 11, letterSpacing: 2, color: Colors.white70)),
            const SizedBox(height: 6),
            Text(fmtMoney(balance),
                style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.w800, color: kGold)),
          ],
        ),
      );

  Widget _rolloverCard(dynamic w) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Điều kiện rút tiền (rollover ×5)',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'Tiền được cấp/nạp phải cược đủ 5 lần trước khi rút — '
                'giống điều khoản khuyến mãi của nhà cái thật.',
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.outline),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                    value: w.progress, minHeight: 10, color: kGold),
              ),
              const SizedBox(height: 6),
              Text(
                'Đã cược ${fmtMoney(w.totalWagered)} / '
                'cần ${fmtMoney(w.requirement)}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );

  Widget _depositCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nạp tiền (giả lập)',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Số tiền (nghìn đồng)',
                        hintText: 'VD: 500 = 500k',
                        errorText: _inputError,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                      onPressed: _deposit, child: const Text('Nạp')),
                ],
              ),
            ],
          ),
        ),
      );

  void _deposit() {
    final v = double.tryParse(_amountCtrl.text.trim());
    if (v == null || v <= 0) {
      setState(() => _inputError = 'Nhập số tiền hợp lệ (> 0).');
      return;
    }
    setState(() => _inputError = null);
    gameState.deposit(v);
    _amountCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Đã nạp ${fmtMoney(v)} — cần cược thêm '
            '${fmtMoney(v * 5)} để đủ điều kiện rút.')));
  }

  void _withdraw() {
    final amount = gameState.withdrawAll();
    if (amount <= 0) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rút tiền thành công 🎉'),
        content: Text('Đã rút ${fmtMoney(amount)} (giả lập — không có '
            'tiền thật). Ví về 0, nạp để chơi tiếp.'),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Lối vào từ tab Tôi (`player_profile_screen.dart`)**

Thêm import: `import 'wallet_screen.dart';`

Trong `Column` phần body (ngay TRƯỚC nút "Chơi lại từ đầu"), thêm:

```dart
                    if (!authState.isDemo) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.account_balance_wallet),
                          label: const Text('Nạp / Rút tiền'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const WalletScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
```

Sửa nút reset cho đúng số dư mới — THAY label và dialog:

```dart
// label nut:  'Chơi lại từ đầu'
// dialog content:
        content: Text('Ví về ${fmtMoney(gameState.isDemoWallet
            ? GameState.demoBalance
            : GameState.startBalance)}, xóa toàn bộ lịch sử cược.'),
```

- [ ] **Step 3: Test ẩn nút với demo (thêm vào `test/widget_test.dart`)**

```dart
  testWidgets('tai khoan demo khong thay nut Nap/Rut o tab Toi',
      (tester) async {
    await tester.pumpWidget(const HouseEdgeApp());
    await tester.enterText(find.byType(TextField).at(0), 'demo');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('ĐĂNG NHẬP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Nạp / Rút tiền'), findsNothing);
    expect(find.text('Chơi lại từ đầu'), findsOneWidget);
  });
```

- [ ] **Step 4: Chạy analyze + full test**

Run: `flutter analyze` → `No issues found!`
Run: `flutter test` → PASS tất cả.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/wallet_screen.dart lib/screens/player_profile_screen.dart test/widget_test.dart
git commit -m "feat: wallet screen with free deposit and rollover-gated withdraw"
```

---

### Task 6: AI phân tích local (`ai_match_analysis.dart`)

**Files:**
- Create: `lib/logic/ai_match_analysis.dart`
- Test: `test/ai_match_analysis_test.dart`

**Interfaces:**
- Consumes: `FootballMatch`, `MatchInsights` (có sẵn).
- Produces: `class AiMatchAnalysis { final String text; final int homeConfidencePct; final String source; }`, `const String kAiDisclaimer`, `AiMatchAnalysis buildLocalAnalysis(FootballMatch m, MatchInsights ins)`.

- [ ] **Step 1: Viết test fail**

```dart
// test/ai_match_analysis_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/ai_match_analysis.dart';
import 'package:house_edge_demo/logic/football_market.dart';
import 'package:house_edge_demo/logic/match_insights.dart';

void main() {
  FootballMatch sample() => generateRound(Random(1), 1).first;

  test('phan tich tat dinh: cung tran -> cung van ban', () {
    final m = sample();
    final a1 = buildLocalAnalysis(m, MatchInsights.of(m));
    final a2 = buildLocalAnalysis(m, MatchInsights.of(m));
    expect(a1.text, a2.text);
    expect(a1.source, 'local');
  });

  test('luon kem disclaimer va nhac ten doi duoc danh gia cao hon', () {
    final m = sample();
    final ins = MatchInsights.of(m);
    final a = buildLocalAnalysis(m, ins);
    expect(a.text, contains(kAiDisclaimer));
    final fav = ins.expertHomePct >= 50 ? m.home : m.away;
    expect(a.text, contains(fav));
    expect(a.homeConfidencePct, ins.expertHomePct);
  });
}
```

- [ ] **Step 2: Chạy test — FAIL** (`flutter test test/ai_match_analysis_test.dart` — package chưa có file).

- [ ] **Step 3: Implementation**

```dart
// lib/logic/ai_match_analysis.dart
import 'dart:math';

import 'football_market.dart';
import 'match_insights.dart';

/// Ket qua phan tich AI cho 1 tran — nguon 'local' (sinh template)
/// hoac 'groq' (goi API that qua AiAnalysisService).
class AiMatchAnalysis {
  final String text;
  final int homeConfidencePct; // % nghieng ve doi nha (theo chuyen gia)
  final String source;
  const AiMatchAnalysis({
    required this.text,
    required this.homeConfidencePct,
    required this.source,
  });
}

/// Dong giao duc bat buoc kem moi phan tich: AI dung den may cung
/// khong thang duoc bien nha cai da tru san trong odds.
const String kAiDisclaimer =
    'Lưu ý: phân tích chuẩn đến mấy thì odds cũng đã trừ biên nhà cái '
    '(~5%) — kỳ vọng dài hạn của người chơi vẫn âm.';

/// Sinh phan tich tu du lieu soi keo co san. Seed theo id tran nen
/// cung mot tran luon ra cung mot bai — demo on dinh, chay offline.
AiMatchAnalysis buildLocalAnalysis(FootballMatch m, MatchInsights ins) {
  final rng = Random(m.id * 31);
  final favHome = ins.expertHomePct >= 50;
  final fav = favHome ? m.home : m.away;
  final dog = favHome ? m.away : m.home;
  final favPct = favHome ? ins.expertHomePct : 100 - ins.expertHomePct;
  int wins(List<bool> form) => form.where((w) => w).length;
  final favWins = wins(favHome ? ins.formHome : ins.formAway);
  final dogWins = wins(favHome ? ins.formAway : ins.formHome);

  final openers = [
    'Dựa trên dữ liệu 5 trận gần nhất và lịch sử đối đầu, ',
    'Tổng hợp phong độ hai đội và tỷ lệ đặt của cộng đồng, ',
    'Mô hình thống kê từ chuỗi trận gần đây cho thấy ',
  ];
  final verdicts = [
    '$fav đang được đánh giá cao hơn với xác suất khoảng $favPct%.',
    'cán cân đang nghiêng về $fav (khoảng $favPct%).',
    '$fav nhỉnh hơn rõ rệt với ~$favPct% cơ hội thắng.',
  ];
  final buffer = StringBuffer()
    ..write(openers[rng.nextInt(openers.length)])
    ..write(verdicts[rng.nextInt(verdicts.length)])
    ..write(' Phong độ gần đây: $fav thắng $favWins/5, '
        '$dog thắng $dogWins/5.')
    ..write(favPct >= 60
        ? ' Kèo chênh lệch — bù lại odds cho $fav sẽ thấp, '
            'ăn ít mỗi lần trúng.'
        : ' Hai đội khá cân bằng nên trận này rủi ro cao hơn.')
    ..write('\n\n$kAiDisclaimer');

  return AiMatchAnalysis(
    text: buffer.toString(),
    homeConfidencePct: ins.expertHomePct,
    source: 'local',
  );
}
```

- [ ] **Step 4: Chạy test — PASS** (`flutter test test/ai_match_analysis_test.dart`).

- [ ] **Step 5: Commit**

```bash
git add lib/logic/ai_match_analysis.dart test/ai_match_analysis_test.dart
git commit -m "feat: deterministic local AI match analysis generator"
```

---

### Task 7: AiAnalysisService — Groq + fallback

**Files:**
- Modify: `pubspec.yaml` (thêm `http`)
- Create: `lib/services/ai_analysis_service.dart`

**Interfaces:**
- Consumes: `buildLocalAnalysis`, `kAiDisclaimer` (Task 6).
- Produces: `AiAnalysisService.instance.analyze(FootballMatch m) → Future<AiMatchAnalysis>` — không bao giờ throw.

- [ ] **Step 1: Thêm dependency**

Trong `pubspec.yaml`, mục `dependencies:` thêm dòng `http: ^1.2.0` (sau `flutter_local_notifications`). Run: `flutter pub get` → Expected: resolve OK.

- [ ] **Step 2: Tạo service**

```dart
// lib/services/ai_analysis_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../logic/ai_match_analysis.dart';
import '../logic/football_market.dart';
import '../logic/match_insights.dart';

/// Phan tich tran bang AI. Co GROQ_API_KEY (--dart-define) -> goi Groq
/// (API chuan OpenAI); khong key / loi / timeout -> tra ban local.
/// Khong bao gio throw. Cache theo id tran trong phien.
class AiAnalysisService {
  AiAnalysisService._();
  static final AiAnalysisService instance = AiAnalysisService._();

  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  final Map<int, AiMatchAnalysis> _cache = {};

  Future<AiMatchAnalysis> analyze(FootballMatch m) async {
    final cached = _cache[m.id];
    if (cached != null) return cached;
    final ins = MatchInsights.of(m);
    final local = buildLocalAnalysis(m, ins);
    if (_apiKey.isEmpty) return _cache[m.id] = local;
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
              'max_tokens': 300,
              'messages': [
                {
                  'role': 'system',
                  'content': 'Bạn là chuyên gia phân tích bóng đá. Viết '
                      'nhận định 4-5 câu tiếng Việt, giọng chuyên môn, '
                      'kết luận nghiêng về đội nào kèm %. Không markdown.'
                },
                {'role': 'user', 'content': _prompt(m, ins)},
              ],
            }),
          )
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        final text = ((data['choices'] as List).first['message']['content']
                as String)
            .trim();
        return _cache[m.id] = AiMatchAnalysis(
          text: '$text\n\n$kAiDisclaimer',
          homeConfidencePct: ins.expertHomePct,
          source: 'groq',
        );
      }
    } catch (_) {
      // roi ve ban local ben duoi
    }
    return _cache[m.id] = local;
  }

  String _prompt(FootballMatch m, MatchInsights ins) {
    String form(List<bool> f) =>
        f.map((w) => w ? 'T' : 'B').join('');
    return 'Trận ${m.home} vs ${m.away}. '
        'Odds: ${m.home} ${m.oddsHome} / ${m.away} ${m.oddsAway}. '
        'Chuyên gia đánh giá ${m.home} ${ins.expertHomePct}%. '
        'Phong độ 5 trận (T=thắng B=bại): ${m.home} ${form(ins.formHome)}, '
        '${m.away} ${form(ins.formAway)}. '
        'Đối đầu gần đây: ${ins.h2h.join('; ')}.';
  }
}
```

- [ ] **Step 3: Analyze + test toàn bộ**

Run: `flutter analyze` → `No issues found!`
Run: `flutter test` → PASS (service không có unit test — phụ thuộc mạng; fallback local đã được test ở Task 6).

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/services/ai_analysis_service.dart
git commit -m "feat: Groq-backed AI analysis service with local fallback"
```

---

### Task 8: Card AI trong màn chi tiết trận

**Files:**
- Create: `lib/widgets/ai_analysis_card.dart`
- Modify: `lib/screens/match_detail_screen.dart`

**Interfaces:**
- Consumes: `AiAnalysisService.instance.analyze`, `AiMatchAnalysis`.

- [ ] **Step 1: Tạo widget**

```dart
// lib/widgets/ai_analysis_card.dart
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
```

- [ ] **Step 2: Gắn vào `match_detail_screen.dart`**

Thêm import: `import '../widgets/ai_analysis_card.dart';`

Trong `Column` phần insights, ngay SAU block `_splitBar` của "Nhận định chuyên gia" và TRƯỚC `const SectionTitle('Phong độ 5 trận gần nhất')`, thêm:

```dart
                  const SectionTitle('AI nhận định'),
                  AiAnalysisCard(match: match),
```

- [ ] **Step 3: Analyze + test + chạy thử**

Run: `flutter analyze` → `No issues found!`; `flutter test` → PASS.
Chạy app, mở chi tiết trận, bấm "Phân tích trận này" → hiện phân tích + badge "AI nội bộ" (không key). Với key: `flutter run --dart-define=GROQ_API_KEY=gsk_xxx` → badge "Groq AI".

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/ai_analysis_card.dart lib/screens/match_detail_screen.dart
git commit -m "feat: AI match analysis card in match detail screen"
```

---

### Task 9: Carousel banner khuyến mãi

**Files:**
- Create: `lib/widgets/promo_banner_carousel.dart`
- Modify: `lib/screens/sportsbook_screen.dart`

**Interfaces:**
- Consumes: `authState.isDemo`, `WalletScreen`.

- [ ] **Step 1: Tạo widget**

```dart
// lib/widgets/promo_banner_carousel.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/auth_state.dart';
import '../screens/wallet_screen.dart';
import '../theme/brand_colors.dart';

/// Bang ron khuyen mai gia — tu cuon 4s/banner cho giong app thuong mai.
/// Noi dung la moi chai khuyen mai kieu nha cai (dung chu de giao duc).
/// Bam banner -> mo man vi (tru tai khoan demo).
class PromoBannerCarousel extends StatefulWidget {
  const PromoBannerCarousel({super.key});

  @override
  State<PromoBannerCarousel> createState() => _PromoBannerCarouselState();
}

class _Promo {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  const _Promo(this.title, this.subtitle, this.icon, this.colors);
}

const List<_Promo> _promos = [
  _Promo('NẠP LẦN ĐẦU +100%', 'Nạp 500k nhận ngay 1 triệu trong ví',
      Icons.bolt, [Color(0xFFB45309), Color(0xFF78350F)]),
  _Promo('CƯỢC XÂU THƯỞNG KHỦNG', 'Xâu 5 kèo trở lên — thưởng thêm 30%',
      Icons.link, [Color(0xFF1D4ED8), Color(0xFF312E81)]),
  _Promo('SIÊU KÈO CUỐI TUẦN', 'Odds tăng cực mạnh cho trận cầu tâm điểm',
      Icons.local_fire_department, [Color(0xFFB91C1C), Color(0xFF7F1D1D)]),
  _Promo('MỜI BẠN NHẬN 50K', 'Giới thiệu bạn bè — cả hai cùng có thưởng',
      Icons.card_giftcard, [Color(0xFF047857), Color(0xFF064E3B)]),
];

class _PromoBannerCarouselState extends State<PromoBannerCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final next = (_page + 1) % _promos.length;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _open() {
    if (authState.isDemo) return; // demo khong co nap/rut
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const WalletScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 96,
          child: PageView.builder(
            controller: _controller,
            itemCount: _promos.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final p = _promos[i];
              return GestureDetector(
                onTap: _open,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(colors: p.colors),
                  ),
                  child: Row(
                    children: [
                      Icon(p.icon, size: 34, color: kGold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.title,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: .5)),
                            const SizedBox(height: 3),
                            Text(p.subtitle,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white54),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _promos.length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 14 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? kGold : Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Gắn vào `sportsbook_screen.dart`**

Thêm import: `import '../widgets/promo_banner_carousel.dart';`

Trong `ListView` phần body, ngay TRƯỚC `HeroBanner(roundNumber: g.roundNumber),` thêm:

```dart
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: PromoBannerCarousel(),
                        ),
```

- [ ] **Step 3: Analyze + full test (chú ý timer)**

Run: `flutter analyze` → `No issues found!`
Run: `flutter test` → PASS. Nếu test báo "A Timer is still pending": kiểm tra `dispose()` đã `_timer?.cancel()` (đã có ở Step 1).

- [ ] **Step 4: Commit**

```bash
git add lib/widgets/promo_banner_carousel.dart lib/screens/sportsbook_screen.dart
git commit -m "feat: auto-scrolling promo banner carousel on sportsbook"
```

---

### Task 10: Chốt — full check, push, mở PR

- [ ] **Step 1: Toàn bộ kiểm tra**

```bash
flutter analyze          # No issues found!
flutter test             # All tests passed!
flutter build apk --debug  # Built ... app-debug.apk
```

- [ ] **Step 2: Chạy thử trên emulator** — login `demo/123456`: ví 10 triệu, không nút nạp/rút, banner cuộn, AI phân tích hiện. Login Firebase: ví 500k, nạp 300 → số dư + rollover tăng, rút bị chặn kèm lý do, cược đủ 5× → rút được.

- [ ] **Step 3: Push + PR**

```bash
git push -u origin feat/wallet-rollover-ai-banners
```

Mở PR trên web: `https://github.com/binh0601/meta-sports/compare/main...feat/wallet-rollover-ai-banners`
Mô tả PR: tính năng (ví 500k + rollover 5×, demo 10tr, AI local+Groq, banner), cách test (`flutter test`, login demo + Firebase), theo spec trong `docs/superpowers/specs/`.

- [ ] **Step 4: Nhờ teammate review, squash merge, xóa branch** (theo Git Flow trong CLAUDE.md).

---

## Ghi chú cho người thực thi

- `game_state.dart` sau Task 2 sẽ ~230 dòng (hơi vượt mốc ~200): chấp nhận được vì phần thêm là method mỏng; KHÔNG tách file trong plan này.
- Test trên Windows: luôn chạy theo file, không `--plain-name` (flutter tools crash với tên có dấu cách).
- Không commit `pubspec.lock`? CÓ commit (app Flutter nên khóa version).
- Đơn vị tiền hiển thị dùng `fmtMoney` từ `betting_math.dart` (500 → "500k", 10000 → "10 triệu").
