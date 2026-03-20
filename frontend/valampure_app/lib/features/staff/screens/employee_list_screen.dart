import 'package:flutter/material.dart';
import 'package:valampure_app/features/staff/screens/salary_settlement_screen.dart';
import '../../../api/staff_api.dart';
import 'employee_add_sheet.dart';
import 'attendance_screen.dart';
import 'staff_statement_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  List<dynamic> employees = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() => isLoading = true);
    try {
      final data = await StaffApi.getEmployees();
      setState(() {
        employees = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error fetching staff: $e")));
      }
    }
  }

  void _navigateToSettlement(BuildContext context) {
    final now = DateTime.now();
    DateTime lastMonday = now.subtract(Duration(days: now.weekday - 1 + 7));
    DateTime lastSaturday = lastMonday.add(const Duration(days: 5));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalarySettlementScreen(
          startDate: lastMonday.toIso8601String().split('T')[0],
          endDate: lastSaturday.toIso8601String().split('T')[0],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(context),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildContentHeader(),
                              const SizedBox(height: 20),
                              Expanded(
                                child: employees.isEmpty
                                    ? const Center(
                                        child: Text("No employees found"),
                                      )
                                    : RefreshIndicator(
                                        onRefresh: _fetchEmployees,
                                        child: _buildEmployeeGrid(),
                                      ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 60,
      width: double.infinity,
      color: const Color(0xFF344955),
      child: const Center(
        child: Text(
          "VALAMPURI ELASTICS",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF344955),
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          _sidebarItem(
            Icons.people_alt_rounded,
            "Staff Directory",
            true,
            () {},
          ),
          _sidebarItem(
            Icons.assignment_turned_in_rounded,
            "Daily Attendance",
            false,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AttendanceScreen(),
                ),
              );
            },
          ),
          _sidebarItem(
            Icons.payments_rounded,
            "Weekly Payroll",
            false,
            () => _navigateToSettlement(context),
          ),
          const Spacer(),
          // Updated: Back to Dashboard logic instead of Logout
          _sidebarItem(
            Icons.dashboard_rounded,
            "Main Dashboard",
            false,
            () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    IconData icon,
    String title,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isSelected ? Colors.orange : Colors.white70),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildContentHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Staff Management",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[800],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _showAddEmployeeSheet(context),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text(
            "ADD EMPLOYEE",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeGrid() {
    return ListView.builder(
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final emp = employees[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            // 1. Added InkWell to make the whole card clickable
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              // 2. Navigate to Statement Screen on tap
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StaffStatementScreen(
                    employeeId: emp['id'].toString(),
                    employeeName: emp['name'],
                  ),
                ),
              );
            },
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Text(
                  emp['name'][0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                emp['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Text(
                "${emp['designation']} • ₹${emp['current_shift_rate']} per shift",
              ),
              trailing: IconButton(
                icon: const Icon(Icons.payments_outlined, color: Colors.green),
                onPressed: () {
                  // Keep the existing transaction dialog functionality
                  _showTransactionDialog(context, emp);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTransactionDialog(BuildContext context, dynamic employee) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'ADVANCE';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text("Money for ${employee['name']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'ADVANCE',
                    label: Text("Advance"),
                    icon: Icon(Icons.money_off),
                  ),
                  ButtonSegment(
                    value: 'BONUS',
                    label: Text("Bonus"),
                    icon: Icon(Icons.card_giftcard),
                  ),
                ],
                selected: {selectedType},
                onSelectionChanged: (Set<String> newSelection) =>
                    setDialogState(() => selectedType = newSelection.first),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount (₹)",
                  border: OutlineInputBorder(),
                  prefixText: "₹ ",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final txData = {
                  "employee_id": employee['id'].toString(),
                  "transaction_date": DateTime.now().toIso8601String().split(
                    'T',
                  )[0],
                  "amount": double.parse(amountController.text),
                  "transaction_type": selectedType,
                  "payment_mode": "CASH",
                  "description": descController.text,
                };
                bool success = await StaffApi.createTransaction(txData);
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Transaction Saved!")),
                  );
                }
              },
              child: const Text("Confirm"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEmployeeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEmployeeSheet(onSuccess: _fetchEmployees),
    );
  }
}
