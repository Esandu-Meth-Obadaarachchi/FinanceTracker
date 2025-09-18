import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package.intl/intl.dart';
import '../utils/api_service.dart'; // Make sure this path is correct

class ManageLoansScreen extends StatefulWidget {
  const ManageLoansScreen({Key? key}) : super(key: key);

  @override
  _ManageLoansScreenState createState() => _ManageLoansScreenState();
}

class _ManageLoansScreenState extends State<ManageLoansScreen> {
  // Method to show the Add/Edit Loan dialog (no changes needed here)
  void _showLoanForm([DocumentSnapshot? loanDoc]) {
    final _formKey = GlobalKey<FormState>();
    final _reasonController = TextEditingController();
    final _amountController = TextEditingController();
    final _descriptionController = TextEditingController();
    String _selectedCategory = 'Personal';
    DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
    bool isEditing = loanDoc != null;

    if (isEditing) {
      final data = loanDoc.data() as Map<String, dynamic>;
      _reasonController.text = data['reason'];
      _amountController.text = data['amount'].toString();
      _descriptionController.text = data['description'] ?? '';
      _selectedCategory = data['category'];
      _dueDate = (data['dueDate'] as Timestamp).toDate();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20, left: 20, right: 20,
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isEditing ? 'Edit Loan' : 'Add New Loan', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(labelText: 'Reason (e.g., Credit Card Bill)'),
                        validator: (v) => v!.isEmpty ? 'Please enter a reason' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(labelText: 'Amount', prefixText: 'LKR '),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v!.isEmpty) return 'Please enter an amount';
                          if (double.tryParse(v) == null) return 'Invalid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        items: ['Personal', 'Home', 'Car', 'Credit Card', 'Student', 'Other']
                            .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                            .toList(),
                        onChanged: (v) => setModalState(() => _selectedCategory = v!),
                        decoration: const InputDecoration(labelText: 'Category'),
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Due Date'),
                        subtitle: Text(DateFormat.yMMMd().format(_dueDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setModalState(() => _dueDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Description (Optional)'),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                if (isEditing) {
                                  await ApiService.updateLoan(
                                    loanId: loanDoc.id,
                                    reason: _reasonController.text,
                                    amount: double.parse(_amountController.text),
                                    category: _selectedCategory,
                                    dueDate: _dueDate,
                                    description: _descriptionController.text,
                                  );
                                } else {
                                  await ApiService.addLoan(
                                    reason: _reasonController.text,
                                    amount: double.parse(_amountController.text),
                                    category: _selectedCategory,
                                    dueDate: _dueDate,
                                    description: _descriptionController.text,
                                  );
                                }
                                Navigator.pop(context);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                              isEditing ? 'Save Changes' : 'Add Loan',
                              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Method to convert a loan to an expense (no changes needed here)
  Future<void> _convertLoan(String loanId) async {
    final paidDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Payment Date',
    );

    if (paidDate != null) {
      try {
        await ApiService.convertLoanToExpense(loanId: loanId, paidDate: paidDate);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loan marked as paid and added to expenses!'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to convert: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Manage Loans'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blueGrey, Colors.teal]),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ApiService.getLoans(status: 'pending'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // ## Enhanced Empty State ##
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 100, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('No Pending Loans', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54)),
                  SizedBox(height: 10),
                  Text('Tap the "+" button to add your first loan.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          final loans = snapshot.data!.docs;
          final totalLoanAmount = loans.fold<double>(0, (sum, doc) => sum + (doc.data() as Map<String, dynamic>)['amount']);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // ## New Summary Card ##
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(colors: [Colors.blueGrey, Colors.black87]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Pending Loans', style: TextStyle(fontSize: 16, color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.simpleCurrency(locale: 'en_LK', name: 'LKR ').format(totalLoanAmount),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ## Redesigned Loan Item Cards ##
              ...loans.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final dueDate = (data['dueDate'] as Timestamp).toDate();
                final isOverdue = dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: isOverdue ? Colors.red.shade200 : Colors.transparent, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('OVERDUE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        if (isOverdue) const SizedBox(height: 8),
                        Text(
                          data['reason'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          NumberFormat.simpleCurrency(locale: 'en_LK', name: 'LKR ').format(data['amount']),
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.category, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(data['category'], style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                            const Spacer(),
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(DateFormat.yMMMd().format(dueDate), style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Edit'),
                                  onPressed: () => _showLoanForm(doc),
                                  style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  label: const Text('Delete'),
                                  onPressed: () => ApiService.deleteLoan(doc.id),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Mark as Paid'),
                              onPressed: () => _convertLoan(doc.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
      // ## Extended FAB ##
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLoanForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Loan'),
        tooltip: 'Add New Loan',
      ),
    );
  }
}