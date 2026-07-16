// Toan hoc loi cho game "KEO CHOP · 30 giay" — ban bong da hoa cua game
// doan so 0–9 (spec: docs/SPEC-xac-suat-30.md).
//
// Ket qua RNG 0–9 = TONG BAN THANG cua mot tran chop nhoang. Cac loai keo
// anh xa sang keo bong da that (Tai/Xiu, Le/Chan) nhung he so & dieu kien
// thang giu nguyen spec muc 3.1. File nay thuan Dart — KHONG import Flutter,
// de unit test.

/// Loai keo. Nhan hien thi tieng Viet dat o lop UI (xac_suat_screen).
enum XsBetKind {
  tai, // Big  {5,6,7,8,9} ×2
  xiu, // Small {0,1,2,3,4} ×2
  le, // Green: le {1,3,7,9}×2, {5}×1.5
  chan, // Red:  chan {2,4,6,8}×2, {0}×1.5
  dacBiet, // Purple {0,5} ×4.5
  dungTong, // Number: dung tong ban da chon ×9
}

/// Phi khau tru moi luot dat, tao house edge ~2%.
const double kXsFeeRate = 0.02;

/// He so nhan tren stake truoc khi ap he so thang: stake_effective.
const double kXsStakeEffectiveMul = 1 - kXsFeeRate; // 0.98

/// R2: khong duoc dat tu 8 so rieng biet tro len -> toi da 7 so "dung tong".
const int kXsMaxDistinctExactPicks = 7;

/// Tong ban >= 5 la "Tai" (nhieu ban), <= 4 la "Xiu" (it ban).
bool xsIsTai(int result) => result >= 5;

/// {0,5} la ket qua "dac biet" (tit ngoi / moc 5) — thuoc ca Le/Chan lan Tim.
bool xsIsSpecial(int result) => result == 0 || result == 5;

/// He so thang cho mot loai keo voi ket qua da co; 0.0 neu thua.
/// [exactValue] chi dung cho [XsBetKind.dungTong].
double xsMultiplier(XsBetKind kind, int result, {int? exactValue}) {
  switch (kind) {
    case XsBetKind.tai:
      return result >= 5 ? 2.0 : 0.0;
    case XsBetKind.xiu:
      return result <= 4 ? 2.0 : 0.0;
    case XsBetKind.le:
      if (result == 1 || result == 3 || result == 7 || result == 9) return 2.0;
      if (result == 5) return 1.5; // so le "dac biet" an thap hon
      return 0.0;
    case XsBetKind.chan:
      if (result == 2 || result == 4 || result == 6 || result == 8) return 2.0;
      if (result == 0) return 1.5; // so chan "dac biet" an thap hon
      return 0.0;
    case XsBetKind.dacBiet:
      return (result == 0 || result == 5) ? 4.5 : 0.0;
    case XsBetKind.dungTong:
      return (exactValue != null && result == exactValue) ? 9.0 : 0.0;
  }
}

/// Tien thuong thuc nhan cho mot luot cuoc (0 neu thua).
/// payout = stake × 0.98 × multiplier.
double xsPayout(double stake, XsBetKind kind, int result, {int? exactValue}) {
  final m = xsMultiplier(kind, result, exactValue: exactValue);
  if (m <= 0) return 0.0;
  return stake * kXsStakeEffectiveMul * m;
}

/// Mot luot dat cuoc dang cho ket qua trong ky hien tai.
class XsBet {
  final XsBetKind kind;
  final int? exactValue; // chi != null voi dungTong
  final double amount;

  const XsBet({required this.kind, required this.amount, this.exactValue});

  /// Khoa nhan dien de to mau / gop cuoc trung o UI.
  Object get selectionKey =>
      kind == XsBetKind.dungTong ? 'num_$exactValue' : kind.name;

  double payoutFor(int result) =>
      xsPayout(amount, kind, result, exactValue: exactValue);
}

/// Ket qua mot ky da mo — luu lich su + ve bang ty so.
class XsRoundResult {
  final int seq;
  final int result; // tong ban 0–9
  final int homeGoals; // scoreline trang tri: homeGoals + awayGoals = result
  final int awayGoals;
  final double netChange; // lai/lo rong cua ky (0 neu khong dat)
  final bool hadBets;

  const XsRoundResult({
    required this.seq,
    required this.result,
    required this.homeGoals,
    required this.awayGoals,
    required this.netChange,
    required this.hadBets,
  });
}

/// Theo doi house edge: bien thuc te hoi tu ~2% khi choi nhieu ky.
class XsStats {
  double totalWagered = 0;
  double totalPaid = 0;

  void record({required double wagered, required double paid}) {
    totalWagered += wagered;
    totalPaid += paid;
  }

  /// (totalWagered − totalPaid) / totalWagered — null khi chua co cuoc nao.
  double? get actualEdge =>
      totalWagered <= 0 ? null : (totalWagered - totalPaid) / totalWagered;
}
