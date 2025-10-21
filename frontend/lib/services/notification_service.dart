import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'sms_transaction_channel';
  static const String channelName = 'Transaction Notifications';
  static const String channelDescription =
      'Notifications for bank SMS transactions';

  /// Initialize notification service
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Show notification with inline reply for transaction details
  static Future<void> showTransactionNotification({
    required String smsText,
    required double amount,
    required String transactionType,
  }) async {
    try {
      print('Creating notification for transaction: $amount, type: $transactionType');
      
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Store SMS text and notification ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_sms_$notificationId', smsText);
      print('Stored pending SMS with ID: $notificationId');
      
      // Set a timer to auto-send as "unknown" after 5 minutes if not responded
      Future.delayed(const Duration(minutes: 5), () async {
        final stillPending = prefs.getString('pending_sms_$notificationId');
        if (stillPending != null) {
          print('Timeout: Sending as unknown');
          await _sendToBackend(smsText, 'unknown, unknown');
          await prefs.remove('pending_sms_$notificationId');
        }
      });

      final String title = transactionType == 'sent'
          ? '💸 Money Sent - ₹$amount'
          : '💰 Money Received - ₹$amount';
      
      print('Notification title: $title');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Transaction detected',
      autoCancel: false,
      ongoing: false,
      styleInformation: BigTextStyleInformation(
        'Type who and why, or tap "Save as Unknown"',
      ),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'reply_action',
          'Reply',
          inputs: <AndroidNotificationActionInput>[
            AndroidNotificationActionInput(
              label: 'person, reason',
            ),
          ],
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'dismiss_action',
          'Save as Unknown',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      notificationId,
      title,
      'Type details below or swipe away to save as "unknown"',
      notificationDetails,
      payload: notificationId.toString(),
    );
    
    print('Notification shown successfully with ID: $notificationId');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  /// Show result notification (success/error)
  static Future<void> showResultNotification({
    required bool success,
    required String message,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      success ? '✅ Transaction Saved' : '❌ Error',
      message,
      notificationDetails,
    );
  }

  /// Handle notification response (tap or inline reply)
  static void _onNotificationTapped(NotificationResponse response) async {
    print('Notification response received');
    print('Action ID: ${response.actionId}');
    print('User input: ${response.input}');
    print('Payload: ${response.payload}');
    
    final notificationId = response.payload ?? '';
    
    if (notificationId.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final smsText = prefs.getString('pending_sms_$notificationId');
    
    if (smsText == null) return;
    
    String finalInput = 'unknown, unknown';
    
    if (response.actionId == 'reply_action') {
      // User clicked "Add Details" button
      final userInput = response.input ?? '';
      finalInput = userInput.trim().isEmpty ? 'unknown, unknown' : userInput.trim();
      print('User provided input: $finalInput');
    } else if (response.actionId == 'dismiss_action') {
      // User clicked "Save as Unknown" button
      print('User explicitly dismissed');
      finalInput = 'unknown, unknown';
    } else {
      // User just tapped the notification (not an action button)
      // Don't save yet - wait for action or timeout
      print('Notification tapped but no action taken');
      return;
    }
    
    print('Sending with input: $finalInput');
    await _sendToBackend(smsText, finalInput);
    
    // Clear pending data
    await prefs.remove('pending_sms_$notificationId');
  }

  /// Send transaction to backend
  static Future<void> _sendToBackend(String smsText, String userInput) async {
    try {
      print('Sending to backend: SMS=$smsText, Input=$userInput');
      
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/transactions/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sms_text': smsText,
          'user_input': userInput,
        }),
      );

      print('Backend response: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        await showResultNotification(
          success: true,
          message: 'Transaction saved successfully!',
        );
      } else {
        await showResultNotification(
          success: false,
          message: 'Failed to save transaction',
        );
      }
    } catch (e) {
      print('Error sending to backend: $e');
      await showResultNotification(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }
}
