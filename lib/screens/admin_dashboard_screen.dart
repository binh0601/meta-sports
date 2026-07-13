import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../logic/betting_math.dart';
import '../services/player_repository.dart';
import '../theme/brand_colors.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: kBrandGradient),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Duyệt Nạp tiền'),
              Tab(text: 'Duyệt Rút tiền'),
              Tab(text: 'Lịch sử duyệt'),
            ],
            indicatorColor: kGold,
            labelColor: kGold,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: const TabBarView(
          children: [
            _DepositTab(),
            _WithdrawTab(),
            _HistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _DepositTab extends StatelessWidget {
  const _DepositTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: PlayerRepository.instance.listenToPendingDeposits(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final t1 = a.data()['createdAt'] as Timestamp?;
          final t2 = b.data()['createdAt'] as Timestamp?;
          if (t1 == null && t2 == null) return 0;
          if (t1 == null) return 1;
          if (t2 == null) return -1;
          return t2.compareTo(t1);
        });

        if (docs.isEmpty) return const Center(child: Text('Không có yêu cầu nạp tiền chờ duyệt.'));

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final amount = data['amount'] as int? ?? 0;
            final transferCode = data['transferCode'] as String? ?? '';
            final username = data['username'] as String? ?? 'Unknown';
            final uid = data['uid'] as String? ?? '';
            final createdAt = data['createdAt'] as Timestamp?;
            final timeStr = createdAt != null 
              ? '${createdAt.toDate().hour.toString().padLeft(2, '0')}:${createdAt.toDate().minute.toString().padLeft(2, '0')} - ${createdAt.toDate().day}/${createdAt.toDate().month}' 
              : '';

            return Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(transferCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kGold)),
                        Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Người nạp: $username', style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Số tiền: ${fmtMoney(amount.toDouble())}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                          onPressed: () => _rejectDeposit(context, doc.id),
                          child: const Text('Từ chối'),
                        ),
                        const SizedBox(width: 16),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () => _approveDeposit(context, doc.id, uid, amount),
                          child: const Text('Duyệt ngay'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _approveDeposit(BuildContext context, String depositId, String uid, int amount) async {
    final nav = Navigator.of(context);
    final sm = ScaffoldMessenger.of(context);

    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
    final success = await PlayerRepository.instance.approveDeposit(depositId, uid, amount);
    nav.pop();

    if (success) {
      sm.showSnackBar(const SnackBar(content: Text('Đã duyệt thành công, tiền đã được cộng!'), backgroundColor: Colors.green));
    } else {
      sm.showSnackBar(const SnackBar(content: Text('Lỗi duyệt nạp tiền.'), backgroundColor: Colors.red));
    }
  }

  void _rejectDeposit(BuildContext context, String depositId) async {
    final nav = Navigator.of(context);
    final sm = ScaffoldMessenger.of(context);

    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
    final success = await PlayerRepository.instance.rejectDeposit(depositId);
    nav.pop();

    if (success) sm.showSnackBar(const SnackBar(content: Text('Đã từ chối nạp tiền!')));
  }
}

