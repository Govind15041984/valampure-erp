import 'dart:convert';
import 'client_api.dart';

class StaffApi {
  // 1. CREATE EMPLOYEE
  // Adds a new staff member to the unit
  static Future<bool> createEmployee(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.post('/staff-salary/create', data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        print("DEBUG: Create Employee Error: ${error['detail']}");
        return false;
      }
    } catch (e) {
      print("DEBUG: createEmployee Error -> $e");
      rethrow;
    }
  }

  // 2. FETCH EMPLOYEES
  // Gets all active employees for the current profile
  // lib/services/api/staff_api.dart

  static Future<List<dynamic>> getEmployees() async {
    try {
      // UPDATED: Added '-salary' to match your backend screenshot
      final response = await ApiClient.get('/staff-salary/list');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          "Failed to load employees. Status: ${response.statusCode}",
        );
      }
    } catch (e) {
      print("DEBUG: getEmployees Error -> $e");
      rethrow;
    }
  }

  // 1. Fetch existing attendance for the week
  static Future<List<dynamic>> getWeeklyAttendance(
    String startDate,
    String endDate,
  ) async {
    try {
      // This allows the grid to "hydrate" with existing ticks
      final response = await ApiClient.get(
        '/staff-salary/attendance?start_date=$startDate&end_date=$endDate',
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("DEBUG: getWeeklyAttendance Error -> $e");
      return [];
    }
  }

  // 2. Reuse your existing Bulk Post
  static Future<bool> postBulkAttendance(
    List<Map<String, dynamic>> entries,
  ) async {
    try {
      final response = await ApiClient.post('/staff-salary/attendance/bulk', {
        'entries': entries,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      rethrow;
    }
  }

  // 4. GET ADVANCE BALANCE
  // Checks how much an employee currently owes
  static Future<double> getAdvanceBalance(String employeeId) async {
    try {
      final response = await ApiClient.get(
        '/staff-salary/advance-balance/$employeeId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['advance_balance'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      print("DEBUG: getAdvanceBalance Error -> $e");
      return 0.0;
    }
  }

  // 5. SALARY SETTLEMENT
  // Finalizes the pay and handles automatic advance deductions
  static Future<bool> paySalary(Map<String, dynamic> salaryData) async {
    try {
      final response = await ApiClient.post(
        '/staff-salary/salary-settlement',
        salaryData,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        print("DEBUG: Salary Settlement Error: ${error['detail']}");
        return false;
      }
    } catch (e) {
      print("DEBUG: paySalary Error -> $e");
      rethrow;
    }
  }

  // 6. RECORD TRANSACTION (ADVANCE / BONUS)
  // Records a single cash movement for an employee
  static Future<bool> createTransaction(Map<String, dynamic> txData) async {
    try {
      final response = await ApiClient.post(
        '/staff-salary/transaction',
        txData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        print("DEBUG: Transaction Error: ${error['detail']}");
        return false;
      }
    } catch (e) {
      print("DEBUG: createTransaction Error -> $e");
      rethrow;
    }
  }

  // 7. GET SALARY PREVIEW
  // Fetches the calculated math (Gross, Shifts, Advances) for the week
  // This is the "Brain" of your Settlement Screen
  static Future<List<dynamic>> getSalaryPreview(
    String startDate,
    String endDate,
  ) async {
    try {
      final response = await ApiClient.get(
        '/staff-salary/salary-preview?start_date=$startDate&end_date=$endDate',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        print("DEBUG: Salary Preview Error: ${error['detail']}");
        throw Exception(error['detail'] ?? "Failed to load salary preview");
      }
    } catch (e) {
      print("DEBUG: getSalaryPreview Error -> $e");
      rethrow;
    }
  }

  // 8. GET STAFF STATEMENT (HISTORY & BONUS STATS)
  // Fetches lifetime earnings, total shifts, and transaction history
  static Future<Map<String, dynamic>> getStaffStatement(
    String employeeId,
  ) async {
    try {
      // Endpoint matches the backend router prefix and employee_id parameter
      final response = await ApiClient.get(
        '/staff-salary/$employeeId/statement',
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        print("DEBUG: Staff Statement Error: ${error['detail']}");
        throw Exception(error['detail'] ?? "Failed to load staff statement");
      }
    } catch (e) {
      print("DEBUG: getStaffStatement Error -> $e");
      rethrow;
    }
  }
}
