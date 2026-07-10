import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../logic/betting_math.dart';
import 'firebase_bootstrap.dart';

/// Thong bao he thong that:
/// - Trung thuong -> local notification hien ngay (khong can server)
/// - FCM: nhan push gui tu Firebase Console (ca foreground lan nen)
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Token thiet bi de dan vao Firebase Console khi test push
  /// (admin dashboard hien thi gia tri nay).
  final ValueNotifier<String?> fcmToken = ValueNotifier(null);

  bool _ready = false;

  Future<void> init() async {
    try {
      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await _local.initialize(
          settings: const InitializationSettings(android: androidInit));
      // Android 13+ phai xin quyen hien thong bao
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('Local notification init loi: $e');
    }

    if (!firebaseReady) return;
    try {
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission();
      fcmToken.value = await fm.getToken();
      debugPrint('FCM token: ${fcmToken.value}');
      // App dang mo: FCM khong tu hien -> chuyen thanh local notification
      FirebaseMessaging.onMessage.listen((RemoteMessage m) {
        final n = m.notification;
        if (n != null) show(n.title ?? 'Mega Sports', n.body ?? '');
      });
    } catch (e) {
      debugPrint('FCM init loi: $e');
    }
  }

  Future<void> show(String title, String body) async {
    if (!_ready) return;
    await _local.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'win_channel',
          'Thông báo trúng thưởng',
          channelDescription: 'Báo khi phiếu cược thắng',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  /// Goi sau khi da vong: co phieu trung thi ban notification tong ket.
  void notifyRoundResult(
      {required int wonCount, required double wonNet, required double balance}) {
    if (wonCount <= 0) return;
    show(
      '🎉 Trúng $wonCount phiếu!',
      'Bạn thắng ${fmtK(wonNet)} — số dư hiện tại ${fmtMoney(balance)}.',
    );
  }
}
