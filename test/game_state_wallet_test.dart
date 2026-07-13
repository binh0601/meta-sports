import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/game_state.dart';
import 'package:house_edge_demo/logic/wallet_rules.dart';

// Test tich hop vi (WalletRules) vao GameState: nap/rut, che do demo,
// netProfit theo tong tien duoc cap/nap. Khong goi playRound (dinh
// NotificationService), dung GameState() moi cho tung test.
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
}
