import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/api_service.dart'; // Make sure this path is correct

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({Key? key}) : super(key: key);

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _fetchAllTransactions();
  }

  Future<void> _fetchAllTransactions() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    try {
      List<Map<String, dynamic>> transactions = [];

      // Get all income
      final incomeSnapshot = await FirebaseFirestore.instance
          .collection('users').doc(ApiService.currentUserId).collection('income')
          .orderBy('date', descending: true).get();

      transactions.addAll(incomeSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'type': 'income', 'amount': (data['amount'] as num).toDouble(),
          'category': data['category'] ?? 'Income',
          'description': data['reason'] ?? 'N/A',
          'date': (data['date'] as Timestamp).toDate(),
          'icon': Icons.arrow_upward,
        };
      }));

      // Get all expenses
      final expenseSnapshot = await FirebaseFirestore.instance
          .collection('users').doc(ApiService.currentUserId).collection('expenses')
          .orderBy('date', descending: true).get();

      transactions.addAll(expenseSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'type': 'expense', 'amount': (data['amount'] as num).toDouble(),
          'category': data['category'] ?? 'Expense',
          'description': data['reason'] ?? 'N/A',
          'date': (data['date'] as Timestamp).toDate(),
          'icon': Icons.arrow_downward,
        };
      }));

      // Sort the combined list by date
      transactions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      if(mounted) {
        setState(() {
          _allTransactions = transactions;
        });
      }
    } catch (e) {
      print('Error fetching all transactions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load transactions: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allTransactions.isEmpty
          ? const Center(
        child: Text(
          'No transactions found.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: _allTransactions.length,
        separatorBuilder: (context, index) => const Divider(height: 24),
        itemBuilder: (context, index) {
          final transaction = _allTransactions[index];
          return _buildTransactionItem(transaction);
        },
      ),
    );
  }

  // Helper widget to display a single transaction item (reused from view_finances_screen)
  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isIncome = transaction['type'] == 'income';
    final color = isIncome ? const Color(0xFF4CAF50) : const Color(0xFFf44336);
    final sign = isIncome ? '+' : '-';
    final date = transaction['date'] as DateTime;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(transaction['icon'], color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(transaction['description'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text('${transaction['category']} • ${DateFormat.yMd().format(date)}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
        ),
        Text(
          '$sign${NumberFormat.simpleCurrency(locale: 'en_US').format(transaction['amount'])}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
