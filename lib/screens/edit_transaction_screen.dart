import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/api_service.dart';

class EditTransactionScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const EditTransactionScreen({Key? key, required this.transaction}) : super(key: key);

  @override
  _EditTransactionScreenState createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _reasonController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  late DateTime _selectedDate;
  late String _transactionType;
  late String _transactionId;
  bool _isLoading = false;

  final List<String> _incomeCategories = ['Salary', 'Freelance', 'Investment', 'Business', 'Gift', 'Bonus', 'Other'];
  final List<String> _expenseCategories = ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Health', 'Other'];

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _transactionId = transaction['id'];
    _transactionType = transaction['type'];
    _reasonController = TextEditingController(text: transaction['description']);
    _amountController = TextEditingController(text: transaction['amount'].toString());
    _descriptionController = TextEditingController(text: transaction['notes'] ?? '');
    _selectedCategory = transaction['category'];
    _selectedDate = transaction['date'];
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isLoading = true; });

    try {
      if (_transactionType == 'income') {
        await ApiService.updateIncome(
          incomeId: _transactionId,
          reason: _reasonController.text,
          amount: double.parse(_amountController.text),
          category: _selectedCategory,
          date: _selectedDate,
          description: _descriptionController.text,
        );
      } else {
        await ApiService.updateExpense(
          expenseId: _transactionId,
          reason: _reasonController.text,
          amount: double.parse(_amountController.text),
          category: _selectedCategory,
          date: _selectedDate,
          description: _descriptionController.text,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction updated successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // Return true to indicate success

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = _transactionType == 'income';
    final categories = isIncome ? _incomeCategories : _expenseCategories;
    final themeColor = isIncome ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${isIncome ? 'Income' : 'Expense'}'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isIncome ? [Colors.green, Colors.teal] : [Colors.red, Colors.orange],
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(labelText: 'Reason / Description'),
                validator: (value) => value!.isEmpty ? 'Please enter a reason' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ '),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an amount';
                  if (double.tryParse(value) == null) return 'Enter a valid number';
                  if (double.parse(value) <= 0) return 'Amount must be positive';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() { _selectedCategory = value; });
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Transaction Date'),
                subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() { _selectedDate = pickedDate; });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                  child: _isLoading
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                      : const Text('Save Changes', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}