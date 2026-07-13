import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../logic/betting_math.dart';
import '../services/player_repository.dart';
import '../theme/brand_colors.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(title: const Text('Lịch sử giao dịch')),
        body: const Center(child: Text('Vui lòng đăng nhập để xem lịch sử.')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: const Text('Lịch sử giao dịch'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: kBrandGradient),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Lịch sử Nạp'),
              Tab(text: 'Lịch sử Rút'),
            ],
            indicatorColor: kGold,
            labelColor: kGold,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            _DepositHistoryTab(uid: user.uid),
            _WithdrawHistoryTab(uid: user.uid),
          ],
        ),
      ),
    );
  }
}

class _DepositHistoryTab extends StatelessWidget {
  final String uid;
  const _DepositHistoryTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: PlayerRepository.instance.listenToUserDeposits(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs.toList();
        
        // Sắp xếp theo ngày tạo (mới nhất lên đầu)
        docs.sort((a, b) {
          final t1 = a.data()['createdAt'] as Timestamp?;
          final t2 = b.data()['createdAt'] as Timestamp?;
          if (t1 == null && t2 == null) return 0;
          if (t1 == null) return 1;
          if (t2 == null) return -1;
          return t2.compareTo(t1);
        });

        if (docs.isEmpty) {
          return const Center(
            child: Text('Bạn chưa có yêu cầu nạp tiền nào.', style: TextStyle(color: Colors.white70)),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final amount = data['amount'] as int? ?? 0;
            final transferCode = data['transferCode'] as String? ?? '';
            final status = data['status'] as String? ?? 'pending';
            final createdAt = data['createdAt'] as Timestamp?;
            
            final timeStr = createdAt != null 
              ? '${createdAt.toDate().hour.toString().padLeft(2, '0')}:${createdAt.toDate().minute.toString().padLeft(2, '0')} - ${createdAt.toDate().day}/${createdAt.toDate().month}' 
              : '';

            Color statusColor = Colors.orange;
            String statusText = 'Chờ duyệt';
            if (status == 'approved') {
              statusColor = Colors.green;
              statusText = 'Thành công';
            } else if (status == 'rejected') {
              statusColor = Colors.red;
              statusText = 'Bị từ chối';
            }

            return Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(transferCode, style: const TextStyle(fontWeight: FontWeight.bold, color: kGold)),
                    Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(timeStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(
                        '+ ${fmtMoney(amount.toDouble())}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _WithdrawHistoryTab extends StatelessWidget {
  final String uid;
  const _WithdrawHistoryTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: PlayerRepository.instance.listenToUserWithdrawals(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs.toList();
        
        // Sắp xếp theo ngày tạo (mới nhất lên đầu)
        docs.sort((a, b) {
          final t1 = a.data()['createdAt'] as Timestamp?;
          final t2 = b.data()['createdAt'] as Timestamp?;
          if (t1 == null && t2 == null) return 0;
          if (t1 == null) return 1;
          if (t2 == null) return -1;
          return t2.compareTo(t1);
        });

        if (docs.isEmpty) {
          return const Center(
            child: Text('Bạn chưa có yêu cầu rút tiền nào.', style: TextStyle(color: Colors.white70)),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final amount = data['amount'] as int? ?? 0;
            final bankName = data['bankName'] as String? ?? '';
            final bankAccountNo = data['bankAccountNo'] as String? ?? '';
            final status = data['status'] as String? ?? 'pending';
            final rejectReason = data['rejectReason'] as String?;
            final createdAt = data['createdAt'] as Timestamp?;
            
            final timeStr = createdAt != null 
              ? '${createdAt.toDate().hour.toString().padLeft(2, '0')}:${createdAt.toDate().minute.toString().padLeft(2, '0')} - ${createdAt.toDate().day}/${createdAt.toDate().month}' 
              : '';

            Color statusColor = Colors.orange;
            String statusText = 'Chờ duyệt';
            if (status == 'approved') {
              statusColor = Colors.green;
              statusText = 'Thành công';
            } else if (status == 'rejected') {
              statusColor = Colors.red;
              statusText = 'Đã từ chối';
            }

            return Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$bankName - $bankAccountNo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            statusText,
                            style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(timeStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            Text(
                              '- ${fmtMoney(amount.toDouble())}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (status == 'rejected' && rejectReason != null && rejectReason.isNotEmpty) ...[
                      const Divider(color: Colors.white12, height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0, top: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Lý do từ chối: ', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                rejectReason,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    ]
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
