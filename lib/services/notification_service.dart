import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
// ➕ NEW — Allows NotificationService to ping the provider when a push arrives
typedef OnNotificationReceived = void Function();

// Background handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background message received: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // ➕ NEW — Register this callback from AuthProvider/main so badge refreshes on push
  OnNotificationReceived? onNotificationReceived;

  Future<void> init() async {
    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('User declined or has not accepted push notification permission');
      return;
    }

    // 2. Initialize Local Notifications (for foreground)
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _localNotifications.initialize(settings: initSettings);

    // 3. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          message.notification!.title ?? '',
          message.notification!.body ?? '',
        );
        // ➕ NEW — Notify provider to refresh unreadCount & list
        onNotificationReceived?.call();
      }
    });

    // 5. Setup Token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      sendTokenToBackend(newToken);
    });

    // 6. Automatically register token for already logged-in users on app start
    await registerDeviceToken();
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ecommerce_channel', 
      'E-commerce Notifications',
      importance: Importance.max, 
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(id: 0, title: title, body: body, notificationDetails: details);
  }

  // Call this after successful login
  Future<void> registerDeviceToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await sendTokenToBackend(token);
      }
    } catch (e) {
      print("Failed to get FCM token: $e");
    }
  }

  Future<void> sendTokenToBackend(String token) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jwtToken = prefs.getString(ApiConstants.tokenKey); // Use your existing token key
      
      if (jwtToken == null) return; // User not logged in

      final url = Uri.parse('${ApiConstants.baseUrl}/api/v1/tokens/register'); 
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'token': token,
          'deviceType': 'android', // This can be determined dynamically using device_info_plus if needed
        }),
      );

      if (response.statusCode == 201) {
        print("FCM Token successfully registered to backend.");
      } else {
        print("Failed to register FCM token: ${response.body}");
      }
    } catch (e) {
      print('Error sending token to backend: $e');
    }
  }
}
