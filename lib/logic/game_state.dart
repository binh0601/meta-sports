import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/notification_service.dart';
import '../services/player_repository.dart';
import 'betting_math.dart';
import 'football_market.dart';
import 'handicap_settlement.dart';
import 'wallet_rules.dart';

/// Trang thai san keo: vi tien ao, phieu cuoc, lich su.
/// Nguoi choi Firebase: vi + lich su dong bo Firestore (fire-and-forget).
/// Khong attachUser (admin/test): hoat dong thuan local nhu cu.
class GameState extends ChangeNotifier {
  static const double startBalance = 500000; // 500.000 VND cap cho tai khoan moi
  static const double demoBalance = 10000000; // 10 trieu VND — rieng tai khoan demo
  final Random _rng = Random();

  double balance = startBalance;
  int roundNumber = 1;
  bool roundPlayed = false;
  bool roundInPlay = false; // vong dang da live (phut dang chay)
  int liveMinute = 0; // phut thi dau hien tai khi dang da
  Timer? _liveTimer;
  List<FootballMatch> matches = [];
  final WalletRules wallet = WalletRules(totalFunded: startBalance);
  bool isDemoWallet = false; // true khi dang nhap tai khoan demo/123456
  League league = League.asianCup;

  final List<BetSelection> slip = []; // phieu dang chon
  double stake = 100000; // 100k VND cược mặc định
  final List<BetSlip> pending = []; // da dat, cho da vong
  final List<BetSlip> settled = []; // da co ket qua
  List<BetSlip> lastResults = []; // ket qua vong vua da
  final List<double> balanceHistory = [startBalance];

  String? _uid; // != null khi nguoi choi Firebase da dang nhap
  bool syncing = false; // dang tai du lieu cloud
  
  String? bankName;
  String? bankAccountNo;
  String? bankAccountName;

  GameState() {
    matches = generateRound(_rng, 1, league: league);
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
    bankName = profile.bankName;
    bankAccountNo = profile.bankAccountNo;
    bankAccountName = profile.bankAccountName;
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
    matches = generateRound(_rng, roundNumber * 100, league: league);
    syncing = false;
    notifyListeners();
  }

  /// Dang nhap tai khoan demo (khong Firebase): vi 10 trieu, thuan local.
  void attachDemo() {
    _uid = null;
    isDemoWallet = true;
    bankName = null;
    bankAccountNo = null;
    bankAccountName = null;
    _resetLocal();
  }

