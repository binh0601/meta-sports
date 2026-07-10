import 'package:flutter/material.dart';

import '../widgets/stat_card.dart';

/// Muc 11 tai lieu: bang tong ket hoi-dap + 4 cau chot.
class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  static const List<(String, String)> _qa = [
    ('Nhà cái lấy tiền đâu trả người thắng?',
        'Từ túi người thua. Không có quỹ nào khác.'),
    ('Nhà cái ăn bao nhiêu trên 100k?', 'Trung bình 5.000đ (hold 5%).'),
    ('Nhà cái có quan tâm ai thắng không?', 'Không — miễn là sổ cân.'),
    ('Nhà cái có bao giờ lỗ không?',
        'Có, khi sổ lệch. Nên họ làm mọi cách để không lệch.'),
    ('Vì sao mới chơi dễ thắng?',
        'May rủi (95√n) lớn hơn biên (5n) khi n nhỏ.'),
    ('Vì sao chơi lâu mất nhiều?', 'n lớn hơn √n. Luôn luôn.'),
    ('Điểm giao là bao nhiêu ván?', '361 ván.'),
    ('Sau 10 ván bao nhiêu người còn lãi?', '~43%.'),
    ('Sau 1.000 ván?', '~5%.'),
    ('Sau 10.000 ván?', '~0.'),
    ('Gấp thếp có cứu được không?',
        'Không. Từ lần thua thứ 4, thắng vẫn âm.'),
    ('Kelly nói gì?', 'f* = −0.055 → đừng cược.'),
    ('Soi kèo chính xác 100% thì sao?', 'Hòa vốn. Vẫn không lãi.'),
    ('Cược xiên 5 kèo, nhà cái ăn bao nhiêu?', '22,6%.'),
    ('Ở site lậu thì sao?',
        'Tệ hơn nhiều: odds chỉnh riêng, khóa tài khoản thắng, treo lệnh '
            'rút, hủy kèo "lỗi kỹ thuật" — và không có cửa khiếu nại.'),
  ];

  static const List<String> _conclusions = [
    'Nhà cái không đánh bạc với bạn. Họ thu phí trung gian.',
    'Bàn chơi tổng bằng không, và phần của nhà cái luôn dương.',
    'Người chơi không thua vì đen. Họ thua vì cấu trúc.',
    'Cách duy nhất không bị con dốc kéo xuống là không bước lên nó.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Bảng tổng kết')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('Bốn câu chốt'),
          for (var i = 0; i < _conclusions.length; i++)
            Card(
              color: theme.colorScheme.primaryContainer,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  child: Text('${i + 1}',
                      style: const TextStyle(fontSize: 13)),
                ),
                title: Text(
                  _conclusions[i],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          const SectionTitle('Hỏi đáp nhanh'),
          for (final (q, a) in _qa)
            Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(a,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          const NoteBox(
            'Mọi hệ thống đặt cược đều là tổ hợp tuyến tính của các cược có '
            'kỳ vọng âm. Tổng của các số âm vẫn âm. Đây là định lý, '
            'không phải ý kiến.',
            icon: Icons.functions,
          ),
        ],
      ),
    );
  }
}
