import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/api_service.dart';

class ManagePendingIncomeScreen extends StatefulWidget {
  const ManagePendingIncomeScreen({Key? key}) : super(key: key);

  @override
  State<ManagePendingIncomeScreen> createState() => _ManagePendingIncomeScreenState();
}

class _ManagePendingIncomeScreenState extends State<ManagePendingIncomeScreen> {
  // Convert a pending income item to actual income
  Future<void> _convertIncome(String pendingIncomeId, BuildContext context) async {
    DateTime? actualDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Received Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4CAF50)),
          ),
          child: child!,
        );
      },
    );

    if (actualDate != null) {
      try {
        await ApiService.convertPendingToIncome(
          pendingIncomeId: pendingIncomeId,
          actualDate: actualDate,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pending income converted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to convert: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Delete a pending income item
  Future<void> _deleteIncome(String pendingIncomeId, BuildContext context) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this pending income? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deletePendingIncome(pendingIncomeId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pending income deleted.'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Pending Income', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Use the ApiService to get a stream of items with 'pending' status
        stream: ApiService.getPendingIncome(status: 'pending'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('No pending income found!', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final pendingDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: pendingDocs.length,
            itemBuilder: (context, index) {
              final doc = pendingDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final expectedDate = (data['expectedDate'] as Timestamp).toDate();

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['reason'] ?? 'No Reason',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.simpleCurrency(locale: 'en_US').format(data['amount']),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.category, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(data['category'] ?? 'N/A', style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Expected on: ${DateFormat.yMd().format(expectedDate)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      if (data['description'] != null && data['description'].isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(data['description'], style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            label: const Text('Delete', style: TextStyle(color: Colors.red)),
                            onPressed: () => _deleteIncome(doc.id, context),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle, color: Colors.white),
                            label: const Text('Convert', style: TextStyle(color: Colors.white)),
                            onPressed: () => _convertIncome(doc.id, context),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}