  void setBankInfo(String bName, String bNo, String bAccName) {
    bankName = bName;
    bankAccountNo = bNo;
    bankAccountName = bAccName;
    notifyListeners();
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

  bool isSelected(FootballMatch m, bool onHome,
          {MarketType market = MarketType.match1x2}) =>
      slip.any((s) =>
          s.match.id == m.id && s.onHome == onHome && s.market == market);

  /// Cua nay da nam trong phieu DA DAT (cho ket qua) chua — de san keo
  /// van to mau sau khi nguoi choi bam dat cuoc.
  bool isBetPlaced(FootballMatch m, bool onHome,
          {MarketType market = MarketType.match1x2}) =>
      pending.any((b) => b.selections.any((s) =>
          s.match.id == m.id && s.onHome == onHome && s.market == market));

  /// Bam odds: chon / bo chon / doi cua trong cung tran.
  /// Ve chap (handicap) luon la ve don: khong xien duoc voi keo khac,
  /// nen chon chap se xoa het cac chan cu; va nguoc lai, dang co chan
  /// chap ma chon them keo khac thi cung xoa chap di (khong xep chong).
  void toggleSelection(FootballMatch m, bool onHome,
      {MarketType market = MarketType.match1x2}) {
    if (roundPlayed || roundInPlay) return;
    final i = slip.indexWhere((s) => s.match.id == m.id);
    if (i >= 0 && slip[i].onHome == onHome && slip[i].market == market) {
      slip.removeAt(i);
    } else {
      if (i >= 0) slip.removeAt(i);
      if (market == MarketType.handicap ||
          slip.any((s) => s.market == MarketType.handicap)) {
        slip.clear();
      }
      slip.add(BetSelection(m, onHome, market: market));
    }
    notifyListeners();
  }

  /// Nhich odds 1x2 cac tran chua da de san keo "chay" nhu web that.
  /// Bo qua tran dang chon (slip) hoac da dat (pending) de khong doi
  /// odds/payout cua nguoi choi. Goi dinh ky tu SportsbookScreen.
  void tickLiveMarket() {
    if (roundPlayed || roundInPlay) return;
    var changed = false;
    for (final m in matches) {
      if (m.played) continue;
      final locked = slip.any((s) => s.match.id == m.id) ||
          pending.any((b) => b.selections.any((s) => s.match.id == m.id));
      if (locked) continue;
      m.tickLiveOdds(_rng);
      changed = true;
    }
    if (changed) notifyListeners();
  }

  double get slipOdds => slip.fold(1.0, (p, s) => p * s.odds);
  bool get canPlaceBet =>
      slip.isNotEmpty &&
      stake > 0 &&
      stake <= balance &&
      !roundPlayed &&
      !roundInPlay;

  void setStake(double v) {
    stake = v;
    notifyListeners();
  }

  void placeBet() {
    if (!canPlaceBet) return;
    // Luoi an toan: ve chap phai la ve don, du toggleSelection da chan
    // truong hop nay tu truoc.
    if (slip.any((s) => s.market == MarketType.handicap) && slip.length > 1) {
      return;
    }
    balance -= stake;
    wallet.recordWager(stake);
    pending.add(
        BetSlip(selections: [...slip], stake: stake, round: roundNumber));
    slip.clear();
    _saveStateToCloud();
    notifyListeners();
  }

  /// Bam "Da vong": bat dau da LIVE — 8 tran chay phut, ban thang lo dan
  /// (~21s), roi tu dong chot ket qua. Cho giong tran dang da that.
  void kickoffRound() {
    if (roundPlayed || roundInPlay) return;
    for (final m in matches) {
      m.startLive(_rng);
    }
    roundInPlay = true;
    liveMinute = 0;
    notifyListeners();
    _liveTimer =
        Timer.periodic(const Duration(milliseconds: 700), (_) => _liveTick());
  }

  /// Moi ~0.7s: tang phut, cap nhat ty so lo dan. Den phut 90 -> chot vong.
  void _liveTick() {
    liveMinute = (liveMinute + 3).clamp(0, 90);
    for (final m in matches) {
      m.liveMinute = liveMinute;
    }
    if (liveMinute >= 90) {
      _liveTimer?.cancel();
      _liveTimer = null;
      for (final m in matches) {
        m.finish();
      }
      roundInPlay = false;
      _settleRound();
      return;
    }
    notifyListeners();
  }

  /// Da ca vong tuc thi (khong live) — giu lai cho tuong thich/test.
  void playRound() {
    if (roundPlayed || roundInPlay) return;
    for (final m in matches) {
      m.play(_rng);
    }
    _settleRound();
  }

  /// Thanh toan moi phieu theo ty so cuoi, luu cloud, ban notification.
  void _settleRound() {
    for (final b in pending) {
      b.settled = true;
      final legs = b.selections;
      if (legs.length == 1 && legs.first.market == MarketType.handicap) {
        // Ve chap don: cham theo ty le hoan (co the an nua/hoan/thua nua).
        final s = legs.first;
        final r = settleHandicap(
          goalsFor: s.onHome ? s.match.homeGoals : s.match.awayGoals,
          goalsAgainst: s.onHome ? s.match.awayGoals : s.match.homeGoals,
          line: s.line,
          odds: s.odds,
        );
        b.payout = b.stake * r.ratio;
        b.won = r.ratio >= 1.0; // an hoac hoan von -> khong tinh la thua (mau UI)
        b.legResults = [
          LegResult(s.teamName, s.odds, b.won,
              payoutRatio: r.ratio, market: MarketType.handicap, status: r.status),
        ];
      } else {
        // Ve don/xien 1x2: nhi phan, phai trung tat ca cac chan.
        b.won = legs.every((s) => s.won);
        b.payout = b.won ? b.stake * b.totalOdds : 0;
        b.captureLegResults();
      }
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
    _liveTimer?.cancel();
    _liveTimer = null;
    roundInPlay = false;
    liveMinute = 0;
    roundNumber++;
    matches = generateRound(_rng, roundNumber * 100, league: league);
    roundPlayed = false;
    slip.clear();
    lastResults = [];
    _saveStateToCloud();
    notifyListeners();
  }

  /// Doi giai dau. Tra ve false khi con phieu cho ket qua (tien dang nam
  /// trong cuoc — khong duoc doi san).
  bool switchLeague(League l) {
    if (roundInPlay) return false;
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

  /// Choi lai tu dau: vi ve 500k (tai khoan demo: 10 trieu), danh dau
  /// reset tren cloud de lich su cu khong bi khoi phuc lai.
  void reset() {
    _resetLocal();
    _saveStateToCloud(markReset: true);
  }

  void _resetLocal() {
    _liveTimer?.cancel();
    _liveTimer = null;
    roundInPlay = false;
    liveMinute = 0;
    balance = isDemoWallet ? demoBalance : startBalance;
    wallet.reset(balance);
    roundNumber = 1;
    roundPlayed = false;
    matches = generateRound(_rng, 1, league: league);
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
