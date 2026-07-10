import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/betting_math.dart';

/// Kiem chung cac con so trong tai lieu "Toan hoc nha cai".
void main() {
  group('Overround & hold (keo 1.90/1.90)', () {
    test('xac suat ngam moi cua = 52,63%', () {
      expect(BettingMath.impliedProb(1.90), closeTo(0.5263, 0.0001));
    });
    test('overround = 5,26%', () {
      expect(BettingMath.overround([1.90, 1.90]), closeTo(0.0526, 0.0001));
    });
    test('hold = 5%', () {
      final over = BettingMath.overround([1.90, 1.90]);
      expect(BettingMath.hold(over), closeTo(0.05, 0.0001));
    });
    test('EV moi van 100k = -5k', () {
      expect(BettingMath.evPerBet(stake: 100, odds: 1.90, p: 0.5),
          closeTo(-5, 0.0001));
    });
  });

  group('So can va so lech (10 nguoi x 100k)', () {
    test('so can 5/5: lai 50k bat ke ket qua', () {
      expect(BettingMath.bookProfitIfAWins(5), 50);
      expect(BettingMath.bookProfitIfBWins(5), 50);
    });
    test('dong 6/4, A ra: lo 140k (kiem chung trong tai lieu)', () {
      expect(BettingMath.bookProfitIfAWins(6), -140);
    });
    test('lech cuc dai 0/10', () {
      expect(BettingMath.bookProfitIfAWins(0), 1000);
      expect(BettingMath.bookProfitIfBWins(0), -900);
    });
  });

  group('n va can n', () {
    test('diem giao: drift = swing tai n = 361', () {
      expect(BettingMath.houseDrift(361),
          closeTo(BettingMath.luckSwing(361), 0.0001));
    });
    test('% nguoi con lai: n=1 ~50%, n=1000 ~5%', () {
      expect(BettingMath.winnersShare(1), closeTo(0.479, 0.01));
      expect(BettingMath.winnersShare(1000), closeTo(0.048, 0.01));
    });
  });

  group('Martingale (odds 1.90)', () {
    test('net theo so lan thua: +80, +60, +20, -60, -220, -540', () {
      expect(BettingMath.martingaleNet(1), 80);
      expect(BettingMath.martingaleNet(2), 60);
      expect(BettingMath.martingaleNet(3), 20);
      expect(BettingMath.martingaleNet(4), -60);
      expect(BettingMath.martingaleNet(5), -220);
      expect(BettingMath.martingaleNet(6), -540);
    });
  });

  group('Cuoc xien', () {
    test('bien nha cai: 1 keo 5%, 5 keo 22,6%, 10 keo 40,1%', () {
      expect(BettingMath.parlayMargin(1), closeTo(0.05, 0.0001));
      expect(BettingMath.parlayMargin(5), closeTo(0.226, 0.001));
      expect(BettingMath.parlayMargin(10), closeTo(0.401, 0.001));
    });
  });
}
