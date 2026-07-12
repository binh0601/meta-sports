import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/wallet_rules.dart';

void main() {
  test('cap 500 -> can cuoc 2500 moi duoc rut', () {
    final w = WalletRules(totalFunded: 500);
    expect(w.requirement, 2500);
    expect(w.remaining, 2500);
    expect(w.canWithdraw(balance: 500, hasPending: false), false);
  });

  test('nap 200 -> requirement tang them 1000', () {
    final w = WalletRules(totalFunded: 500)..deposit(200);
    expect(w.totalFunded, 700);
    expect(w.requirement, 3500);
  });

  test('cuoc du 5x -> duoc rut khi vi con tien va khong pending', () {
    final w = WalletRules(totalFunded: 500)..recordWager(2500);
    expect(w.canWithdraw(balance: 300, hasPending: false), true);
    expect(w.withdrawBlockReason(balance: 300, hasPending: false), null);
  });

  test('du rollover nhung con phieu pending -> chua duoc rut', () {
    final w = WalletRules(totalFunded: 500)..recordWager(2500);
    expect(w.canWithdraw(balance: 300, hasPending: true), false);
    expect(w.withdrawBlockReason(balance: 300, hasPending: true),
        contains('phiếu chờ'));
  });

  test('vi rong -> khong rut duoc, ly do bao nap tien', () {
    final w = WalletRules(totalFunded: 500)..recordWager(2500);
    expect(w.canWithdraw(balance: 0, hasPending: false), false);
    expect(w.withdrawBlockReason(balance: 0, hasPending: false),
        contains('nạp'));
  });

  test('chua du rollover -> ly do neu ro so tien can cuoc them', () {
    final w = WalletRules(totalFunded: 500)..recordWager(1000);
    expect(w.withdrawBlockReason(balance: 400, hasPending: false),
        contains('cược thêm'));
    expect(w.remaining, 1500);
  });

  test('rut xong reset ve 0, nap moi tao requirement moi', () {
    final w = WalletRules(totalFunded: 500)..recordWager(2500);
    w.resetAfterWithdraw();
    expect(w.totalFunded, 0);
    expect(w.requirement, 0);
    w.deposit(100);
    expect(w.requirement, 500);
    expect(w.canWithdraw(balance: 100, hasPending: false), false);
  });

  test('progress bi chan trong [0,1]', () {
    final w = WalletRules(totalFunded: 500)..recordWager(9999);
    expect(w.progress, 1.0);
    expect(WalletRules(totalFunded: 0).progress, 0.0);
  });
}
