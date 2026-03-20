import 'package:flutter/material.dart';
import '../../../api/staff_api.dart';
import 'dart:convert';

class SalarySettlementScreen extends StatefulWidget {
  final String startDate;
  final String endDate;

  const SalarySettlementScreen({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<SalarySettlementScreen> createState() => _SalarySettlementScreenState();
}

class _SalarySettlementScreenState extends State<SalarySettlementScreen> {
  List<dynamic> previewData = [];
  Set<String> selectedIds = {};
  Map<String, double> customDeductions = {};
  bool isLoading = true;
  String? currentStart;
  String? currentEnd;

  @override
  void initState() {
    super.initState();
    currentStart = widget.startDate;
    currentEnd = widget.endDate;
    _fetchPreview();
  }

  Future<void> _fetchPreview() async {
    if (currentStart == null || currentEnd == null) return;
    setState(() => isLoading = true);

    try {
      final data = await StaffApi.getSalaryPreview(currentStart!, currentEnd!);
      if (!mounted) return;

      setState(() {
        previewData = data;
        // Logic: ONLY auto-select employees who are NOT settled yet
        selectedIds = data
            .where((e) => e['is_settled'] != true)
            .map((e) => e['employee_id'].toString())
            .toSet();
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Preview Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _calculateNet(dynamic emp) {
    double gross = (emp['gross_salary'] as num).toDouble();
    double advance =
        customDeductions[emp['employee_id'].toString()] ??
        (emp['unsettled_advance'] as num).toDouble();
    return gross - advance;
  }

  Future<void> _processSettlement() async {
    setState(() => isLoading = true);
    int successCount = 0;

    try {
      // Only process employees who are selected AND not already settled
      final toProcess = previewData.where((e) {
        return selectedIds.contains(e['employee_id'].toString()) &&
            e['is_settled'] != true;
      }).toList();

      for (var emp in toProcess) {
        final payload = {
          "profile_id": emp['profile_id'].toString(),
          "employee_id": emp['employee_id'].toString(),
          "period_start": currentStart,
          "period_end": currentEnd,
          "total_shifts": emp['total_shifts'],
          "gross_salary": emp['gross_salary'],
          "advance_deducted":
              customDeductions[emp['employee_id'].toString()] ??
              emp['unsettled_advance'] ??
              0,
          "other_deductions": 0,
          "incentives_added": 0,
          "net_paid": _calculateNet(emp),
          "payment_mode": "CASH",
          "remarks": "Weekly Settlement",
        };

        bool success = await StaffApi.paySalary(payload);
        if (success) successCount++;
      }

      if (!mounted) return;
      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Settled $successCount staff members"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Settlement failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Weekly Settlement")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    itemCount: previewData.length,
                    itemBuilder: (context, index) {
                      final emp = previewData[index];
                      final String id = emp['employee_id'].toString();
                      final bool alreadyPaid = emp['is_settled'] ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        color: alreadyPaid ? Colors.grey.shade50 : Colors.white,
                        child: ListTile(
                          leading: Checkbox(
                            value: alreadyPaid
                                ? true
                                : selectedIds.contains(id),
                            activeColor: alreadyPaid
                                ? Colors.grey
                                : Colors.blue,
                            onChanged: alreadyPaid
                                ? null
                                : (val) {
                                    setState(() {
                                      val!
                                          ? selectedIds.add(id)
                                          : selectedIds.remove(id);
                                    });
                                  },
                          ),
                          title: Row(
                            children: [
                              Text(
                                emp['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: alreadyPaid
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                              ),
                              if (alreadyPaid) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "PAID",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            "Shifts: ${emp['total_shifts']} | Gross: ₹${emp['gross_salary']}",
                          ),
                          trailing: Opacity(
                            opacity: alreadyPaid ? 0.6 : 1.0,
                            child: _buildDeductionBox(emp),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildSummaryFooter(),
              ],
            ),
    );
  }

  Widget _buildDeductionBox(dynamic emp) {
    double currentDed =
        (customDeductions[emp['employee_id'].toString()] ??
                emp['unsettled_advance'] ??
                0)
            .toDouble();

    return Container(
      width: 100, // Reduced width slightly to prevent overflow
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min, // Fixes 10px overflow
        children: [
          const Text(
            "Deduct Adv.",
            style: TextStyle(fontSize: 8, color: Colors.grey, height: 1.0),
          ),
          const SizedBox(height: 2),
          GestureDetector(
            onTap: emp['is_settled'] == true
                ? null
                : () => _showEditDeductionDialog(emp),
            child: Text(
              "₹${currentDed.toStringAsFixed(0)}",
              style: TextStyle(
                color: emp['is_settled'] == true ? Colors.grey : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "Net: ₹${_calculateNet(emp).toStringAsFixed(0)}",
              style: TextStyle(
                color: emp['is_settled'] == true ? Colors.grey : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shiftWeek(int days) {
    DateTime start = DateTime.parse(currentStart!);
    DateTime end = DateTime.parse(currentEnd!);
    setState(() {
      currentStart = start
          .add(Duration(days: days))
          .toIso8601String()
          .split('T')[0];
      currentEnd = end
          .add(Duration(days: days))
          .toIso8601String()
          .split('T')[0];
      customDeductions.clear(); // Clear manual edits when moving weeks
    });
    _fetchPreview();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: DateTime.parse(currentStart!),
        end: DateTime.parse(currentEnd!),
      ),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        currentStart = picked.start.toIso8601String().split('T')[0];
        currentEnd = picked.end.toIso8601String().split('T')[0];
        customDeductions.clear();
      });
      _fetchPreview();
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.blueAccent),
            onPressed: () => _shiftWeek(-7),
          ),
          Expanded(
            child: InkWell(
              onTap: _selectDateRange,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Settlement Period",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 14,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$currentStart  ➔  $currentEnd",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.blueAccent),
            onPressed: () => _shiftWeek(7),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "${selectedIds.length} Selected",
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSummaryFooter() {
    double pendingToPay = 0;
    double alreadySettledTotal = 0;
    int unsettledCount = 0;

    for (var emp in previewData) {
      double net = _calculateNet(emp);
      if (emp['is_settled'] == true) {
        alreadySettledTotal += net;
      } else {
        unsettledCount++; // Count how many people are still waiting for pay
        if (selectedIds.contains(emp['employee_id'].toString())) {
          pendingToPay += net;
        }
      }
    }

    // The button should show as long as there is at least ONE unsettled person
    bool showSettleButton = unsettledCount > 0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  showSettleButton
                      ? "Total Disbursement"
                      : "Total Settled (History)",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "₹${(showSettleButton ? pendingToPay : alreadySettledTotal).toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: showSettleButton ? Colors.blue : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          if (showSettleButton)
            ElevatedButton(
              // Enable button if someone is selected AND payment > 0
              onPressed: (selectedIds.isEmpty || pendingToPay <= 0)
                  ? null
                  : _processSettlement,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors
                    .grey
                    .shade900, // Matching your Login/Add Employee style
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "SETTLE NOW",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          else
            const Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                Text(
                  "ALL PAID",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showEditDeductionDialog(dynamic emp) {
    String id = emp['employee_id'].toString();
    final controller = TextEditingController(
      text: (customDeductions[id] ?? emp['unsettled_advance']).toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Adjust Deduction: ${emp['name']}"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Amount to deduct",
            prefixText: "₹ ",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(
                () => customDeductions[id] =
                    double.tryParse(controller.text) ?? 0,
              );
              Navigator.pop(context);
            },
            child: const Text("Apply"),
          ),
        ],
      ),
    );
  }
}
