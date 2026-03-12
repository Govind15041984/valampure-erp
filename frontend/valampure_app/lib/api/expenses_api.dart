import 'dart:convert';
import 'client_api.dart';

class ExpensesApi {
  // 1. FETCH MONTHLY EXPENSES & TOTAL
  // Returns a map with 'total_amount', 'month_name', and 'items'
  static Future<Map<String, dynamic>> getMonthlyExpenses() async {
    try {
      final response = await ApiClient.get('/expenses/monthly');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load monthly expenses');
      }
    } catch (e) {
      print("DEBUG: Expenses getMonthlyExpenses Error -> $e");
      rethrow;
    }
  }

  // 2. CREATE A NEW EXPENSE ENTRY
  // Sends the JSON data matching your Pydantic schema (ExpenseCreate)
  static Future<bool> createExpense(Map<String, dynamic> data) async {
    print("DEBUG: Sending to /expenses/ -> ${jsonEncode(data)}");

    try {
      final response = await ApiClient.post('/expenses/', data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print("DEBUG: Expense Created Successfully");
        return true;
      } else {
        final error = jsonDecode(response.body);
        print("DEBUG: Expense Backend Error: ${error['detail']}");
        return false;
      }
    } catch (e) {
      print("DEBUG: createExpense Error -> $e");
      rethrow;
    }
  }

  // 3. DELETE AN EXPENSE
  static Future<bool> deleteExpense(int id) async {
    try {
      final response = await ApiClient.delete('/expenses/$id');

      if (response.statusCode == 200) {
        print("DEBUG: Expense Deleted Successfully");
        return true;
      } else {
        print("DEBUG: Delete Error: ${response.body}");
        return false;
      }
    } catch (e) {
      print("DEBUG: deleteExpense Error -> $e");
      rethrow;
    }
  }
}
