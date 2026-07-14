import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/betting_math.dart';
import '../services/player_repository.dart';
import '../theme/brand_colors.dart';

class QrPaymentScreen extends StatefulWidget {
  final double amountVnd;

  const QrPaymentScreen({
    super.key,
    required this.amountVnd,
  });

  @override
  State<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends State<QrPaymentScreen> {
  bool _isSubmitting = false;
  late final int _orderCode;
  late final String _transferCode;

  @override
  void initState() {
    super.initState();
    _orderCode = DateTime.now().millisecondsSinceEpoch;
    final user = FirebaseAuth.instance.currentUser;
    final shortUid = user?.uid.substring(0, 5).toUpperCase() ?? 'GUEST';
    // Rút gọn transfer code, ví dụ: MS 1234 GUEST
    final suffix = _orderCode.toString().substring(_orderCode.toString().length - 4);
    _transferCode = 'MS $suffix $shortUid';
  }

  void _confirmTransfer() async {
    setState(() => _isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final result = await PlayerRepository.instance.createManualDeposit(
        uid: user.uid,
        username: user.displayName ?? user.email ?? 'Member',
        amountVnd: widget.amountVnd.round(),
        orderCode: _orderCode,
        transferCode: _transferCode,
      );

      if (mounted) {
        if (result != null && result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Đã gửi yêu cầu nạp tiền! Vui lòng chờ admin duyệt.'),
            backgroundColor: Colors.green,
          ));
          Navigator.pop(context); // Trở về trang ví
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Lỗi khi gửi yêu cầu nạp tiền. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
    
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Thông tin tài khoản Admin (Bạn có thể đổi bankId, accountNo sau)
    const String bankId = 'MB'; // Tên viết tắt NH theo VietQR (MB, VCB, TCB...)
    const String accountNo = '0359185728'; // Điền số tài khoản thật của bạn
    const String accountName = 'DANG VAN HAI';
    
    // API tạo mã QR tĩnh chuẩn VietQR
    final qrUrl = 'https://img.vietqr.io/image/$bankId-$accountNo-compact2.jpg?amount=${widget.amountVnd.round()}&addInfo=${Uri.encodeComponent(_transferCode)}&accountName=${Uri.encodeComponent(accountName)}';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Thanh toán Nạp tiền'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: kBrandGradient),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Vui lòng quét mã QR dưới đây hoặc chuyển khoản theo thông tin bên dưới để nạp tiền.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),
              
              // Mã QR
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Image.network(
                  qrUrl,
                  height: 300,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, error, stackTrace) => const SizedBox(
                    height: 300,
                    child: Center(
                      child: Text('Không tải được mã QR', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Thông tin chuyển khoản
              Card(
                color: const Color(0xFF1E293B),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow('Ngân hàng', bankId),
                      const Divider(color: Colors.white12),
                      _buildInfoRow('Số tài khoản', accountNo, copyable: true),
                      const Divider(color: Colors.white12),
                      _buildInfoRow('Tên tài khoản', accountName),
                      const Divider(color: Colors.white12),
                      _buildInfoRow('Số tiền', fmtMoney(widget.amountVnd), copyable: true, valueColor: kGold),
                      const Divider(color: Colors.white12),
                      _buildInfoRow('Nội dung', _transferCode, copyable: true, valueColor: Colors.cyan),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Lưu ý: Bắt buộc nhập đúng NỘI DUNG CHUYỂN KHOẢN để Admin duyệt lệnh nạp.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Nút xác nhận
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: kGold,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _isSubmitting ? null : _confirmTransfer,
                  icon: _isSubmitting 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
                    : const Icon(Icons.check_circle),
                  label: const Text('TÔI ĐÃ CHUYỂN KHOẢN THÀNH CÔNG', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool copyable = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                if (copyable) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Đã sao chép: $value'),
                        duration: const Duration(seconds: 1),
                      ));
                    },
                    child: const Icon(Icons.copy, size: 16, color: kGold),
                  ),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
}
