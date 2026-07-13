import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/screens/live_score_screen.dart';

void main() {
  testWidgets('LiveScoreScreen hien tran demo va huy Timer khi pop',
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
    await tester.pump(const Duration(milliseconds: 50)); // cho fetchLive()

    expect(find.textContaining('Việt Nam'), findsWidgets);
    expect(find.textContaining('Thái Lan'), findsWidgets);
    expect(find.textContaining('Chỉ xem'), findsOneWidget);

    // pop truoc khi Timer.periodic (4s) kip chay lan tick dau -> dispose huy Timer
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });
}
