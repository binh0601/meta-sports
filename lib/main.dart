import 'package:flutter/material.dart';

import 'logic/auth_state.dart';
import 'screens/login_screen.dart';
import 'screens/player_home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/firebase_bootstrap.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase(); // an toan khi thieu google-services.json
  await NotificationService.instance.init();
  // Firebase nho phien dang nhap -> mo app vao thang san keo
  final restored = authState.tryRestoreSession();
  runApp(HouseEdgeApp(startLoggedIn: restored));
}

/// Demo giao duc: "Toan hoc nha cai" duoi vo boc app ca cuoc that.
/// 2 role: nguoi choi (Firebase Auth) va admin nha cai (dang nhap cung).
class HouseEdgeApp extends StatelessWidget {
  final bool startLoggedIn;
  final bool showSplash;
  const HouseEdgeApp(
      {super.key, this.startLoggedIn = false, this.showSplash = true});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mega Sports',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'ChakraPetch',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6), // xanh royal kieu app the thao
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        cardTheme: const CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
        // Chuyen man truot ngang + mo dan (Material 3 motion)
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        }),
      ),
      home: showSplash
          ? SplashScreen(
              next: startLoggedIn
                  ? const PlayerHomeScreen()
                  : const LoginScreen())
          : startLoggedIn
              ? const PlayerHomeScreen()
              : const LoginScreen(),
    );
  }
}
