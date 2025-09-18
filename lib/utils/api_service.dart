import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  // EXPENSE METHODS
  static Future<String> addExpense({
    required String reason,
    required double amount,
    required String category,
    required DateTime date,
    String? description,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('expenses')
          .add({
        'reason': reason,
        'amount': amount,
        'category': category,
        'description': description ?? '',
        'date': Timestamp.fromDate(date),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  static Future<void> updateExpense({
    required String expenseId,
    String? reason,
    double? amount,
    String? category,
    DateTime? date,
    String? description,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      Map<String, dynamic> updateData = {'updatedAt': Timestamp.now()};

      if (reason != null) updateData['reason'] = reason;
      if (amount != null) updateData['amount'] = amount;
      if (category != null) updateData['category'] = category;
      if (date != null) updateData['date'] = Timestamp.fromDate(date);
      if (description != null) updateData['description'] = description;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('expenses')
          .doc(expenseId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  static Future<void> deleteExpense(String expenseId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('expenses')
          .doc(expenseId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  static Stream<QuerySnapshot> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) {
    if (currentUserId == null) throw Exception('User not authenticated');

    Query query = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('expenses')
        .orderBy('date', descending: true);

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots();
  }

  // INCOME METHODS
  static Future<String> addIncome({
    required String reason,
    required double amount,
    required String category,
    required DateTime date,
    String? description,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('income')
          .add({
        'reason': reason,
        'amount': amount,
        'category': category,
        'description': description ?? '',
        'date': Timestamp.fromDate(date),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add income: $e');
    }
  }

  static Future<void> updateIncome({
    required String incomeId,
    String? reason,
    double? amount,
    String? category,
    DateTime? date,
    String? description,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      Map<String, dynamic> updateData = {'updatedAt': Timestamp.now()};

      if (reason != null) updateData['reason'] = reason;
      if (amount != null) updateData['amount'] = amount;
      if (category != null) updateData['category'] = category;
      if (date != null) updateData['date'] = Timestamp.fromDate(date);
      if (description != null) updateData['description'] = description;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('income')
          .doc(incomeId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update income: $e');
    }
  }

  static Future<void> deleteIncome(String incomeId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('income')
          .doc(incomeId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete income: $e');
    }
  }

  static Stream<QuerySnapshot> getIncome({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) {
    if (currentUserId == null) throw Exception('User not authenticated');

    Query query = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('income')
        .orderBy('date', descending: true);

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots();
  }

  // PENDING INCOME METHODS
  static Future<String> addPendingIncome({
    required String reason,
    required double amount,
    required String category,
    required DateTime expectedDate,
    String? description,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('pendingIncome')
          .add({
        'reason': reason,
        'amount': amount,
        'category': category,
        'description': description ?? '',
        'expectedDate': Timestamp.fromDate(expectedDate),
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add pending income: $e');
    }
  }

  static Future<void> updatePendingIncome({
    required String pendingIncomeId,
    String? reason,
    double? amount,
    String? category,
    DateTime? expectedDate,
    String? description,
    String? status,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      Map<String, dynamic> updateData = {'updatedAt': Timestamp.now()};

      if (reason != null) updateData['reason'] = reason;
      if (amount != null) updateData['amount'] = amount;
      if (category != null) updateData['category'] = category;
      if (expectedDate != null) updateData['expectedDate'] = Timestamp.fromDate(expectedDate);
      if (description != null) updateData['description'] = description;
      if (status != null) updateData['status'] = status;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('pendingIncome')
          .doc(pendingIncomeId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update pending income: $e');
    }
  }

  static Future<void> deletePendingIncome(String pendingIncomeId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('pendingIncome')
          .doc(pendingIncomeId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete pending income: $e');
    }
  }

  // Convert pending income to actual income
  static Future<void> convertPendingToIncome({
    required String pendingIncomeId,
    required DateTime actualDate,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      // Get pending income data
      DocumentSnapshot pendingDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('pendingIncome')
          .doc(pendingIncomeId)
          .get();

      if (!pendingDoc.exists) throw Exception('Pending income not found');

      Map<String, dynamic> pendingData = pendingDoc.data() as Map<String, dynamic>;

      // Add to income collection
      await addIncome(
        reason: pendingData['reason'],
        amount: pendingData['amount'].toDouble(),
        category: pendingData['category'],
        date: actualDate,
        description: pendingData['description'],
      );

      // Update pending income status to received
      await updatePendingIncome(
        pendingIncomeId: pendingIncomeId,
        status: 'received',
      );
    } catch (e) {
      throw Exception('Failed to convert pending income: $e');
    }
  }

  static Stream<QuerySnapshot> getPendingIncome({String? status}) {
    if (currentUserId == null) throw Exception('User not authenticated');

    Query query = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('pendingIncome')
        .orderBy('expectedDate', descending: false);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots();
  }

  // USER METHODS
  static Future<void> createUserDocument(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  // ANALYTICS METHODS
  static Future<Map<String, double>> getMonthlyTotals(DateTime month) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      DateTime startOfMonth = DateTime(month.year, month.month, 1);
      DateTime endOfMonth = DateTime(month.year, month.month + 1, 0);

      // Get expenses
      QuerySnapshot expenseSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('expenses')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      // Get income
      QuerySnapshot incomeSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('income')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      double totalExpenses = 0;
      double totalIncome = 0;

      for (var doc in expenseSnapshot.docs) {
        totalExpenses += (doc.data() as Map<String, dynamic>)['amount'].toDouble();
      }

      for (var doc in incomeSnapshot.docs) {
        totalIncome += (doc.data() as Map<String, dynamic>)['amount'].toDouble();
      }

      return {
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'netIncome': totalIncome - totalExpenses,
      };
    } catch (e) {
      throw Exception('Failed to get monthly totals: $e');
    }
  }
}