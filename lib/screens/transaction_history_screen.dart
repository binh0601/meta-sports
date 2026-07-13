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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lịch sử Nạp/Rút'),
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
            _buildUserDeposits(uid),
            _buildUserWithdrawals(uid),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDeposits(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: PlayerRepository.instance.listenToUserDeposits(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) => _sortByDate(a, b));
        
        if (docs.isEmpty) return const Center(child: Text('Chưa có dữ liệu.'));
        
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final amount = data['amount'] as int? ?? 0;
            final status = data['status'] as String? ?? 'pending';
            final code = data['transferCode'] as String? ?? '';
            
            IconData icon;
            Color color;
            String statusText;
            if (status == 'approved') {
              icon = Icons.check_circle;
              color = Colors.green;
              statusText = 'Thành công';
            } else if (status == 'rejected') {
              icon = Icons.cancel;
              color = Colors.red;
              statusText = 'Bị từ chối';
            } else {
              icon = Icons.pending;
              color = Colors.amber;
              statusText = 'Đang chờ duyệt';
            }
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: Icon(icon, color: color),
                title: Text('Nạp tiền: ${fmtMoney(amount.toDouble())}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Mã: $code\nTrạng thái: $statusText'),
                trailing: Text(_formatTime(data['createdAt'])),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserWithdrawals(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: PlayerRepository.instance.listenToUserWithdrawals(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) => _sortByDate(a, b));
        
        if (docs.isEmpty) return const Center(child: Text('Chưa có dữ liệu.'));
        
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final amount = data['amount'] as int? ?? 0;
            final status = data['status'] as String? ?? 'pending';
            final bank = data['bankName'] as String? ?? '';
            final reason = data['rejectReason'] as String? ?? '';
            
            IconData icon;
            Color color;
            String statusText;
            if (status == 'approved') {
              icon = Icons.check_circle;
              color = Colors.green;
              statusText = 'Đã hoàn tất';
            } else if (status == 'rejected') {
              icon = Icons.cancel;
              color = Colors.red;
              statusText = 'Bị từ chối ${reason.isNotEmpty ? "($reason)" : ""}';
            } else {
              icon = Icons.pending;
              color = Colors.amber;
              statusText = 'Đang chờ xử lý';
            }
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: Icon(icon, color: color),
                title: Text('Rút tiền: ${fmtMoney(amount.toDouble())}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Về: $bank\nTrạng thái: $statusText'),
                trailing: Text(_formatTime(data['createdAt'])),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  int _sortByDate(QueryDocumentSnapshot<Map<String, dynamic>> a, QueryDocumentSnapshot<Map<String, dynamic>> b) {
    final t1 = a.data()['createdAt'] as Timestamp?;
    final t2 = b.data()['createdAt'] as Timestamp?;
    if (t1 == null && t2 == null) return 0;
    if (t1 == null) return 1;
    if (t2 == null) return -1;
    return t2.compareTo(t1);
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) return '';
    final d = timestamp.toDate();
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} - ${d.day}/${d.month}';
  }
}
