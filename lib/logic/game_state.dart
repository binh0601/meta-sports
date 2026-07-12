import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/notification_service.dart';
import '../services/player_repository.dart';
import 'betting_math.dart';
import 'football_market.dart';
import 'wallet_rules.dart';

/// Trang thai san keo: vi tien ao, phieu cuoc, lich su.
/// Nguoi choi Firebase: vi + lich su dong bo Firestore (fire-and-forget).
/// Khong attachUser (admin/test): hoat dong thuan local nhu cu.
class GameState extends ChangeNotifier {
  static const double startBalance = 500; // 500k cap cho tai khoan moi
  static const double demoBalance = 10000; // 10 trieu — rieng tai khoan demo
  final Random _rng = Random();

  double balance = startBalance;
  int roundNumber = 1;
  bool roundPlayed = false;
  List<FootballMatch> matches = [];
  final WalletRules wallet = WalletRules(totalFunded: startBalance);
  bool isDemoWallet = false; // true khi dang nhap tai khoan demo/123456

  final List<BetSelection> slip = []; // phieu dang chon
  double stake = 100;
  final List<BetSlip> pending = []; // da dat, cho da vong
  final List<BetSlip> settled = []; // da co ket qua
  List<BetSlip> lastResults = []; // ket qua vong vua da
  final List<double> balanceHistory = [startBalance];

  String? _uid; // != null khi nguoi choi Firebase da dang nhap
  bool syncing = false; // dang tai du lieu cloud

  GameState() {
    matches = generateRound(_rng, 1);
  }

  // ---- Dong bo Firestore ----

  /// Goi sau khi dang nhap Firebase: tai vi + lich su ve thay the local.
  Future<void> attachUser(User user) async {
    _uid = user.uid;
    syncing = true;
    notifyListeners();
    final profile = await PlayerRepository.instance
        .loadOrCreateProfile(user, startBalance);
    final history =
        await PlayerRepository.instance.loadRecentBets(user.uid);
    balance = profile.balance;
    roundNumber = profile.roundNumber;
    isDemoWallet = false;
    wallet.totalFunded = profile.totalFunded;
    wallet.totalWagered = profile.totalWagered;
    settled
      ..clear()
      ..addAll(history.map((h) => h.slip));
    balanceHistory
      ..clear()
      ..add(history.isEmpty ? balance : wallet.totalFunded)
      ..addAll(history.map((h) => h.balanceAfter));
    slip.clear();
    pending.clear();
    lastResults = [];
    roundPlayed = false;
    matches = generateRound(_rng, roundNumber * 100);
    syncing = false;
    notifyListeners();
  }

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

  // ---- Gameplay ----

  bool isSelected(FootballMatch m, bool onHome) =>
      slip.any((s) => s.match.id == m.id && s.onHome == onHome);

  /// Cua nay da nam trong phieu DA DAT (cho ket qua) chua — de san keo
  /// van to mau sau khi nguoi choi bam dat cuoc.
  bool isBetPlaced(FootballMatch m, bool onHome) => pending.any(
      (b) => b.selections.any((s) => s.match.id == m.id && s.onHome == onHome));

  /// Bam odds: chon / bo chon / doi cua trong cung tran.
  void toggleSelection(FootballMatch m, bool onHome) {
    if (roundPlayed) return;
    final i = slip.indexWhere((s) => s.match.id == m.id);
    if (i >= 0 && slip[i].onHome == onHome) {
      slip.removeAt(i);
    } else {
      if (i >= 0) slip.removeAt(i);
      slip.add(BetSelection(m, onHome));
    }
    notifyListeners();
  }

  double get slipOdds => slip.fold(1.0, (p, s) => p * s.odds);
  bool get canPlaceBet =>
      slip.isNotEmpty && stake > 0 && stake <= balance && !roundPlayed;

  void setStake(double v) {
    stake = v;
    notifyListeners();
  }

  void placeBet() {
    if (!canPlaceBet) return;
    balance -= stake;
    wallet.recordWager(stake);
    pending.add(
        BetSlip(selections: [...slip], stake: stake, round: roundNumber));
    slip.clear();
    _saveStateToCloud();
    notifyListeners();
  }

  /// Da ca vong: ra ket qua 8 tran, thanh toan moi phieu, luu cloud,
  /// ban notification neu co phieu trung.
  void playRound() {
    if (roundPlayed) return;
    for (final m in matches) {
      m.play(_rng);
    }
    for (final b in pending) {
      b.settled = true;
      b.won = b.selections.every((s) => s.won);
      b.payout = b.won ? b.stake * b.totalOdds : 0;
      b.captureLegResults();
      balance += b.payout;
      settled.add(b);
      balanceHistory.add(balance);
      final uid = _uid;
      if (uid != null) {
        PlayerRepository.instance.saveSettledBet(uid, b, balance);
      }
    }
    lastResults = [...pending];
    pending.clear();
    roundPlayed = true;
    _saveStateToCloud();

    final wonSlips = lastResults.where((b) => b.won).toList();
    NotificationService.instance.notifyRoundResult(
      wonCount: wonSlips.length,
      wonNet: wonSlips.fold(0.0, (s, b) => s + b.net),
      balance: balance,
    );
    notifyListeners();
  }

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

  void newRound() {
    roundNumber++;
    matches = generateRound(_rng, roundNumber * 100);
    roundPlayed = false;
    slip.clear();
    lastResults = [];
    _saveStateToCloud();
    notifyListeners();
  }

  /// Choi lai tu dau: vi ve 500k (tai khoan demo: 10 trieu), danh dau
  /// reset tren cloud de lich su cu khong bi khoi phuc lai.
  void reset() {
    _resetLocal();
    _saveStateToCloud(markReset: true);
  }

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

  // ---- Thong ke doi chieu voi ly thuyet (admin dung) ----
  int get betCount => settled.length;
  double get totalStaked => settled.fold(0.0, (s, b) => s + b.stake);
  /// Lai/lo so voi tong tien duoc cap/nap (tru phieu dang cho ket qua).
  double get netProfit => balance - wallet.totalFunded - pendingStake;
  double get pendingStake => pending.fold(0.0, (s, b) => s + b.stake);

  /// Ly thuyet du doan mat: tong (tien cuoc x bien nha cai theo so keo ghep).
  double get expectedLoss => settled.fold(
      0.0, (s, b) => s + b.stake * BettingMath.parlayMargin(b.legs));
}

/// Trang thai dung chung cho cac man hinh san keo.
final GameState gameState = GameState();
