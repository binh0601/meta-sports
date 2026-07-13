import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../logic/football_market.dart';
import 'firebase_bootstrap.dart';

/// Doc/ghi du lieu nguoi choi tren Firestore:
///   users/{uid}: email, displayName, balance, roundNumber, resetAt, createdAt
///   users/{uid}/bets/{auto}: round, legs[], stake, totalOdds, won, payout,
///                            net, balanceAfter, settledAt
///   deposits/{orderCode}: orderCode, uid, username, amount, status, transferCode, expiredAt, createdAt
/// Moi ham deu tu nuot loi mang (fire-and-forget) de khong chan gameplay.
class PlayerRepository {
  PlayerRepository._();
  static final PlayerRepository instance = PlayerRepository._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  /// Tạo yêu cầu nạp tiền thủ công
  Future<Map<String, dynamic>?> createManualDeposit({
    required String uid,
    required String username,
    required int amountVnd,
    required int orderCode,
    required String transferCode,
  }) async {
    try {
      final docRef = _db.collection('deposits').doc(orderCode.toString());
      
      await docRef.set({
        'orderCode': orderCode,
        'uid': uid,
        'username': username,
        'amount': amountVnd,
        'status': 'pending',
        'transferCode': transferCode,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return {
        'success': true,
        'orderCode': orderCode,
        'transferCode': transferCode,
      };
    } catch (e) {
      debugPrint('createManualDeposit Exception: $e');
      return null;
    }
  }

  /// Tạo yêu cầu rút tiền (Atomic Transaction để trừ tiền ngay lập tức)
  Future<bool> createWithdrawRequest({
    required String uid,
    required String username,
    required int amountVnd,
    required String bankName,
    required String bankAccountNo,
    required String bankAccountName,
  }) async {
    try {
      final orderCode = DateTime.now().millisecondsSinceEpoch;
      final withdrawRef = _db.collection('withdrawals').doc(orderCode.toString());
      final userRef = _userDoc(uid);
      
      await _db.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw Exception("User not found");
        
        final balance = (userDoc.data()!['balance'] as num?)?.toDouble() ?? 0.0;
        if (balance < amountVnd) {
          throw Exception("Insufficient balance");
        }
        
        // Tạo hóa đơn pending
        transaction.set(withdrawRef, {
          'orderCode': orderCode,
          'uid': uid,
          'username': username,
          'amount': amountVnd,
          'status': 'pending',
          'bankName': bankName,
          'bankAccountNo': bankAccountNo,
          'bankAccountName': bankAccountName,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Trừ tiền ngay lập tức
        transaction.update(userRef, {
          'balance': FieldValue.increment(-amountVnd),
        });
      });
      
      return true;
    } catch (e) {
      debugPrint('createWithdrawRequest Exception: $e');
      return false;
    }
  }

  /// Dành cho Admin: Lấy danh sách chờ duyệt
  Stream<QuerySnapshot<Map<String, dynamic>>> listenToPendingDeposits() {
    return _db
        .collection('deposits')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// Dành cho Admin: Duyệt nạp tiền (Cộng tiền an toàn qua Transaction)
  Future<bool> approveDeposit(String depositId, String uid, int amount) async {
    try {
      final depositRef = _db.collection('deposits').doc(depositId);
      final userRef = _userDoc(uid);
      
      await _db.runTransaction((transaction) async {
        final depositDoc = await transaction.get(depositRef);
        if (!depositDoc.exists) throw Exception("Deposit not found");
        
        final data = depositDoc.data()!;
        if (data['status'] == 'approved') throw Exception("Already approved");
        
        transaction.update(depositRef, {
          'status': 'approved',
          'updatedAt': FieldValue.serverTimestamp()
        });
        
        transaction.update(userRef, {
          'balance': FieldValue.increment(amount),
          'totalFunded': FieldValue.increment(amount),
        });
      });
      return true;
    } catch (e) {
      debugPrint('approveDeposit Exception: $e');
      return false;
    }
  }

  /// Dành cho Admin: Từ chối nạp tiền
  Future<bool> rejectDeposit(String depositId) async {
    try {
      await _db.collection('deposits').doc(depositId).update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp()
      });
      return true;
    } catch (e) {
      debugPrint('rejectDeposit Exception: $e');
      return false;
    }
  }

  /// Tra ve profile vi; user moi duoc tao voi [defaultBalance].
  /// Tai khoan cu thieu field vi -> mac dinh totalFunded=500, wagered=0.
  Future<({
    double balance,
    int roundNumber,
    double totalFunded,
    double totalWagered,
    String? bankName,
    String? bankAccountNo,
    String? bankAccountName,
  })> loadOrCreateProfile(User user, double defaultBalance) async {
    final ref = _userDoc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'email': user.email,
        'displayName': user.displayName ?? '',
        'balance': defaultBalance,
        'roundNumber': 1,
        'totalFunded': defaultBalance,
        'totalWagered': 0.0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return (
        balance: defaultBalance,
        roundNumber: 1,
        totalFunded: defaultBalance,
        totalWagered: 0.0,
        bankName: null,
        bankAccountNo: null,
        bankAccountName: null,
      );
    }
    final d = snap.data()!;
    return (
      balance: (d['balance'] as num?)?.toDouble() ?? defaultBalance,
      roundNumber: (d['roundNumber'] as num?)?.toInt() ?? 1,
      totalFunded: (d['totalFunded'] as num?)?.toDouble() ?? defaultBalance,
      totalWagered: (d['totalWagered'] as num?)?.toDouble() ?? 0.0,
      bankName: d['bankName'] as String?,
      bankAccountNo: d['bankAccountNo'] as String?,
      bankAccountName: d['bankAccountName'] as String?,
    );
  }

