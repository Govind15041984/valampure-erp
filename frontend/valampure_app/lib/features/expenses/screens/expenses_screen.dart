import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../api/expenses_api.dart';
import '../../../theme/app_colors.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = "General";
  String _selectedPaymentMode = "CASH";
  bool _isLoading = false;
  Map<String, dynamic>? _monthlyData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ExpensesApi.getMonthlyExpenses();
      setState(() => _monthlyData = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- ADD EXPENSE FORM (MODAL) ---
  void _showAddExpenseForm() {
    // Reset to pre-filled defaults
    _itemController.text = "Misc Expense";
    _amountController.clear();
    _remarksController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 25,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Add New Expense",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // 1. DATE PICKER
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Transaction Date"),
                  subtitle: Text(
                    DateFormat('dd-MM-yyyy').format(_selectedDate),
                  ),
                  trailing: const Icon(
                    Icons.calendar_month,
                    color: AppColors.primary,
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null)
                      setModalState(() => _selectedDate = picked);
                  },
                ),
                const Divider(),

                // 2. EXPENSE CATEGORY
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: "Expense Category",
                  ),
                  items:
                      [
                            "General",
                            "Tea/Snacks",
                            "Fuel",
                            "Maintenance",
                            "Electricity",
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) =>
                      setModalState(() => _selectedCategory = val!),
                ),
                const SizedBox(height: 15),

                // 3. ITEM NAME (With pre-filled text logic)
                TextField(
                  controller: _itemController,
                  decoration: const InputDecoration(
                    labelText: "Item Name",
                    hintText: "e.g. Office Supplies",
                  ),
                ),
                const SizedBox(height: 15),

                // AMOUNT FIELD
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Amount (₹)",
                    prefixText: "₹ ",
                  ),
                ),
                const SizedBox(height: 15),

                // 4. REMARKS
                TextField(
                  controller: _remarksController,
                  decoration: const InputDecoration(labelText: "Remarks"),
                ),
                const SizedBox(height: 15),

                // 5. PAYMENT MODE
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMode,
                  decoration: const InputDecoration(labelText: "Payment Mode"),
                  items: ["CASH", "GPAY", "BANK TRANSFER"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) =>
                      setModalState(() => _selectedPaymentMode = val!),
                ),
                const SizedBox(height: 30),

                // SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await _handleSave();
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text(
                      "SAVE EXPENSE",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_amountController.text.isEmpty) return;
    try {
      await ExpensesApi.createExpense({
        "expense_date": DateFormat('yyyy-MM-dd').format(_selectedDate),
        "category": _selectedCategory,
        "item_name": _itemController.text,
        "amount": double.parse(_amountController.text),
        "payment_mode": _selectedPaymentMode,
        "remarks": _remarksController.text,
      });
      _loadData();
    } catch (e) {
      debugPrint("Save error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Monthly Expenses")),
      body: Column(
        children: [
          _buildSummaryHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddExpenseForm,
                icon: const Icon(Icons.add),
                label: const Text("ADD EXPENSE"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildExpenseList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader() {
    double total = _monthlyData?['total_amount']?.toDouble() ?? 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Spends This Month",
            style: TextStyle(color: Colors.white70),
          ),
          Text(
            "₹ ${total.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList() {
    final List items = _monthlyData?['items'] ?? [];
    if (items.isEmpty)
      return const Center(child: Text("No data found for this month"));

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: 70),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey.shade100,
            child: Text(
              DateFormat('dd').format(DateTime.parse(item['expense_date'])),
            ),
          ),
          title: Text(
            item['item_name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("${item['category']} | ${item['payment_mode']}"),
          trailing: Text(
            "₹${item['amount']}",
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
