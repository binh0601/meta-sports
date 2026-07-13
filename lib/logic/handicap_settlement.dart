/// Cham keo chap (Asian Handicap) — thuan Dart, khong import Flutter.
/// Quy uoc: [line] la line theo goc nhin CUA nguoi choi da chon.
///   Chon cua tren (home)  -> line = homeHandicap        (thuong am)
///   Chon cua duoi (away)  -> line = -homeHandicap       (thuong duong)
/// Tra ve ty le hoan tien (ratio = tien ve / tien cuoc) + trang thai hien thi.
library;

enum SettleStatus { win, halfWin, push, halfLose, lose }

/// Cham mot nua tien tai 1 line boi 0.5. Tra ve ty le hoan cua nua do:
///   thang -> odds ; hoa von -> 1.0 ; thua -> 0.0
double _half(double effMargin, double odds) {
  if (effMargin > 0) return odds;
  if (effMargin == 0) return 1.0;
  return 0.0;
}

({double ratio, SettleStatus status}) settleHandicap({
  required int goalsFor,
  required int goalsAgainst,
  required double line,
  required double odds,
}) {
  final margin = goalsFor - goalsAgainst;
  final isQuarter = (line * 4).round().isOdd; // boi 0.25 nhung khong boi 0.5
  if (!isQuarter) {
    final r = _half(margin + line, odds);
    final s = r == 0.0
        ? SettleStatus.lose
        : (r == 1.0 ? SettleStatus.push : SettleStatus.win);
    return (ratio: r, status: s);
  }
  final lo = _half(margin + line - 0.25, odds); // nua o line thap hon
  final hi = _half(margin + line + 0.25, odds); // nua o line cao hon
  final ratio = 0.5 * lo + 0.5 * hi;
  return (ratio: ratio, status: _quarterStatus(lo, hi, odds));
}

SettleStatus _quarterStatus(double lo, double hi, double odds) {
  final loWin = lo == odds, loPush = lo == 1.0;
  final hiWin = hi == odds, hiPush = hi == 1.0;
  if (loWin && hiWin) return SettleStatus.win;
  if ((loWin && hiPush) || (loPush && hiWin)) return SettleStatus.halfWin;
  if ((loPush && !hiWin && hi == 0.0) || (hiPush && lo == 0.0)) {
    return SettleStatus.halfLose;
  }
  return SettleStatus.lose;
}
