import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'game_state.dart';
import 'xac_suat_math.dart';

/// Pha cua mot ky.
enum XsPhase { betting, locked, resolved }

/// Che do thoi luong (spec 3.3). Ty le betting:locked = 5:1 o moi che do.
enum XsMode { real, fast }

/// Ket qua khi thu dat cuoc — de UI hien thong bao dung luat R1–R4.
enum XsBetOutcome { ok, notBetting, insufficient, oppositePair, tooManyNumbers }

/// Bo dem thoi luong (ms) cho tung che do.
class _Timing {
  final int betting, total, resolveDelay;
  const _Timing(this.betting, this.total, this.resolveDelay);
}

const Map<XsMode, _Timing> _kTiming = {
  XsMode.real: _Timing(25000, 30000, 2000),
  XsMode.fast: _Timing(6000, 8000, 1500),
};

/// Controller game "KEO CHOP · 30 giay": state machine theo thoi gian, RNG
/// 0–9, validate luat choi. Vi dung chung voi [gameState]. Toan hoc o
/// xac_suat_math (da co test). Tinh remaining theo DateTime de khong lech.
class XsGame extends ChangeNotifier {
  final Random _rng = Random();
  Timer? _ticker;

  XsMode mode = XsMode.real;
  XsPhase phase = XsPhase.betting;
  int seq = 1;
  int remainingMs = 0; // con lai toi khi mo ket qua
  DateTime _roundStart = DateTime.now();
  bool _resolved = false;

  final List<XsBet> pendingBets = [];
  final List<XsRoundResult> history = []; // moi nhat o cuoi
  final XsStats stats = XsStats();
  XsRoundResult? lastResult; // ky vua mo, de reveal

  _Timing get _t => _kTiming[mode]!;
  bool get bettingOpen => phase == XsPhase.betting;
  double get pendingStake => pendingBets.fold(0.0, (s, b) => s + b.amount);
  int get distinctExactPicks =>
      pendingBets.where((b) => b.kind == XsBetKind.dungTong).length;

  /// Bat dau vong lap; goi tu initState man hinh (idempotent).
  void start() {
    if (_ticker != null) return;
    _beginRound();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _beginRound() {
    _roundStart = DateTime.now();
    _resolved = false;
    phase = XsPhase.betting;
    remainingMs = _t.total;
    lastResult = null;
    notifyListeners();
  }

  void _tick() {
    final elapsed = DateTime.now().difference(_roundStart).inMilliseconds;
    if (elapsed < _t.betting) {
      phase = XsPhase.betting;
    } else if (elapsed < _t.total) {
      phase = XsPhase.locked;
    } else if (!_resolved) {
      _resolve();
    } else if (elapsed >= _t.total + _t.resolveDelay) {
      seq++;
      _beginRound();
      return;
    }
    remainingMs = (_t.total - elapsed).clamp(0, _t.total);
    notifyListeners();
  }

  void _resolve() {
    _resolved = true;
    phase = XsPhase.resolved;
    final result = _rng.nextInt(10);
    final home = _rng.nextInt(result + 1); // scoreline trang tri
    final away = result - home;

    final wagered = pendingStake;
    final paid = pendingBets.fold(0.0, (s, b) => s + b.payoutFor(result));
    stats.record(wagered: wagered, paid: paid);
    gameState.addXsPayout(paid);

    lastResult = XsRoundResult(
      seq: seq,
      result: result,
      homeGoals: home,
      awayGoals: away,
      netChange: paid - wagered,
      hadBets: pendingBets.isNotEmpty,
    );
    history.add(lastResult!);
    if (history.length > 30) history.removeAt(0);
    pendingBets.clear();
  }

  /// Kiem tra & dat mot luot cuoc. Tru vi qua [gameState].
  XsBetOutcome placeBet(XsBetKind kind, double amount, {int? exactValue}) {
    if (!bettingOpen) return XsBetOutcome.notBetting; // R4
    // R1: khong dat ca Tai lan Xiu cung ky.
    final opposite = kind == XsBetKind.tai
        ? XsBetKind.xiu
        : (kind == XsBetKind.xiu ? XsBetKind.tai : null);
    if (opposite != null && pendingBets.any((b) => b.kind == opposite)) {
      return XsBetOutcome.oppositePair;
    }
    // R2: khong qua 7 so "dung tong" rieng biet.
    if (kind == XsBetKind.dungTong &&
        !pendingBets.any((b) => b.exactValue == exactValue) &&
        distinctExactPicks >= kXsMaxDistinctExactPicks) {
      return XsBetOutcome.tooManyNumbers;
    }
    // R3: > 0 va <= so du (tru vi ngay).
    if (!gameState.placeXsStake(amount)) return XsBetOutcome.insufficient;
    pendingBets.add(XsBet(kind: kind, amount: amount, exactValue: exactValue));
    notifyListeners();
    return XsBetOutcome.ok;
  }

  /// Tong da dat cho mot lua chon (de hien tren nut).
  double stakedOn(XsBetKind kind, {int? exactValue}) => pendingBets
      .where((b) =>
          b.kind == kind && (kind != XsBetKind.dungTong || b.exactValue == exactValue))
      .fold(0.0, (s, b) => s + b.amount);

  /// Doi che do: huy timer cu tranh ro ri, khoi tao ky moi an toan.
  void setMode(XsMode m) {
    if (m == mode) return;
    mode = m;
    _ticker?.cancel();
    _ticker = null;
    for (final b in pendingBets) {
      gameState.addXsPayout(b.amount); // hoan cuoc dang cho khi doi che do
    }
    pendingBets.clear();
    start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

/// Singleton dung chung cho man hinh Keo Chop.
final XsGame xsGame = XsGame();
