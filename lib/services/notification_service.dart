import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    const channel = AndroidNotificationChannel(
      'alovu_channel',
      'ALOVU Notifications',
      description: 'Thông báo của ứng dụng',
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> show({required String title, required String body}) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'alovu_channel',
        'ALOVU Notifications',
        channelDescription: 'Thông báo của ứng dụng',
        importance: Importance.max,
        priority: Priority.high,
      );

      const details = NotificationDetails(android: androidDetails);

      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('LỖI LOCAL NOTIFICATION: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> notificationStream() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      debugPrint('USER NULL - KHÔNG ĐỌC ĐƯỢC THÔNG BÁO');
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> add({
    required String title,
    required String body,
    required String type,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      debugPrint('USER NULL - CHƯA ĐĂNG NHẬP NÊN KHÔNG TẠO THÔNG BÁO');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .add({
            'title': title,
            'body': body,
            'type': type,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

      debugPrint('ĐÃ TẠO THÔNG BÁO FIRESTORE THÀNH CÔNG');

      await show(title: title, body: body);
    } catch (e) {
      debugPrint('LỖI TẠO THÔNG BÁO: $e');
    }
  }

  Future<void> markAsRead(String docId) async {
    final currentUser = _user;
    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead() async {
    final currentUser = _user;
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('notifications')
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  Future<void> deleteNotification(String docId) async {
    final currentUser = _user;
    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('notifications')
        .doc(docId)
        .delete();
  }

  Future<void> clearAll() async {
    final currentUser = _user;
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('notifications')
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> notifyFavorite({
    required String fieldName,
    required bool added,
  }) async {
    await add(
      title: added ? 'Đã thêm yêu thích' : 'Đã bỏ yêu thích',
      body: fieldName,
      type: 'favorite',
    );
  }

  Future<void> notifyBooking({
    required String fieldName,
    required String courtName,
    required String time,
  }) async {
    await add(
      title: 'Đặt sân thành công',
      body: '$fieldName - $courtName lúc $time',
      type: 'booking',
    );
  }

  Future<void> scheduleBookingReminder({
    required String fieldName,
    required String courtName,
    required String bookingTime,
  }) async {
    try {
      final now = DateTime.now();

      final parts = bookingTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      DateTime bookingDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (bookingDateTime.isBefore(now)) {
        bookingDateTime = bookingDateTime.add(const Duration(days: 1));
      }

      final reminderTime = bookingDateTime.subtract(const Duration(hours: 1));

      if (reminderTime.isBefore(now)) {
        debugPrint('GIỜ NHẮC ĐÃ QUA - KHÔNG HẸN NHẮC');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'alovu_channel',
        'ALOVU Notifications',
        channelDescription: 'Thông báo của ứng dụng',
        importance: Importance.max,
        priority: Priority.high,
      );

      const details = NotificationDetails(android: androidDetails);

      await _plugin.zonedSchedule(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'Nhắc lịch đặt sân',
        'Bạn có lịch tại $fieldName - $courtName lúc $bookingTime',
        tz.TZDateTime.from(reminderTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('ĐÃ HẸN GIỜ NHẮC LỊCH');
    } catch (e) {
      debugPrint('LỖI NHẮC LỊCH: $e');
    }
  }

  Future<void> notifyChat(String message) async {
    await add(title: 'Tin nhắn mới', body: message, type: 'chat');
  }

  Future<void> notifyReminder(String text) async {
    await add(title: 'Nhắc lịch', body: text, type: 'reminder');
  }
}
