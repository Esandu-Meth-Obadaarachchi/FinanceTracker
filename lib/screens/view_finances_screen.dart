import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/api_service.dart'; // Make sure this import path is correct
import 'all_transactions_screen.dart';
class ViewFinancesScreen extends StatefulWidget {
  const ViewFinancesScreen({Key? key}) : super(key: key);

  @override
  State<ViewFinancesScreen> createState() => _ViewFinancesScreenState();
}

class _ViewFinancesScreenState extends State<ViewFinancesScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  // State variables to hold fetched data
  Map<String, double> _monthlyTotals = {
    'totalIncome': 0.0,
    'totalExpenses': 0.0,
    'netIncome': 0.0,
  };
  double _pendingTotal = 0.0;
  List<Map<String, dynamic>> _recentTransactions = [];
  Map<String, double> _categorySpending = {};

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  // Main function to fetch all data for the selected month
  Future<void> _loadFinancialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch totals, recent transactions, and category data concurrently
      await Future.wait([
        _fetchMonthlyTotals(),
        _fetchPendingTotal(),
        _fetchRecentTransactions(),
        _fetchCategorySpending(),
      ]);
    } catch (e) {
      print('Error loading financial data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 1. Fetches Income, Expenses, and Net totals for the month
  Future<void> _fetchMonthlyTotals() async {
    final totals = await ApiService.getMonthlyTotals(_selectedDate);
    if (mounted) {
      setState(() {
        _monthlyTotals = totals;
      });
    }
  }

  // 2. Fetches the total pending income for the month
  Future<void> _fetchPendingTotal() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(ApiService.currentUserId)
        .collection('pendingIncome')
        .where('status', isEqualTo: 'pending') // Now gets ALL pending items
        .get();

    double total = 0.0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['amount'] as num).toDouble();
    }

    if (mounted) {
      setState(() {
        _pendingTotal = total;
      });
    }
  }

  // 3. Fetches the 5 most recent transactions (income and expense)
  Future<void> _fetchRecentTransactions() async {
    List<Map<String, dynamic>> transactions = [];

    // Get recent income
    final incomeSnapshot = await FirebaseFirestore.instance
        .collection('users').doc(ApiService.currentUserId).collection('income')
        .orderBy('date', descending: true).limit(5).get();

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

    // Get recent expenses
    final expenseSnapshot = await FirebaseFirestore.instance
        .collection('users').doc(ApiService.currentUserId).collection('expenses')
        .orderBy('date', descending: true).limit(5).get();

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

    // Sort combined list by date and take the top 5
    transactions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    if(mounted) {
      setState(() {
        _recentTransactions = transactions.take(5).toList();
      });
    }
  }

  // 4. Fetches all expenses for the month and groups them by category
  Future<void> _fetchCategorySpending() async {
    final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);

    final snapshot = await FirebaseFirestore.instance
        .collection('users').doc(ApiService.currentUserId).collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    final Map<String, double> spending = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final category = data['category'] as String? ?? 'Uncategorized';
      final amount = (data['amount'] as num).toDouble();
      spending.update(category, (value) => value + amount, ifAbsent: () => amount);
    }

    if (mounted) {
      setState(() {
        _categorySpending = spending;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic calculations
    final double totalIncome = _monthlyTotals['totalIncome'] ?? 0.0;
    final double totalExpenses = _monthlyTotals['totalExpenses'] ?? 0.0;
    final double balance = totalIncome - totalExpenses;
    final double savingsRate = totalIncome > 0 ? (balance / totalIncome) * 100 : 0.0;
    final int daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final double avgDailySpend = totalExpenses > 0 ? totalExpenses / daysInMonth : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Finances', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFinancialData,
          ),
        ],
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
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Selector
            _buildMonthSelectorCard(),
            const SizedBox(height: 24),

            // Summary Cards
            _buildSummaryCards(totalIncome, totalExpenses, balance),
            const SizedBox(height: 32),

            // Spending by Category
            const Text('Spending Breakdown', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 16),
            _buildCategorySpendingCard(totalExpenses),
            const SizedBox(height: 32),

            // Recent Transactions
            _buildRecentTransactionsSection(),
            const SizedBox(height: 32),

            // Statistics Cards
            const Text('Monthly Statistics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 16),
            _buildStatisticsCards(savingsRate, avgDailySpend),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildMonthSelectorCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        // ... (This widget's content is mostly static and doesn't need much change)
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)]),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.analytics, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            const Text('Financial Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: _selectMonth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _getMonthYearString(_selectedDate),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double income, double expenses, double balance) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSummaryCard(title: 'Income', amount: income, color: const Color(0xFF4CAF50), icon: Icons.trending_up)),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCard(title: 'Expenses', amount: expenses, color: const Color(0xFFf44336), icon: Icons.trending_down)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Balance',
                amount: balance,
                color: balance >= 0 ? const Color(0xFF2196F3) : const Color(0xFFf44336),
                icon: balance >= 0 ? Icons.account_balance_wallet : Icons.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCard(title: 'Pending', amount: _pendingTotal, color: const Color(0xFFFF9800), icon: Icons.schedule)),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySpendingCard(double totalExpenses) {
    // Define a list of colors for categories
    const categoryColors = [
      Color(0xFFf44336), Color(0xFF2196F3), Color(0xFF9C27B0),
      Color(0xFF4CAF50), Color(0xFFFF9800), Color(0xFF00BCD4), Color(0xFFE91E63)
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _categorySpending.isEmpty
            ? const Text('No expenses recorded for this month.', textAlign: TextAlign.center)
            : Column(
          children: _categorySpending.entries.toList().asMap().entries.map((entry) {
            int index = entry.key;
            MapEntry<String, double> categoryEntry = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildCategoryItem(
                categoryEntry.key,
                categoryEntry.value,
                Icons.category, // You can map icons if you want
                categoryColors[index % categoryColors.length],
                totalExpenses,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Transactions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AllTransactionsScreen()),
                );
              },
              child: const Text('View All', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF9C27B0))),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _recentTransactions.isEmpty
                ? const Text('No recent transactions found.', textAlign: TextAlign.center)
                : Column(
              children: _recentTransactions.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> transaction = entry.value;
                return Column(
                  children: [
                    _buildTransactionItem(transaction),
                    if (index < _recentTransactions.length - 1)
                      const Divider(height: 24),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCards(double savingsRate, double avgDailySpend) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
              ),
              child: Column(
                children: [
                  const Icon(Icons.savings, size: 32, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text('Savings Rate', style: TextStyle(fontSize: 14, color: Colors.white70)),
                  Text('${savingsRate.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [Color(0xFFffecd2), Color(0xFFfcb69f)]),
              ),
              child: Column(
                children: [
                  const Icon(Icons.show_chart, size: 32, color: Color(0xFF8D4E85)),
                  const SizedBox(height: 12),
                  const Text('Avg Daily Spend', style: TextStyle(fontSize: 14, color: Color(0xFF8D4E85))),
                  Text(
                    NumberFormat.simpleCurrency(locale: 'en_US', decimalDigits: 0).format(avgDailySpend),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF8D4E85)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -- Helper Widgets & Functions --

  Widget _buildSummaryCard({ required String title, required double amount, required Color color, required IconData icon }) {
    return Card(
      // ... Unchanged from your original code
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: color.withOpacity(0.1)),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(NumberFormat.simpleCurrency(locale: 'sr_Latn').format(amount), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, double amount, IconData icon, Color color, double totalExpenses) {
    final double percentage = totalExpenses > 0 ? (amount / totalExpenses) * 100 : 0.0;
    return Column(
      // ... Unchanged from your original code
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('${percentage.toStringAsFixed(1)}% of expenses', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Text(NumberFormat.simpleCurrency(locale: 'en_US').format(amount), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: percentage / 100, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(color)),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isIncome = transaction['type'] == 'income';
    final color = isIncome ? const Color(0xFF4CAF50) : const Color(0xFFf44336);
    final sign = isIncome ? '+' : '-';
    final date = transaction['date'] as DateTime;

    return Row(
      // ... Unchanged from your original code
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

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      // ... Theme builder unchanged
    );
    if (picked != null && (picked.year != _selectedDate.year || picked.month != _selectedDate.month)) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month);
      });
      _loadFinancialData(); // <-- Reload data when month changes
    }
  }

  String _getMonthYearString(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }
}