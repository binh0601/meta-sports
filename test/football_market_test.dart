import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/betting_math.dart';
import 'package:house_edge_demo/logic/football_market.dart';
import 'package:house_edge_demo/logic/game_state.dart';

void main() {
  group('Sinh keo bong da', () {
    test('moi vong 8 tran, odds co overround ~5,26%', () {
      final matches = generateRound(Random(42), 1);
      expect(matches.length, 8);
      for (final m in matches) {
        final over = BettingMath.overround([m.oddsHome, m.oddsAway]);
        // odds lam tron 2 chu so nen cho phep sai so nho quanh 5,26%
        expect(over, closeTo(0.0526, 0.01));
        expect(m.oddsHome, greaterThan(1.0));
        expect(m.oddsAway, greaterThan(1.0));
      }
    });

    test('da tran: ty so khop voi doi thang', () {
      final m = generateRound(Random(1), 1).first;
      m.play(Random(2));
      expect(m.played, true);
      if (m.homeWon) {
        expect(m.homeGoals, greaterThan(m.awayGoals));
      } else {
        expect(m.awayGoals, greaterThanOrEqualTo(m.homeGoals));
      }
    });

    test('play co the ra hoa qua nhieu lan', () {
      final rng = Random(7);
      var draws = 0;
      for (var i = 0; i < 400; i++) {
        final m = generateRound(rng, i * 8).first..play(rng);
        if (m.homeGoals == m.awayGoals) draws++;
      }
      expect(draws, greaterThan(40)); // >~10% hoa
      expect(draws, lessThan(200));   // <50%
    });

    test('handicap line la boi cua 0.25 va co dau theo doi manh', () {
      final rng = Random(3);
      for (final m in generateRound(rng, 1)) {
        expect((m.homeHandicap * 4) % 1, 0); // boi 0.25
        // doi xac suat cao hon la cua tren (line am ve phia ho)
        if (m.trueProbHome > 0.55) expect(m.homeHandicap, lessThanOrEqualTo(0));
        if (m.trueProbHome < 0.45) expect(m.homeHandicap, greaterThanOrEqualTo(0));
      }
    });

    test('line co the dat toi ca banh (>=0.5) qua nhieu tran', () {
      final rng = Random(11);
      var reached = false;
      for (var i = 0; i < 20 && !reached; i++) {
        for (final m in generateRound(rng, i * 8)) {
          if (m.homeHandicap.abs() >= 0.5) reached = true;
        }
      }
      expect(reached, true);
    });

    test('hoa -> ca hai cua 1x2 deu thua', () {
      final rng = Random(5);
      final m = generateRound(rng, 1).first;
      // ep ra hoa: da lai cho toi khi homeGoals == awayGoals
      while (m.homeGoals != m.awayGoals || !m.played) {
        m.play(rng);
      }
      expect(m.homeGoals, m.awayGoals);
      expect(BetSelection(m, true).won, false);
      expect(BetSelection(m, false).won, false);
    });
  });

  group('Phieu cuoc', () {
    test('LegResult serialize/parse doi xung (luu Firestore)', () {
      const leg = LegResult('Việt Nam', 1.85, true);
      final back = LegResult.fromMap(leg.toMap());
      expect(back.teamName, 'Việt Nam');
      expect(back.odds, 1.85);
      expect(back.won, true);
    });

    test('BetSlip.restored: totalOdds/legs tinh tu legResults', () {
      final b = BetSlip.restored(
        legResults: const [
          LegResult('A', 2.0, true),
          LegResult('B', 1.5, true),
        ],
        stake: 100,
        round: 3,
        won: true,
        payout: 300,
      );
      expect(b.legs, 2);
      expect(b.totalOdds, closeTo(3.0, 0.0001));
      expect(b.net, 200);
      expect(b.settled, true);
    });

    test('xien: odds nhan voi nhau, phai trung tat ca', () {
      final matches = generateRound(Random(7), 1);
      final slip = BetSlip(
        selections: [
          BetSelection(matches[0], true),
          BetSelection(matches[1], false),
        ],
        stake: 100,
        round: 1,
      );
      expect(slip.legs, 2);
      expect(slip.totalOdds,
          closeTo(matches[0].oddsHome * matches[1].oddsAway, 0.0001));
    });
  });

  group('GameState', () {
    test('dat cuoc tru tien, thanh toan dung khi da vong', () {
      final g = GameState();
      final m = g.matches.first;
      g.toggleSelection(m, true);
      g.setStake(200);
      expect(g.canPlaceBet, true);
      g.placeBet();
      expect(g.balance, GameState.startBalance - 200);
      expect(g.pending.length, 1);

      g.playRound();
      expect(g.pending, isEmpty);
      expect(g.settled.length, 1);
      final b = g.settled.first;
      // Thang thi cong stake * odds, thua thi 0 — so du phai khop
      expect(g.balance,
          closeTo(GameState.startBalance - 200 + b.payout, 0.0001));
      expect(b.won, m.homeWon);
    });

    test('sau khi dat phieu, cua da cuoc van duoc danh dau (isBetPlaced)', () {
      final g = GameState();
      final m = g.matches.first;
      g.toggleSelection(m, true);
      g.placeBet();
      // slip da bi xoa nhung san keo van phai to mau cua da dat
      expect(g.isSelected(m, true), false);
      expect(g.isBetPlaced(m, true), true);
      expect(g.isBetPlaced(m, false), false);
      g.playRound();
      expect(g.isBetPlaced(m, true), false); // da co ket qua -> het cho
    });

    test('khong cho dat qua so du', () {
      final g = GameState();
      g.toggleSelection(g.matches.first, true);
      g.setStake(999999);
      expect(g.canPlaceBet, false);
    });

    test('reset ve trang thai ban dau', () {
      final g = GameState();
      g.toggleSelection(g.matches.first, true);
      g.placeBet();
      g.playRound();
      g.reset();
      expect(g.balance, GameState.startBalance);
      expect(g.settled, isEmpty);
      expect(g.roundNumber, 1);
      expect(g.roundPlayed, false);
    });
  });
}
