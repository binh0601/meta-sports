import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/football_market.dart';
import 'package:house_edge_demo/logic/game_state.dart';
import 'package:house_edge_demo/logic/handicap_settlement.dart';
import 'package:house_edge_demo/logic/wallet_rules.dart';

// Test tich hop vi (WalletRules) vao GameState: nap/rut, che do demo,
// netProfit theo tong tien duoc cap/nap. Da so khong goi playRound (dinh
// NotificationService); rieng nhom "ve chap" ben duoi co goi playRound —
// da xac nhan an toan (football_market_test.dart cung goi playRound).
// Dung GameState() moi cho tung test.
void main() {
  group('GameState vi — nap tien', () {
    test('deposit(200): balance +200, totalFunded +200, requirement +200',
        () {
      final g = GameState();
      final balanceBefore = g.balance;
      final fundedBefore = g.wallet.totalFunded;
      final reqBefore = g.wallet.requirement;
      g.deposit(200);
      expect(g.balance, balanceBefore + 200);
      expect(g.wallet.totalFunded, fundedBefore + 200);
      expect(g.wallet.requirement,
          reqBefore + 200 * WalletRules.rolloverMultiplier);
    });

    test('deposit(0) va deposit(-50): khong doi gi', () {
      final g = GameState();
      final balanceBefore = g.balance;
      final fundedBefore = g.wallet.totalFunded;
      g.deposit(0);
      g.deposit(-50);
      expect(g.balance, balanceBefore);
      expect(g.wallet.totalFunded, fundedBefore);
    });
  });

  group('GameState vi — rut tien', () {
    test('chua du rollover: withdrawAll tra 0, balance giu nguyen', () {
      final g = GameState();
      final amount = g.withdrawAll();
      expect(amount, 0);
      expect(g.balance, GameState.startBalance);
    });

    test('du rollover nhung con phieu pending: withdrawAll tra 0', () {
      final g = GameState();
      g.toggleSelection(g.matches.first, true);
      g.setStake(100);
      g.placeBet(); // pending 1 phieu, da cuoc 100
      g.wallet.recordWager(g.wallet.requirement); // ep du rollover
      expect(g.wallet.remaining, 0);
      expect(g.withdrawAll(), 0);
      expect(g.pending.length, 1);
    });

    test('du rollover, khong pending: rut dung so du, vi ve 0', () {
      final g = GameState();
      g.wallet.recordWager(g.wallet.requirement); // ep du rollover
      final amount = g.withdrawAll();
      expect(amount, GameState.startBalance);
      expect(g.balance, 0);
      expect(g.wallet.totalFunded, 0);
      expect(g.balanceHistory.last, 0);
    });
  });

  group('GameState vi — che do demo', () {
    test('attachDemo: vi 10 trieu, reset() van ve 10 trieu', () {
      final g = GameState();
      g.attachDemo();
      expect(g.balance, GameState.demoBalance);
      g.reset();
      expect(g.balance, GameState.demoBalance);
    });

    test('detachUser: ve vi thuong 500k', () {
      final g = GameState();
      g.attachDemo();
      g.detachUser();
      expect(g.balance, GameState.startBalance);
    });
  });

  group('GameState vi — netProfit', () {
    test('GameState moi: netProfit == 0', () {
      final g = GameState();
      expect(g.netProfit, 0);
    });

    test('nap tien KHONG lam thay doi netProfit', () {
      final g = GameState();
      final before = g.netProfit;
      g.deposit(300);
      expect(g.netProfit, before);
    });
  });

  group('GameState ve chap — rang buoc single va cham diem', () {
    test('chon chap: slip luon la ve don, khong xien duoc voi keo khac', () {
      final g = GameState();
      final m0 = g.matches[0];
      final m1 = g.matches[1];

      g.toggleSelection(m0, true); // keo 1x2 binh thuong
      expect(g.slip.length, 1);

      g.toggleSelection(m1, true, market: MarketType.handicap);
      expect(g.slip.length, 1); // chon chap -> xoa het chan cu
      expect(g.slip.first.market, MarketType.handicap);
      expect(g.slip.first.match.id, m1.id);

      g.toggleSelection(m0, true); // them keo 1x2 khac -> khong xien voi chap
      expect(g.slip.length, 1);
      expect(g.slip.first.market, MarketType.match1x2);
      expect(g.slip.first.match.id, m0.id);
    });

    test('placeBet tu choi neu slip co chap + nhieu chan (luoi an toan)', () {
      final g = GameState();
      final m0 = g.matches[0];
      final m1 = g.matches[1];
      // Bo qua toggleSelection de ep truong hop bat thuong nay.
      g.slip.addAll([
        BetSelection(m0, true, market: MarketType.handicap),
        BetSelection(m1, true),
      ]);
      g.setStake(100);
      final balanceBefore = g.balance;

      g.placeBet();

      expect(g.pending, isEmpty);
      expect(g.balance, balanceBefore);
    });

    test('ve chap don: payout va status khop voi settleHandicap tinh tu ty so thuc',
        () {
      final g = GameState();
      final m = g.matches.first;
      g.toggleSelection(m, true, market: MarketType.handicap);
      g.setStake(100);
      g.placeBet();

      g.playRound();

      expect(g.settled.length, 1);
      final b = g.settled.first;
      final sel = BetSelection(m, true, market: MarketType.handicap);
      final expected = settleHandicap(
        goalsFor: m.homeGoals,
        goalsAgainst: m.awayGoals,
        line: sel.line,
        odds: sel.odds,
      );
      expect(b.payout, closeTo(100 * expected.ratio, 0.0001));
      expect(b.legResults.length, 1);
      expect(b.legResults.first.market, MarketType.handicap);
      expect(b.legResults.first.status, expected.status);
      expect(b.legResults.first.payoutRatio, expected.ratio);
      expect(g.balance,
          closeTo(GameState.startBalance - 100 + b.payout, 0.0001));
    });

    test('ve 1x2 xien: khong dung settleHandicap, van nhi phan nhu cu', () {
      final g = GameState();
      final m0 = g.matches[0];
      final m1 = g.matches[1];
      g.toggleSelection(m0, true);
      g.toggleSelection(m1, false);
      g.setStake(100);
      g.placeBet();

      g.playRound();

      final b = g.settled.first;
      expect(b.legResults.length, 2);
      final expectedWon =
          BetSelection(m0, true).won && BetSelection(m1, false).won;
      expect(b.won, expectedWon);
      expect(b.payout, b.won ? closeTo(100 * b.totalOdds, 0.0001) : 0);
    });
  });
}
