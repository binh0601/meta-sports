import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/screens/live_score_screen.dart';

void main() {
  testWidgets('LiveScoreScreen hien danh sach tran truc tiep va huy Timer khi pop',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LiveScoreScreen())),
                child: const Text('mo'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('mo'));
    await tester.pump(); // bat dau push
    await tester.pump(const Duration(milliseconds: 50));

    // Danh sach tran (khong con du lieu demo Viet Nam - Thai Lan co dinh)
    expect(find.textContaining('Dynamo Kyiv'), findsWidgets);
    expect(find.textContaining('trận đang trực tiếp'), findsOneWidget);
    expect(find.text('Xem trực tiếp'), findsWidgets);

    // pop truoc khi Timer.periodic (2.5s) kip chay -> dispose huy Timer
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });
}
