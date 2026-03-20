import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../api/staff_api.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<dynamic> employees = [];
  bool isLoading = true;
  bool isSaving = false;

  // Stores what is currently in the Database
  Map<String, Map<String, double>> savedMatrix = {};
  // Stores current UI state (including unsaved changes)
  Map<String, Map<String, double>> displayMatrix = {};

  List<DateTime> weekDates = [];

  @override
  void initState() {
    super.initState();
    _generateWeekDates(DateTime.now());
    _loadInitialData();
  }

  void _generateWeekDates(DateTime referenceDate) {
    DateTime monday = referenceDate.subtract(
      Duration(days: referenceDate.weekday - 1),
    );
    weekDates = List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      // 1. Fetch Employees
      final empData = await StaffApi.getEmployees();

      // 2. Fetch Existing Attendance for this week range
      String start = DateFormat('yyyy-MM-dd').format(weekDates.first);
      String end = DateFormat('yyyy-MM-dd').format(weekDates.last);
      final attendanceData = await StaffApi.getWeeklyAttendance(start, end);

      // 3. Map attendance data into our matrix
      Map<String, Map<String, double>> loadedData = {};
      for (var record in attendanceData) {
        String date = record['attendance_date'];
        String empId = record['employee_id'].toString();
        double shifts = (record['shifts_count'] as num).toDouble();

        if (!loadedData.containsKey(date)) loadedData[date] = {};
        loadedData[date]![empId] = shifts;
      }

      setState(() {
        employees = empData;
        savedMatrix = Map.from(loadedData);
        displayMatrix = _deepCopyMatrix(loadedData);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Load Error: $e")));
    }
  }

  Map<String, Map<String, double>> _deepCopyMatrix(
    Map<String, Map<String, double>> original,
  ) {
    return original.map((k, v) => MapEntry(k, Map.from(v)));
  }

  void _cycleAttendance(String dateKey, String empId) {
    setState(() {
      if (!displayMatrix.containsKey(dateKey)) displayMatrix[dateKey] = {};
      double current = displayMatrix[dateKey]![empId] ?? 0.0;

      // Cycle logic: 0 -> 1 -> 1.5 -> 0.5 -> 0
      double next;
      if (current == 0.0)
        next = 1.0;
      else if (current == 1.0)
        next = 1.5;
      else if (current == 1.5)
        next = 0.5;
      else
        next = 0.0;

      displayMatrix[dateKey]![empId] = next;
    });
  }

  bool _isDirty(String dateKey, String empId) {
    double saved = savedMatrix[dateKey]?[empId] ?? 0.0;
    double current = displayMatrix[dateKey]?[empId] ?? 0.0;
    return saved != current;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weekly Register"),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            onPressed: weekDates.isEmpty
                ? null
                : () {
                    // Add null check
                    _generateWeekDates(
                      weekDates[0].subtract(const Duration(days: 7)),
                    );
                    _loadInitialData();
                  },
          ),
          Center(
            child: Text(
              weekDates.isNotEmpty
                  ? DateFormat('dd MMM').format(weekDates[0])
                  : "...",
              style: const TextStyle(fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: weekDates.isEmpty
                ? null
                : () {
                    // Add null check
                    _generateWeekDates(
                      weekDates[0].add(const Duration(days: 7)),
                    );
                    _loadInitialData();
                  },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildLegend(),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 15,
                        headingRowHeight: 60,
                        columns: [
                          const DataColumn(label: Text('Staff Name')),
                          ...weekDates.map(
                            (d) => DataColumn(label: _buildDateHeader(d)),
                          ),
                        ],
                        rows: employees
                            .map((emp) => _buildEmployeeRow(emp))
                            .toList(),
                      ),
                    ),
                  ),
                ),
                _buildBottomAction(),
              ],
            ),
    );
  }

  DataRow _buildEmployeeRow(dynamic emp) {
    String empId = emp['id'].toString();
    return DataRow(
      cells: [
        DataCell(
          Text(
            emp['name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...weekDates.map((date) {
          String dKey = DateFormat('yyyy-MM-dd').format(date);
          double val = displayMatrix[dKey]?[empId] ?? 0.0;
          bool dirty = _isDirty(dKey, empId);

          return DataCell(
            GestureDetector(
              onTap: () => _cycleAttendance(dKey, empId),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _getColor(val),
                  borderRadius: BorderRadius.circular(6),
                  border: dirty
                      ? Border.all(color: Colors.black, width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    _getLabel(val),
                    style: TextStyle(
                      color: val == 0 ? Colors.grey : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDateHeader(DateTime d) {
    bool isToday =
        DateFormat('yyyy-MM-dd').format(d) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          DateFormat('E').format(d),
          style: TextStyle(
            fontSize: 10,
            color: isToday ? Colors.blue : Colors.grey,
          ),
        ),
        Text(
          DateFormat('dd').format(d),
          style: TextStyle(
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Colors.green[700],
        ),
        onPressed: isSaving ? null : _saveChanges,
        child: isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "SAVE CHANGES",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    List<Map<String, dynamic>> entriesToSave = [];

    displayMatrix.forEach((date, emps) {
      emps.forEach((empId, shifts) {
        if (_isDirty(date, empId)) {
          final emp = employees.firstWhere((e) => e['id'].toString() == empId);
          double rate = (emp['current_shift_rate'] as num).toDouble();
          entriesToSave.add({
            "employee_id": empId,
            "attendance_date": date,
            "shifts_count": shifts,
            "rate_at_time": rate,
            "daily_amount": shifts * rate,
          });
        }
      });
    });

    print("DEBUG: Total entries to save: ${entriesToSave.length}");

    if (entriesToSave.isEmpty) return;

    setState(() => isSaving = true);
    try {
      await StaffApi.postBulkAttendance(entriesToSave);
      await _loadInitialData(); // Refresh to lock in the "Saved" state
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Attendance Sync Successful")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Sync Failed: $e")));
    } finally {
      setState(() => isSaving = false);
    }
  }

  // --- Helpers ---
  String _getLabel(double v) =>
      v == 0 ? "-" : (v == 1.5 ? "1.5" : (v == 0.5 ? "0.5" : "1"));
  Color _getColor(double v) {
    if (v == 1.0) return Colors.green[400]!;
    if (v == 1.5) return Colors.blue[600]!;
    if (v == 0.5) return Colors.orange[400]!;
    return Colors.grey[200]!;
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendDot("1.0", Colors.green[400]!),
          const SizedBox(width: 15),
          _legendDot("1.5 (OT)", Colors.blue[600]!),
          const SizedBox(width: 15),
          _legendDot("0.5", Colors.orange[400]!),
          const SizedBox(width: 15),
          _legendDot("Unsaved", Colors.black, isBorder: true),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color, {bool isBorder = false}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isBorder ? Colors.white : color,
            border: isBorder ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
