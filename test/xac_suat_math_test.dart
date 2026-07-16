import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/xac_suat_math.dart';

void main() {
  group('xsMultiplier — dieu kien thang & he so (spec 3.1 / 8.1)', () {
    test('Tai thang khi tong ban 5..9, thua khi 0..4', () {
      for (var r = 0; r <= 9; r++) {
        expect(xsMultiplier(XsBetKind.tai, r), r >= 5 ? 2.0 : 0.0,
            reason: 'result=$r');
      }
    });

    test('Xiu thang khi tong ban 0..4, thua khi 5..9', () {
      for (var r = 0; r <= 9; r++) {
        expect(xsMultiplier(XsBetKind.xiu, r), r <= 4 ? 2.0 : 0.0,
            reason: 'result=$r');
      }
    });

    test('Le: {1,3,7,9} ×2, {5} ×1.5, con lai thua', () {
      expect(xsMultiplier(XsBetKind.le, 1), 2.0);
      expect(xsMultiplier(XsBetKind.le, 3), 2.0);
      expect(xsMultiplier(XsBetKind.le, 7), 2.0);
      expect(xsMultiplier(XsBetKind.le, 9), 2.0);
      expect(xsMultiplier(XsBetKind.le, 5), 1.5);
      for (final r in [0, 2, 4, 6, 8]) {
        expect(xsMultiplier(XsBetKind.le, r), 0.0, reason: 'result=$r');
      }
    });

    test('Chan: {2,4,6,8} ×2, {0} ×1.5, con lai thua', () {
      expect(xsMultiplier(XsBetKind.chan, 2), 2.0);
      expect(xsMultiplier(XsBetKind.chan, 4), 2.0);
      expect(xsMultiplier(XsBetKind.chan, 6), 2.0);
      expect(xsMultiplier(XsBetKind.chan, 8), 2.0);
      expect(xsMultiplier(XsBetKind.chan, 0), 1.5);
      for (final r in [1, 3, 5, 7, 9]) {
        expect(xsMultiplier(XsBetKind.chan, r), 0.0, reason: 'result=$r');
      }
    });

    test('Dac biet {0,5} ×4.5', () {
      for (var r = 0; r <= 9; r++) {
        expect(xsMultiplier(XsBetKind.dacBiet, r), (r == 0 || r == 5) ? 4.5 : 0.0,
            reason: 'result=$r');
      }
    });

    test('Dung tong: chi thang khi trung dung so da chon ×9', () {
      expect(xsMultiplier(XsBetKind.dungTong, 7, exactValue: 7), 9.0);
      expect(xsMultiplier(XsBetKind.dungTong, 7, exactValue: 3), 0.0);
      expect(xsMultiplier(XsBetKind.dungTong, 7), 0.0); // thieu exactValue
    });
  });

  group('Ket qua dac biet 0 & 5 (spec checklist)', () {
    test('Ket qua 0: Chan va Dac biet cung thang dung he so (1.5 & 4.5)', () {
      expect(xsMultiplier(XsBetKind.chan, 0), 1.5);
      expect(xsMultiplier(XsBetKind.dacBiet, 0), 4.5);
      expect(xsMultiplier(XsBetKind.le, 0), 0.0);
    });

    test('Ket qua 5: Le va Dac biet cung thang dung he so (1.5 & 4.5)', () {
      expect(xsMultiplier(XsBetKind.le, 5), 1.5);
      expect(xsMultiplier(XsBetKind.dacBiet, 5), 4.5);
      expect(xsMultiplier(XsBetKind.chan, 5), 0.0);
    });
  });

  group('xsPayout — khau tru 2% truoc khi tinh thuong', () {
    test('Tai thang: payout = stake × 0.98 × 2', () {
      expect(xsPayout(100000, XsBetKind.tai, 6), closeTo(196000, 1e-6));
    });

    test('Thua: payout = 0', () {
      expect(xsPayout(100000, XsBetKind.tai, 3), 0.0);
    });

    test('Dung tong thang: payout = stake × 0.98 × 9', () {
      expect(xsPayout(10000, XsBetKind.dungTong, 4, exactValue: 4),
          closeTo(88200, 1e-6));
    });
  });

  group('XsStats — house edge hoi tu theo tung loai keo', () {
    // Mo phong nhieu ky, dat 1 loai keo co dinh, tra ve bien thuc te.
    double simulateEdge(XsBetKind kind, {int? exactValue, int seed = 42}) {
      final rng = Random(seed);
      final stats = XsStats();
      const stake = 100000.0;
      const rounds = 40000; // du lon de hoi tu
      for (var i = 0; i < rounds; i++) {
        final result = rng.nextInt(10);
        final paid = xsPayout(stake, kind, result, exactValue: exactValue);
        stats.record(wagered: stake, paid: paid);
      }
      return stats.actualEdge!;
    }

    test('Tai/Xiu (even-money ×2, p=0.5) hoi tu dung phi 2%', () {
      // Bien ly thuyet = 1 − 0.98×2×0.5 = 0.02.
      expect(simulateEdge(XsBetKind.tai), closeTo(0.02, 0.01));
      expect(simulateEdge(XsBetKind.xiu), closeTo(0.02, 0.01));
    });

    test('Le/Chan (co so ×1.5) co bien cao hon ~6.9%', () {
      // 1 − 0.98×(2×0.4 + 1.5×0.1) = 1 − 0.98×0.95 = 0.069.
      expect(simulateEdge(XsBetKind.le), closeTo(0.069, 0.01));
      expect(simulateEdge(XsBetKind.chan), closeTo(0.069, 0.01));
    });

    test('Dac biet ×4.5 va Dung tong ×9 co bien cao nhat ~11.8%', () {
      // Dac biet: 1 − 0.98×4.5×0.2 = 0.118. Dung tong: 1 − 0.98×9×0.1 = 0.118.
      expect(simulateEdge(XsBetKind.dacBiet), closeTo(0.118, 0.01));
      expect(simulateEdge(XsBetKind.dungTong, exactValue: 7),
          closeTo(0.118, 0.015));
    });

    test('actualEdge null khi chua co cuoc', () {
      expect(XsStats().actualEdge, isNull);
    });
  });

  group('Helper phan loai', () {
    test('xsIsTai', () {
      for (var r = 0; r <= 9; r++) {
        expect(xsIsTai(r), r >= 5);
      }
    });
    test('xsIsSpecial chi 0 va 5', () {
      for (var r = 0; r <= 9; r++) {
        expect(xsIsSpecial(r), r == 0 || r == 5);
      }
    });
  });

  group('XsBet.selectionKey — R2 gop cuoc trung', () {
    test('cuoc dung tong khac so -> key khac nhau', () {
      const a = XsBet(kind: XsBetKind.dungTong, amount: 1000, exactValue: 3);
      const b = XsBet(kind: XsBetKind.dungTong, amount: 1000, exactValue: 4);
      expect(a.selectionKey == b.selectionKey, isFalse);
    });
    test('cuoc cung loai (Tai) -> cung key', () {
      const a = XsBet(kind: XsBetKind.tai, amount: 1000);
      const b = XsBet(kind: XsBetKind.tai, amount: 2000);
      expect(a.selectionKey == b.selectionKey, isTrue);
    });
  });
}
