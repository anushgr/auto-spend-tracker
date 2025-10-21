import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your backend URL
  // For local testing: 'http://10.0.2.2:8000' (Android emulator)
  // For production: 'https://your-backend.com'
  static const String baseUrl = 'http://10.0.2.2:8000';

  /// Create a new transaction
  static Future<Map<String, dynamic>> createTransaction({
    required String smsText,
    required String userInput,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/transactions/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sms_text': smsText,
          'user_input': userInput,
        }),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Transaction saved successfully!',
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to save transaction: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Fetch all transactions with pagination
  static Future<Map<String, dynamic>> getTransactions({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/transactions/?page=$page&page_size=$pageSize'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'transactions': data['transactions'],
          'total': data['total'],
          'page': data['page'],
          'pageSize': data['page_size'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch transactions: ${response.statusCode}',
          'transactions': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        'transactions': [],
      };
    }
  }
}
