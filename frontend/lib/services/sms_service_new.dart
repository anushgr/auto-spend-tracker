import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_service.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    // Extract transaction details
    final transactionInfo = _parseTransactionInfo(smsText);

    if (transactionInfo['amount'] != null) {
      // Show notification with inline reply
      await NotificationService.showTransactionNotification(
        smsText: smsText,
        amount: transactionInfo['amount']!,
        transactionType: transactionInfo['type'] ?? 'unknown',
      );
    }
  }

  /// Parse transaction information from SMS
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

  /// Get all SMS messages from a specific sender
  static Future<List<SmsMessage>> getMessagesFromSender(String sender) async {
    final messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      filter: SmsFilter.where(SmsColumn.ADDRESS).equals(sender),
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );
    return messages;
  }

  /// Get all Kotak bank SMS messages
  static Future<List<SmsMessage>> getKotakMessages() async {
    final allMessages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    // Filter for Kotak messages
    return allMessages.where((msg) {
      final sender = msg.address ?? '';
      return _isKotakMessage(sender);
    }).toList();
  }

  /// Process historical Kotak SMS messages
  static Future<void> processHistoricalMessages() async {
    final kotakMessages = await getKotakMessages();
    
    print('Found ${kotakMessages.length} Kotak bank messages');
    
    for (final message in kotakMessages) {
      final body = message.body ?? '';
      
      // Check if this message has already been processed
      final prefs = await SharedPreferences.getInstance();
      final processedKey = 'processed_${message.id}';
      
      if (!prefs.containsKey(processedKey)) {
        // Process and save to backend
        await ApiService.createTransaction(
          smsText: body,
          userInput: 'unknown, unknown',
        );
        
        // Mark as processed
        await prefs.setBool(processedKey, true);
      }
    }
  }
}
