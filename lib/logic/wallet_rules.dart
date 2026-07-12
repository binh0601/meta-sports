import 'dart:math';

import 'betting_math.dart';

/// Quy tac rollover cua nha cai: tien duoc cap/nap phai duoc dat cuoc
/// du [rolloverMultiplier] lan truoc khi cho rut — mo phong dieu khoan
/// bonus that (giu chan nguoi choi nop tien cho house edge nhieu vong).
/// Thuan Dart, khong import Flutter — de unit test.
class WalletRules {
  static const int rolloverMultiplier = 5;

  double totalFunded; // tong tien duoc cap + da nap (k)
  double totalWagered; // tong tien da dat cuoc (k)

  WalletRules({this.totalFunded = 0, this.totalWagered = 0});

  /// Tong tien phai cuoc de duoc rut.
  double get requirement => totalFunded * rolloverMultiplier;

  /// Con phai cuoc them bao nhieu (0 khi da du).
  double get remaining => max(0, requirement - totalWagered);

  /// Tien do rollover 0..1 (ve progress bar).
  double get progress =>
      requirement <= 0 ? 0 : min(1, totalWagered / requirement);

  void deposit(double amount) => totalFunded += amount;

  void recordWager(double stake) => totalWagered += stake;

  bool canWithdraw({required double balance, required bool hasPending}) =>
      withdrawBlockReason(balance: balance, hasPending: hasPending) == null;

  /// Ly do chua duoc rut (tieng Viet, hien tren UI) — null la duoc rut.
  String? withdrawBlockReason(
      {required double balance, required bool hasPending}) {
    if (balance <= 0) return 'Ví trống — nạp tiền để chơi tiếp.';
    if (hasPending) {
      return 'Còn phiếu chờ kết quả — đá xong vòng này mới được rút.';
    }
    if (totalWagered < requirement) {
      return 'Cần cược thêm ${fmtMoney(remaining)} nữa mới đủ điều kiện rút '
          '(đã cược ${fmtMoney(totalWagered)}/${fmtMoney(requirement)}).';
    }
    return null;
  }

  /// Sau khi rut toan bo: ve 0, muon choi tiep phai nap moi.
  void resetAfterWithdraw() {
    totalFunded = 0;
    totalWagered = 0;
  }

  /// Choi lai tu dau voi so tien cap moi.
  void reset(double initialFund) {
    totalFunded = initialFund;
    totalWagered = 0;
  }
}
