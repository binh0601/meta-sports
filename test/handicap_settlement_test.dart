import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/handicap_settlement.dart';

void main() {
  // Home = cua tren, line = homeHandicap (am). odds 2.0 cho de tinh.
  ({double ratio, SettleStatus status}) home(int hg, int ag, double line) =>
      settleHandicap(goalsFor: hg, goalsAgainst: ag, line: line, odds: 2.0);

  test('chap 1 (line -1)', () {
    expect(home(3, 1, -1.0).status, SettleStatus.win); // thang 2 -> an du
    expect(home(3, 1, -1.0).ratio, 2.0);
    expect(home(2, 1, -1.0).status, SettleStatus.push); // thang 1 -> hoan
    expect(home(2, 1, -1.0).ratio, 1.0);
    expect(home(1, 1, -1.0).status, SettleStatus.lose); // hoa -> mat
    expect(home(0, 2, -1.0).status, SettleStatus.lose); // thua -> mat
  });

  test('chap 0.5 (line -0.5)', () {
    expect(home(1, 0, -0.5).status, SettleStatus.win);
    expect(home(1, 1, -0.5).status, SettleStatus.lose); // hoa -> mat
    expect(home(0, 1, -0.5).status, SettleStatus.lose);
  });

  test('chap 0.25 (line -0.25)', () {
    expect(home(1, 0, -0.25).status, SettleStatus.win); // thang -> an du
    expect(home(1, 0, -0.25).ratio, 2.0);
    final draw = home(1, 1, -0.25); // hoa
    expect(draw.status, SettleStatus.halfLose); // hoan nua + thua nua
    expect(draw.ratio, 0.5); // 0.5*1.0 + 0.5*0
    expect(home(0, 1, -0.25).status, SettleStatus.lose); // thua -> mat het
  });

  test('chap 0.75 (line -0.75)', () {
    expect(home(3, 1, -0.75).status, SettleStatus.win); // thang 2 -> an du
    final win1 = home(2, 1, -0.75); // thang dung 1
    expect(win1.status, SettleStatus.halfWin); // an nua + hoan nua
    expect(win1.ratio, 1.5); // 0.5*2.0 + 0.5*1.0
    expect(home(1, 1, -0.75).status, SettleStatus.lose); // hoa -> mat het
    expect(home(0, 2, -0.75).status, SettleStatus.lose);
  });

  test('cua duoi (away) doi xung: away nhan 0.5 (line +0.5)', () {
    // away goalsFor=ag, goalsAgainst=hg. Away +0.5: hoa -> away an.
    final r = settleHandicap(goalsFor: 1, goalsAgainst: 1, line: 0.5, odds: 2.0);
    expect(r.status, SettleStatus.win);
  });
}
