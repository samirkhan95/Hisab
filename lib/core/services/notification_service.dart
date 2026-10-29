import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotificationsPlugin.initialize(initSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        _localNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon,
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker',
              playSound: true,
            ),
          ),
        );
      }
    });

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message);
    });

    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage);
    }

    _setupTokenSync();
  }

  static void _handleNotificationClick(RemoteMessage message) {
    debugPrint("Notification clicked: ${message.data}");
  }

  static Future<void> _setupTokenSync() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    auth.authStateChanges().listen((user) async {
      if (user != null) {
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await firestore.collection('users').doc(user.uid).set({
            'fcm_token': token,
            'last_active': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = auth.currentUser;
      if (user != null) {
        await firestore.collection('users').doc(user.uid).set({
          'fcm_token': newToken,
        }, SetOptions(merge: true));
      }
    });
  }

  // --- NEW: DIRECT SEND LOGIC (NO BLAZE PLAN REQUIRED) ---

  static Future<String> _getAccessToken() async {
    final String response = await rootBundle.loadString('service-account.json');
    final data = json.decode(response);

    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(data),
      ['https://www.googleapis.com/auth/cloud-platform'],
    );

    return client.credentials.accessToken.data;
  }

  static Future<void> sendPushNotification({
    required String recipientUid,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // 1. Get the recipient's token from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(recipientUid).get();
      final String? token = userDoc.data()?['fcm_token'];

      if (token == null) {
        debugPrint('Cannot send push: No token found for user $recipientUid');
        return;
      }

      // 2. Get Access Token
      final accessToken = await _getAccessToken();
      
      // 3. Get Project ID from service-account.json
      final String saStr = await rootBundle.loadString('service-account.json');
      final saData = json.decode(saStr);
      final String projectId = saData['project_id'];

      // 4. Construct the V1 API request
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'message': {
            'token': token,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': data ?? {},
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'high_importance_channel',
                'priority': 'max',
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              },
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Push notification sent successfully');
      } else {
        debugPrint('Failed to send push: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending push: $e');
    }
  }
}
