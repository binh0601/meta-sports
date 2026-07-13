import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:house_edge_demo/logic/auth_state.dart';
import 'package:house_edge_demo/logic/football_market.dart';
import 'package:house_edge_demo/logic/game_state.dart';
import 'package:house_edge_demo/logic/handicap_settlement.dart';
import 'package:house_edge_demo/main.dart';
import 'package:house_edge_demo/widgets/bet_slip_panel.dart';
import 'package:house_edge_demo/widgets/match_card.dart'
    show MatchCard, OddsSelectButton;

void main() {
  tearDown(() async => authState.logout());

  testWidgets('Man hinh dang nhap: du email/Google/dang ky', (tester) async {
    await tester.pumpWidget(const HouseEdgeApp(showSplash: false));
    expect(find.text('MEGA SPORTS'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
    expect(find.text('Tiếp tục với Google'), findsOneWidget);
    expect(find.textContaining('Đăng ký ngay'), findsOneWidget);
  });

  testWidgets('admin/123456 -> vao dashboard nha cai (bypass Firebase)',
      (tester) async {
    await tester.pumpWidget(const HouseEdgeApp(showSplash: false));
    await tester.enterText(find.byType(TextField).at(0), 'admin');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('ĐĂNG NHẬP'));
    await tester.pumpAndSettle();
    expect(find.text('Bảng điều khiển Nhà cái'), findsOneWidget);
    expect(authState.role, UserRole.admin);
  });

  testWidgets('admin sai mat khau -> bao loi', (tester) async {
    await tester.pumpWidget(const HouseEdgeApp(showSplash: false));
    await tester.enterText(find.byType(TextField).at(0), 'admin');
    await tester.enterText(find.byType(TextField).at(1), 'sai-roi');
    await tester.tap(find.text('ĐĂNG NHẬP'));
    await tester.pumpAndSettle();
    expect(find.text('Sai mật khẩu admin.'), findsOneWidget);
    expect(authState.isLoggedIn, false);
  });

  testWidgets('email login khi Firebase chua cau hinh -> bao loi ro rang',
      (tester) async {
    await tester.pumpWidget(const HouseEdgeApp(showSplash: false));
    await tester.enterText(
        find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('ĐĂNG NHẬP'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Firebase chưa được cấu hình'), findsOneWidget);
    expect(authState.isLoggedIn, false);
  });

  testWidgets('link dang ky mo man Register', (tester) async {
    await tester.pumpWidget(const HouseEdgeApp(showSplash: false));
    await tester.tap(find.textContaining('Đăng ký ngay'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo tài khoản người chơi'), findsOneWidget);
    expect(find.text('ĐĂNG KÝ'), findsOneWidget);
  });

  testWidgets('demo/123456 -> vao sanh nguoi choi voi vi 10 trieu',
      (tester) async {
    await tester.pumpWidget(const HouseEdgeApp(showSplash: false));
    await tester.enterText(find.byType(TextField).at(0), 'demo');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('ĐĂNG NHẬP'));
    // San keo co SpinningBallIcon quay vo han -> pumpAndSettle khong bao gio
    // dung; pump theo thoi luong co dinh de qua het chuyen man + entrance.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('MEGA SPORTS'), findsOneWidget); // san keo
    expect(authState.role, UserRole.player);
    expect(authState.isDemo, true);
    expect(gameState.balance, GameState.demoBalance);
  });

  testWidgets('demo sai mat khau -> bao loi', (tester) async {
    await tester.pumpWidget(const HouseEdgeApp(showSplash: false));
    await tester.enterText(find.byType(TextField).at(0), 'demo');
    await tester.enterText(find.byType(TextField).at(1), 'sai');
    await tester.tap(find.text('ĐĂNG NHẬP'));
    await tester.pumpAndSettle();
    expect(find.text('Sai mật khẩu demo.'), findsOneWidget);
    expect(authState.isLoggedIn, false);
  });

  testWidgets('tai khoan demo khong thay nut Nap/Rut o tab Toi',
      (tester) async {
    await tester.pumpWidget(const HouseEdgeApp(showSplash: false));
    await tester.enterText(find.byType(TextField).at(0), 'demo');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('ĐĂNG NHẬP'));
    // San keo co SpinningBallIcon quay vo han -> pumpAndSettle khong bao gio
    // dung; pump theo thoi luong co dinh de qua het chuyen man + entrance.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Tôi'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Nạp / Rút tiền'), findsNothing);
    expect(find.text('Chơi lại từ đầu'), findsOneWidget);
  });

  testWidgets('splash hien logo roi tu vao man dang nhap', (tester) async {
    await tester.pumpWidget(const HouseEdgeApp());
    expect(find.text('MEGA SPORTS'), findsOneWidget); // splash logo
    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget); // sang login
  });

  testWidgets('doi giai sang World Cup doi label va doi bong', (tester) async {
    await tester.pumpWidget(const HouseEdgeApp(showSplash: false));
    await tester.enterText(find.byType(TextField).at(0), 'demo');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('ĐĂNG NHẬP'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('WORLD CUP 2026').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(gameState.league, League.worldCup);
    // gameState la global — tra ve giai cu de khong anh huong test sau.
    gameState.switchLeague(League.asianCup);
  });

  testWidgets('chon cua chap trong chi tiet tran -> vao phieu market handicap',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HouseEdgeApp(showSplash: false));
    await tester.enterText(find.byType(TextField).at(0), 'demo');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('ĐĂNG NHẬP'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // Keo chap gio nam trong trang chi tiet tran -> mo chi tiet truoc
    await tester.tap(find.byType(MatchCard).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final hdpButton = find.byWidgetPredicate((w) =>
        w is OddsSelectButton &&
        w.market == MarketType.handicap &&
        w.onHome == true);
    expect(hdpButton, findsWidgets);
    await tester.tap(hdpButton.first);
    await tester.pump();
    expect(gameState.slip.any((s) => s.market == MarketType.handicap), true);
    // gameState la global — don phieu de khong anh huong test sau.
    gameState.slip.clear();
  });

  testWidgets('nhan ket qua xien 2 chan (1 thang 1 thua) hien "Mất" khong "Ăn đủ"',
      (tester) async {
    // Xien 1x2: chan 0 THANG (status win) nhung chan 1 THUA -> ca phieu thua
    // (won=false, payout 0). Nhan phai theo ket qua toan phieu, khong theo
    // status cua chan dau tien.
    final g = gameState;
    final parlay = BetSlip.restored(
      legResults: const [
        LegResult('A', 1.9, true, payoutRatio: 1.9, status: SettleStatus.win),
        LegResult('B', 1.9, false, status: SettleStatus.lose),
      ],
      stake: 100,
      round: 1,
      won: false,
      payout: 0,
    );
    g.roundPlayed = true;
    g.lastResults = [parlay];
    addTearDown(() {
      g.roundPlayed = false;
      g.lastResults = [];
    });

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Align(child: BetSlipPanel())),
    ));
    await tester.pump();
    expect(find.text('Mất'), findsOneWidget);
    expect(find.text('Ăn đủ'), findsNothing);
  });

  testWidgets('tim keo: go cau hoi loc dung ten doi, xoa loc tra ve du tran',
      (tester) async {
    // ListView chi build cac MatchCard nam trong viewport/cache extent ->
    // can man hinh cao de ca 8 tran deu duoc render (tuong tu test
    // "chon cua chap" o tren).
    await tester.binding.setSurfaceSize(const Size(800, 2600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HouseEdgeApp(showSplash: false));
    await tester.enterText(find.byType(TextField).at(0), 'demo');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('ĐĂNG NHẬP'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final totalBefore = find.byType(MatchCard).evaluate().length;
    expect(totalBefore, 8);

    // BetFinderBar la TextField duy nhat tren man san keo (2 TextField dang
    // nhap da bi thay the sau khi dang nhap thanh cong).
    // Dung ten doi cu the (Viet Nam luon co dung 1 tran/vong, du doi thu
    // duoc boc tham ngau nhien) de dam bao loc con dung 1 tran, thay vi
    // loc "cua nha" don thuan — sideHome mot minh luon dung tren canh nha
    // cua MOI tran (khong co odds di kem) nen khong the tu giam so tran
    // hien thi (da duoc BetQueryFilter.matchesSide xac nhan trong
    // bet_query_filter_test.dart).
    await tester.enterText(find.byType(TextField), 'kèo Việt Nam');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Xoá lọc'), findsOneWidget);
    final totalAfterFilter = find.byType(MatchCard).evaluate().length;
    expect(totalAfterFilter, lessThan(totalBefore));

    await tester.tap(find.text('Xoá lọc'));
    await tester.pump();
    expect(find.byType(MatchCard).evaluate().length, totalBefore);
    // MatchCard moi (danh sach vua doi) tu boc EntranceSlide, tao Future.delayed
    // (toi da 12*40ms) cho hieu ung vao man so le — pump het de khong con
    // timer treo khi ket thuc test.
    await tester.pump(const Duration(milliseconds: 500));
  });
}