  Future<bool> updateBankInfo(String uid, String bankName, String bankAccountNo, String bankAccountName) async {
    try {
      await _userDoc(uid).update({
        'bankName': bankName,
        'bankAccountNo': bankAccountNo,
        'bankAccountName': bankAccountName,
      });
      return true;
    } catch (e) {
      debugPrint('updateBankInfo Exception: $e');
      return false;
    }
  }

  Future<void> saveState(String uid,
      {required double balance,
      required int roundNumber,
      required double totalFunded,
      required double totalWagered,
      bool markReset = false}) async {
    if (!firebaseReady) return;
    try {
      await _userDoc(uid).set({
        'balance': balance,
        'roundNumber': roundNumber,
        'totalFunded': totalFunded,
        'totalWagered': totalWagered,
        if (markReset) 'resetAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('saveState loi: $e');
    }
  }

  Future<void> saveSettledBet(
      String uid, BetSlip b, double balanceAfter) async {
    if (!firebaseReady) return;
    try {
      await _userDoc(uid).collection('bets').add({
        'round': b.round,
        'legs': [for (final l in b.legResults) l.toMap()],
        'stake': b.stake,
        'totalOdds': b.totalOdds,
        'won': b.won,
        'payout': b.payout,
        'net': b.net,
        'balanceAfter': balanceAfter,
        'settledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('saveSettledBet loi: $e');
    }
  }

  /// Khoi phuc toi da [limit] phieu gan nhat (sau lan reset cuoi),
  /// tra ve theo thu tu thoi gian tang dan kem balanceAfter de ve bieu do.
  Future<List<({BetSlip slip, double balanceAfter})>> loadRecentBets(
      String uid, {int limit = 100}) async {
    if (!firebaseReady) return [];
    try {
      final profile = await _userDoc(uid).get();
      final resetAt = profile.data()?['resetAt'] as Timestamp?;
      Query<Map<String, dynamic>> q =
          _userDoc(uid).collection('bets').orderBy('settledAt');
      if (resetAt != null) {
        q = q.where('settledAt', isGreaterThan: resetAt);
      }
      final snap = await q.limitToLast(limit).get();
      return [
        for (final doc in snap.docs)
          (
            slip: BetSlip.restored(
              legResults: [
                for (final m in (doc['legs'] as List))
                  LegResult.fromMap(Map<String, dynamic>.from(m as Map))
              ],
              stake: (doc['stake'] as num).toDouble(),
              round: (doc['round'] as num).toInt(),
              won: doc['won'] as bool,
              payout: (doc['payout'] as num).toDouble(),
            ),
            balanceAfter: (doc['balanceAfter'] as num).toDouble(),
          )
      ];
    } catch (e) {
      debugPrint('loadRecentBets loi: $e');
      return [];
    }
  }
  /// Dành cho Admin: Lấy danh sách rút tiền chờ duyệt
  Stream<QuerySnapshot<Map<String, dynamic>>> listenToPendingWithdrawals() {
    return _db
        .collection('withdrawals')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// Dành cho Admin: Duyệt rút tiền
  Future<bool> approveWithdrawal(String withdrawId, String adminEmail) async {
    try {
      await _db.collection('withdrawals').doc(withdrawId).update({
        'status': 'approved',
        'processedBy': adminEmail,
        'processedAt': FieldValue.serverTimestamp()
      });
      return true;
    } catch (e) {
      debugPrint('approveWithdrawal Exception: $e');
      return false;
    }
  }

  /// Dành cho Admin: Từ chối rút tiền (hoàn lại số dư)
  Future<bool> rejectWithdrawal(String withdrawId, String uid, int amount, String adminEmail, String? rejectReason) async {
    try {
      final withdrawRef = _db.collection('withdrawals').doc(withdrawId);
      final userRef = _userDoc(uid);

      await _db.runTransaction((transaction) async {
        final wDoc = await transaction.get(withdrawRef);
        if (!wDoc.exists || wDoc.data()!['status'] != 'pending') {
          throw Exception('Invalid withdrawal state');
        }

        // Đổi trạng thái
        transaction.update(withdrawRef, {
          'status': 'rejected',
          'rejectReason': rejectReason ?? '',
          'processedBy': adminEmail,
          'processedAt': FieldValue.serverTimestamp()
        });

        // Hoàn tiền
        transaction.update(userRef, {
          'balance': FieldValue.increment(amount),
        });
      });
      
      return true;
    } catch (e) {
      debugPrint('rejectWithdrawal Exception: $e');
      return false;
    }
  }
}
