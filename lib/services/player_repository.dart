import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../logic/football_market.dart';
import 'firebase_bootstrap.dart';

/// Doc/ghi du lieu nguoi choi tren Firestore:
///   users/{uid}: email, displayName, balance, roundNumber, resetAt, createdAt
///   users/{uid}/bets/{auto}: round, legs[], stake, totalOdds, won, payout,
///                            net, balanceAfter, settledAt
/// Moi ham deu tu nuot loi mang (fire-and-forget) de khong chan gameplay.
class PlayerRepository {
  PlayerRepository._();
  static final PlayerRepository instance = PlayerRepository._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  /// Tra ve profile vi; user moi duoc tao voi [defaultBalance].
  /// Tai khoan cu thieu field vi -> mac dinh totalFunded=500, wagered=0.
  Future<({
    double balance,
    int roundNumber,
    double totalFunded,
    double totalWagered,
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
      );
    }
    final d = snap.data()!;
    return (
      balance: (d['balance'] as num?)?.toDouble() ?? defaultBalance,
      roundNumber: (d['roundNumber'] as num?)?.toInt() ?? 1,
      totalFunded: (d['totalFunded'] as num?)?.toDouble() ?? defaultBalance,
      totalWagered: (d['totalWagered'] as num?)?.toDouble() ?? 0.0,
    );
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
}