class _WithdrawTab extends StatelessWidget {
  const _WithdrawTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: PlayerRepository.instance.listenToPendingWithdrawals(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final t1 = a.data()['createdAt'] as Timestamp?;
          final t2 = b.data()['createdAt'] as Timestamp?;
          if (t1 == null && t2 == null) return 0;
          if (t1 == null) return 1;
          if (t2 == null) return -1;
          return t2.compareTo(t1);
        });

        if (docs.isEmpty) return const Center(child: Text('Không có yêu cầu rút tiền chờ duyệt.'));

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final amount = data['amount'] as int? ?? 0;
            final bankName = data['bankName'] as String? ?? '';
            final bankAccountNo = data['bankAccountNo'] as String? ?? '';
            final bankAccountName = data['bankAccountName'] as String? ?? '';
            final username = data['username'] as String? ?? 'Unknown';
            final uid = data['uid'] as String? ?? '';
            
            final createdAt = data['createdAt'] as Timestamp?;
            final timeStr = createdAt != null 
              ? '${createdAt.toDate().hour.toString().padLeft(2, '0')}:${createdAt.toDate().minute.toString().padLeft(2, '0')}' 
              : '';

            return Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('LỆNH RÚT TIỀN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kGold)),
                        Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Người rút: $username', style: const TextStyle(fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text('Số tiền: ${fmtMoney(amount.toDouble())}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    const Divider(height: 24, color: Colors.white24),
                    Text('Ngân hàng: $bankName', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('STK: $bankAccountNo', style: const TextStyle(fontSize: 16)),
                        // Optional: Copy button
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Chủ thẻ: $bankAccountName', style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                          onPressed: () => _showRejectDialog(context, doc.id, uid, amount),
                          child: const Text('Từ chối'),
                        ),
                        const SizedBox(width: 16),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.green),
                          onPressed: () => _approveWithdrawal(context, doc.id),
                          child: const Text('Đã C/K (Duyệt)'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _approveWithdrawal(BuildContext context, String withdrawId) async {
    final nav = Navigator.of(context);
    final sm = ScaffoldMessenger.of(context);
    final adminEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown Admin';

    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
    final success = await PlayerRepository.instance.approveWithdrawal(withdrawId, adminEmail);
    nav.pop();

    if (success) {
      sm.showSnackBar(const SnackBar(content: Text('Đã duyệt rút tiền thành công!'), backgroundColor: Colors.green));
    } else {
      sm.showSnackBar(const SnackBar(content: Text('Lỗi duyệt rút tiền.'), backgroundColor: Colors.red));
    }
  }

  void _showRejectDialog(BuildContext context, String withdrawId, String uid, int amount) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối rút tiền'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Số tiền sẽ được hoàn lại vào ví của người chơi. Hãy ghi lý do từ chối:'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'Lý do (Tùy chọn)', border: OutlineInputBorder()),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _rejectWithdrawal(context, withdrawId, uid, amount, ctrl.text.trim());
            }, 
            child: const Text('Từ chối & Hoàn tiền')
          ),
        ],
      )
    );
  }

  void _rejectWithdrawal(BuildContext context, String withdrawId, String uid, int amount, String reason) async {
    final nav = Navigator.of(context);
    final sm = ScaffoldMessenger.of(context);
    final adminEmail = FirebaseAuth.instance.currentUser?.email ?? 'Unknown Admin';

    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
    final success = await PlayerRepository.instance.rejectWithdrawal(withdrawId, uid, amount, adminEmail, reason);
    nav.pop();

    if (success) {
      sm.showSnackBar(const SnackBar(content: Text('Đã từ chối rút và hoàn tiền cho user!')));
    } else {
      sm.showSnackBar(const SnackBar(content: Text('Lỗi khi từ chối.'), backgroundColor: Colors.red));
    }
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    // Để đơn giản và nhanh gọn, ta kết hợp 2 streams (Nạp và Rút) bằng rxdart hoặc StreamGroup
    // Nhưng vì không có sẵn rxdart, ta dùng FutureBuilder hoặc ListView với 2 danh sách.
    // Cách dễ nhất là dùng 1 StreamBuilder cho Nạp và 1 cho Rút, hiển thị thành 2 mảng.
    // Tuy nhiên giao diện đẹp nhất là trộn lại. Ta sẽ dùng DefaultTabController lồng nhau hoặc chỉ hiện danh sách riêng.
    
    // Ở đây ta tạo 1 màn hình đơn giản chia làm 2 phần: Lịch sử Nạp và Lịch sử Rút.
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [Tab(text: 'Lịch sử Nạp'), Tab(text: 'Lịch sử Rút')],
            labelColor: kGold,
            unselectedLabelColor: Colors.white70,
            indicatorColor: kGold,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildProcessedDeposits(),
                _buildProcessedWithdrawals(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProcessedDeposits() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: PlayerRepository.instance.listenToProcessedDeposits(),
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
            final status = data['status'] as String? ?? '';
            final isApproved = status == 'approved';
            
            return ListTile(
              leading: Icon(isApproved ? Icons.check_circle : Icons.cancel, color: isApproved ? Colors.green : Colors.red),
              title: Text('Nạp: ${fmtMoney(amount.toDouble())} - ${data['username']}'),
              subtitle: Text(isApproved ? 'Đã duyệt' : 'Đã từ chối'),
              trailing: Text(_formatTime(data['processedAt'])),
            );
          },
        );
      },
    );
  }

  Widget _buildProcessedWithdrawals() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: PlayerRepository.instance.listenToProcessedWithdrawals(),
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
            final status = data['status'] as String? ?? '';
            final isApproved = status == 'approved';
            final reason = data['rejectReason'] as String? ?? '';
            
            return ListTile(
              leading: Icon(isApproved ? Icons.check_circle : Icons.cancel, color: isApproved ? Colors.green : Colors.red),
              title: Text('Rút: ${fmtMoney(amount.toDouble())} - ${data['username']}'),
              subtitle: Text(isApproved ? 'Đã duyệt' : 'Đã từ chối ${reason.isNotEmpty ? "($reason)" : ""}'),
              trailing: Text(_formatTime(data['processedAt'])),
            );
          },
        );
      },
    );
  }

  int _sortByDate(QueryDocumentSnapshot<Map<String, dynamic>> a, QueryDocumentSnapshot<Map<String, dynamic>> b) {
    final t1 = a.data()['processedAt'] as Timestamp?;
    final t2 = b.data()['processedAt'] as Timestamp?;
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
