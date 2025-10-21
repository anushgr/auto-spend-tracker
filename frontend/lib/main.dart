import 'package:flutter/material.dart';
import 'services/sms_service.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  await SmsService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Spend Tracker',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _transactions = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalTransactions = 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _checkPendingNotifications();
  }

  /// Check for pending notification responses
  Future<void> _checkPendingNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if notification was tapped
    final notificationTapped = prefs.getBool('notification_tapped') ?? false;
    
    if (notificationTapped) {
      final pendingSms = prefs.getString('pending_sms');
      
      if (pendingSms != null) {
        // Clear the flag
        await prefs.setBool('notification_tapped', false);
        
        // Wait a bit for the UI to render, then show the dialog
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _showManualEntryDialogWithSms(pendingSms);
        }
      }
    }
    
    // Legacy check for old processing method
    final isPending = prefs.getString('pending_processing');
    if (isPending == 'true') {
      final smsText = prefs.getString('pending_sms');
      final userInput = prefs.getString('user_input');

      if (smsText != null && userInput != null) {
        // Process the transaction
        await SmsService.processUserInput(smsText, userInput);

        // Clear pending flags
        await prefs.remove('pending_processing');
        await prefs.remove('pending_sms');
        await prefs.remove('user_input');

        // Reload transactions
        _loadTransactions();
      }
    }
  }

  /// Load transactions from backend
  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    final result = await ApiService.getTransactions(page: _currentPage);

    if (result['success']) {
      setState(() {
        _transactions = result['transactions'] ?? [];
        _totalTransactions = result['total'] ?? 0;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to load data')),
        );
      }
    }
  }

  /// Format transaction type
  String _formatType(String type) {
    return type == 'sent' ? '💸 Sent' : '💰 Received';
  }

  /// Get color based on transaction type
  Color _getTypeColor(String type) {
    return type == 'sent' ? Colors.red : Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Spend Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? _buildEmptyState()
              : _buildTransactionList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showManualEntryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Manual'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Transactions will appear here when you\nreceive bank SMS and add details',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Total Transactions: $_totalTransactions',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              final tx = _transactions[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getTypeColor(tx['transaction_type']),
                    child: Text(
                      tx['transaction_type'] == 'sent' ? '−' : '+',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tx['applicable_to'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '₹${tx['amount']?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _getTypeColor(tx['transaction_type']),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx['reason'] ?? 'No reason'),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatType(tx['transaction_type'])} • ${tx['date'] ?? ''}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Date', tx['date'] ?? '-'),
                          _buildDetailRow('Time', tx['time'] ?? '-'),
                          _buildDetailRow('Type', tx['transaction_type'] ?? '-'),
                          _buildDetailRow('UPI/Account',
                              tx['sender_receiver_info'] ?? '-'),
                          _buildDetailRow(
                              'Full Input', tx['full_text'] ?? '-'),
                          const Divider(),
                          Text(
                            'SMS Message:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tx['sms_text'] ?? '-',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  /// Show manual entry dialog for testing
  void _showManualEntryDialog() {
    _showManualEntryDialogWithSms(
      'Sent Rs.236.00 from Kotak Bank AC X0396 to vyapar.172400950852@hdfcbank on 05-07-25.UPI Ref 555256646612.',
    );
  }

  /// Show manual entry dialog with pre-filled SMS
  void _showManualEntryDialogWithSms(String smsText) {
    final smsController = TextEditingController(text: smsText);
    final inputController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Transaction Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: smsController,
                decoration: const InputDecoration(
                  labelText: 'SMS Text',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: inputController,
                decoration: const InputDecoration(
                  labelText: 'User Input (person, reason)',
                  hintText: 'mom, apples',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await SmsService.processUserInput(
                smsController.text,
                inputController.text,
              );
              _loadTransactions();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
