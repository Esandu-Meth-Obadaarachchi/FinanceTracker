import 'package:flutter/material.dart';

class ViewFinancesScreen extends StatefulWidget {
  const ViewFinancesScreen({Key? key}) : super(key: key);

  @override
  State<ViewFinancesScreen> createState() => _ViewFinancesScreenState();
}

class _ViewFinancesScreenState extends State<ViewFinancesScreen> {
  DateTime _selectedDate = DateTime.now();

  // Hardcoded data for demonstration
  final Map<String, Map<String, double>> _monthlyData = {
    '2024-09': {
      'income': 5000.0,
      'expenses': 3200.0,
      'pending': 800.0,
    },
    '2024-08': {
      'income': 4800.0,
      'expenses': 2900.0,
      'pending': 400.0,
    },
    '2024-07': {
      'income': 5200.0,
      'expenses': 3100.0,
      'pending': 600.0,
    },
  };

  final List<Map<String, dynamic>> _sampleTransactions = [
    {
      'type': 'income',
      'amount': 3000.0,
      'category': 'Salary',
      'description': 'Monthly salary',
      'date': '2024-09-01',
      'icon': Icons.work,
    },
    {
      'type': 'expense',
      'amount': 150.0,
      'category': 'Groceries',
      'description': 'Weekly shopping',
      'date': '2024-09-03',
      'icon': Icons.shopping_cart,
    },
    {
      'type': 'expense',
      'amount': 45.0,
      'category': 'Transportation',
      'description': 'Gas station',
      'date': '2024-09-04',
      'icon': Icons.local_gas_station,
    },
    {
      'type': 'income',
      'amount': 500.0,
      'category': 'Freelance',
      'description': 'Website project',
      'date': '2024-09-05',
      'icon': Icons.laptop,
    },
    {
      'type': 'expense',
      'amount': 80.0,
      'category': 'Entertainment',
      'description': 'Movie night',
      'date': '2024-09-06',
      'icon': Icons.movie,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final monthKey = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';
    final data = _monthlyData[monthKey] ?? {'income': 0.0, 'expenses': 0.0, 'pending': 0.0};
    final balance = data['income']! - data['expenses']!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'View Finances',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Selector
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.analytics,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Financial Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: _selectMonth,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getMonthYearString(_selectedDate),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Income',
                    amount: data['income']!,
                    color: const Color(0xFF4CAF50),
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Expenses',
                    amount: data['expenses']!,
                    color: const Color(0xFFf44336),
                    icon: Icons.trending_down,
                  ),
                ),
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
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Pending',
                    amount: data['pending']!,
                    color: const Color(0xFFFF9800),
                    icon: Icons.schedule,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Spending by Category
            const Text(
              'Spending Breakdown',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildCategoryItem('Food & Dining', 450.0, Icons.restaurant, const Color(0xFFf44336)),
                    const SizedBox(height: 16),
                    _buildCategoryItem('Transportation', 200.0, Icons.directions_car, const Color(0xFF2196F3)),
                    const SizedBox(height: 16),
                    _buildCategoryItem('Shopping', 300.0, Icons.shopping_bag, const Color(0xFF9C27B0)),
                    const SizedBox(height: 16),
                    _buildCategoryItem('Entertainment', 150.0, Icons.movie, const Color(0xFF4CAF50)),
                    const SizedBox(height: 16),
                    _buildCategoryItem('Bills & Utilities', 200.0, Icons.receipt, const Color(0xFFFF9800)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Recent Transactions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to all transactions
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9C27B0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _sampleTransactions.take(5).map((transaction) {
                    return Column(
                      children: [
                        _buildTransactionItem(transaction),
                        if (_sampleTransactions.indexOf(transaction) < 4)
                          const Divider(height: 24),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Statistics Cards
            const Text(
              'Monthly Statistics',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.savings,
                            size: 32,
                            color: Colors.white,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Savings Rate',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '36%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFffecd2), Color(0xFFfcb69f)],
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 32,
                            color: Color(0xFF8D4E85),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Avg Daily',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8D4E85),
                            ),
                          ),
                          Text(
                            '\$106',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8D4E85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.1),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category, double amount, IconData icon, Color color) {
    final double percentage = (amount / 3200.0) * 100; // Based on total expenses

    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}% of expenses',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final isIncome = transaction['type'] == 'income';
    final color = isIncome ? const Color(0xFF4CAF50) : const Color(0xFFf44336);
    final sign = isIncome ? '+' : '-';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            transaction['icon'],
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction['description'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${transaction['category']} • ${transaction['date']}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          '$sign\$${transaction['amount'].toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF9C27B0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}