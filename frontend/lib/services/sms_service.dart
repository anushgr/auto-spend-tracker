import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_service.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Background message handler - MUST be a top-level function
@pragma('vm:entry-point')
void backgroundMessageHandler(SmsMessage message) {
  final sender = message.address ?? '';
  final body = message.body ?? '';

  print('Background SMS received from: $sender');
  
  // Check if it's from Kotak bank
  if (_isKotakMessageStatic(sender)) {
    print('Kotak bank SMS detected in background!');
    _processKotakSmsStatic(body);
  }
}

// Static helper functions for background handler
bool _isKotakMessageStatic(String sender) {
  final senderLower = sender.toLowerCase();
  return senderLower.contains('kotak') ||
      senderLower.startsWith('ax-kotak') ||
      senderLower.startsWith('vm-kotak');
}

void _processKotakSmsStatic(String smsText) {
  // Extract transaction details
  final transactionInfo = _parseTransactionInfoStatic(smsText);
  
  if (transactionInfo['amount'] != null) {
    // Show notification with inline reply
    NotificationService.showTransactionNotification(
      smsText: smsText,
      amount: transactionInfo['amount']!,
      transactionType: transactionInfo['type'] ?? 'unknown',
    );
  }
}

Map<String, dynamic> _parseTransactionInfoStatic(String smsText) {
  double? amount;
  String type = 'unknown';

  // Extract amount (Rs.XXX.XX or Rs.XXX)
  final amountRegex = RegExp(r'Rs\.?(\d+(?:,\d+)*(?:\.\d+)?)', caseSensitive: false);
  final amountMatch = amountRegex.firstMatch(smsText);
  if (amountMatch != null) {
    final amountStr = amountMatch.group(1)?.replaceAll(',', '');
    amount = double.tryParse(amountStr ?? '0');
  }

  // Determine transaction type
  if (RegExp(r'\b(sent|debited|paid)\b', caseSensitive: false).hasMatch(smsText)) {
    type = 'sent';
  } else if (RegExp(r'\b(received|credited|deposited)\b', caseSensitive: false)
      .hasMatch(smsText)) {
    type = 'received';
  }

  return {
    'amount': amount,
    'type': type,
  };
}

class SmsService {
  static final Telephony telephony = Telephony.instance;

  /// Request SMS permissions
  static Future<bool> requestPermissions() async {
    final smsStatus = await Permission.sms.request();
    final phoneStatus = await Permission.phone.request();
    
    return smsStatus.isGranted && phoneStatus.isGranted;
  }

  /// Initialize SMS listener
  static Future<void> initialize() async {
    // Request permissions first
    final hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      print('SMS permissions not granted');
      return;
    }

    // Listen to incoming SMS (foreground only to avoid background handler crash)
    telephony.listenIncomingSms(
      onNewMessage: onMessageReceived,
      listenInBackground: false,
    );

    print('SMS listener initialized (foreground only)');
  }

  /// Handle incoming SMS
  static void onMessageReceived(SmsMessage message) {
    final sender = message.address ?? '';
    final body = message.body ?? '';

    print('SMS received from: $sender');
    print('Message: $body');

    // Check if it's from Kotak bank
    if (_isKotakMessage(sender)) {
      print('Kotak bank SMS detected!');
      _processKotakSms(body);
    }
  }

  /// Check if the SMS is from Kotak bank
  static bool _isKotakMessage(String sender) {
    final senderLower = sender.toLowerCase();
    return senderLower.contains('kotak') ||
        senderLower.startsWith('ax-kotak') ||
        senderLower.startsWith('vm-kotak');
  }

  /// Process Kotak bank SMS
  static Future<void> _processKotakSms(String smsText) async {
    try {
      print('Processing Kotak SMS...');
      
      // Extract transaction details
      final transactionInfo = _parseTransactionInfo(smsText);
      
      print('Transaction info: $transactionInfo');

      if (transactionInfo['amount'] != null) {
        print('Calling showTransactionNotification with amount: ${transactionInfo['amount']}, type: ${transactionInfo['type']}');
        
        // Show notification with inline reply
        await NotificationService.showTransactionNotification(
          smsText: smsText,
          amount: transactionInfo['amount']!,
          transactionType: transactionInfo['type'] ?? 'unknown',
        );
        
        print('Notification call completed');

        // Store SMS for processing when user responds
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_sms', smsText);
      } else {
        print('No amount found in SMS');
      }
    } catch (e) {
      print('Error processing Kotak SMS: $e');
    }
  }

  /// Parse transaction info from SMS
  static Map<String, dynamic> _parseTransactionInfo(String smsText) {
    double? amount;
    String type = 'unknown';

    // Extract amount (Rs.XXX.XX or Rs.XXX)
    final amountRegex = RegExp(r'Rs\.?(\d+(?:,\d+)*(?:\.\d+)?)', caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(smsText);
    if (amountMatch != null) {
      final amountStr = amountMatch.group(1)?.replaceAll(',', '');
      amount = double.tryParse(amountStr ?? '0');
    }

    // Determine transaction type
    if (RegExp(r'\b(sent|debited|paid)\b', caseSensitive: false).hasMatch(smsText)) {
      type = 'sent';
    } else if (RegExp(r'\b(received|credited|deposited)\b', caseSensitive: false)
        .hasMatch(smsText)) {
      type = 'received';
    }

    return {
      'amount': amount,
      'type': type,
    };
  }

  /// Process user input from notification and send to backend
  static Future<void> processUserInput(String smsText, String userInput) async {
    final result = await ApiService.createTransaction(
      smsText: smsText,
      userInput: userInput,
    );

    // Show result notification
    await NotificationService.showResultNotification(
      success: result['success'] ?? false,
      message: result['message'] ?? 'Unknown error',
    );
  }
}
