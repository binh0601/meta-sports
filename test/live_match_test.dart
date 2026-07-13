import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/live_match.dart';

void main() {
  group('LiveMatch.demo', () {
    test('tra tran dang da voi cac truong hop ly', () {
      final m = LiveMatch.demo();
      expect(m.isLive, isTrue);
      expect(m.status, 'LIVE');
      expect(m.home, isNotEmpty);
      expect(m.away, isNotEmpty);
      expect(m.homeGoals, greaterThanOrEqualTo(0));
      expect(m.awayGoals, greaterThanOrEqualTo(0));
      expect(m.minute, inInclusiveRange(0, 90));
      expect(m.events, isNotEmpty);
    });
  });

  group('LiveMatch.tickDemo', () {
    test('tien phut va khong bao gio giam ban thang', () {
      var m = LiveMatch.demo();
      final rng = Random(1);
      var prevMinute = m.minute;
      var prevHomeGoals = m.homeGoals;
      var prevAwayGoals = m.awayGoals;

      for (var i = 0; i < 40; i++) {
        m = LiveMatch.tickDemo(m, rng);
        expect(m.minute, greaterThanOrEqualTo(prevMinute));
        expect(m.homeGoals, greaterThanOrEqualTo(prevHomeGoals));
        expect(m.awayGoals, greaterThanOrEqualTo(prevAwayGoals));
        prevMinute = m.minute;
        prevHomeGoals = m.homeGoals;
        prevAwayGoals = m.awayGoals;
        if (!m.isLive) break;
      }

      expect(m.minute, lessThanOrEqualTo(90));
    });

    test('tran ket thuc khi qua phut 90 va status thanh FT', () {
      var m = LiveMatch.demo();
      final rng = Random(2);
      for (var i = 0; i < 40 && m.isLive; i++) {
        m = LiveMatch.tickDemo(m, rng);
      }
      expect(m.isLive, isFalse);
      expect(m.status, 'FT');
      expect(m.minute, 90);
    });

    test('tran da ket thuc thi tickDemo tra ve nguyen trang', () {
      var m = LiveMatch.demo();
      final rng = Random(3);
      for (var i = 0; i < 40 && m.isLive; i++) {
        m = LiveMatch.tickDemo(m, rng);
      }
      final after = LiveMatch.tickDemo(m, rng);
      expect(after.minute, m.minute);
      expect(after.status, m.status);
    });
  });
}
