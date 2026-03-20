import 'package:flutter/material.dart';
import '../../../api/staff_api.dart';

class StaffStatementScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const StaffStatementScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<StaffStatementScreen> createState() => _StaffStatementScreenState();
}

class _StaffStatementScreenState extends State<StaffStatementScreen> {
  late Future<Map<String, dynamic>> _statementData;
  double _bonusPercentage = 8.33; // Default starting value
  final TextEditingController _bonusController = TextEditingController(
    text: "8.33",
  );

  @override
  void initState() {
    super.initState();
    _statementData = StaffApi.getStaffStatement(widget.employeeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF37474F),
        title: Text("${widget.employeeName}'s Financial Statement"),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _statementData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data!;
          final summary = data['summary'];
          final List allHistory = data['history'];

          // Separate the lists based on type
          final settlements = allHistory
              .where((tx) => tx['type'] == "SETTLEMENT")
              .toList();
          final advances = allHistory
              .where((tx) => tx['type'] == "ADVANCE")
              .toList();

          return Column(
            children: [
              // Top Stats Card for Bonus/Debt overview
              _buildBonusStatsHeader(summary),

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT SIDE: Weekly Settlements
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          _buildColumnHeader(
                            "WEEKLY SETTLEMENTS",
                            Icons.assignment_turned_in,
                            settlements.length,
                          ),
                          Expanded(
                            child: settlements.isEmpty
                                ? _buildEmptyColumnState("No settlements yet")
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    itemCount: settlements.length,
                                    itemBuilder: (context, index) =>
                                        _buildSettlementCard(
                                          settlements[index],
                                        ),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // VERTICAL DIVIDER
                    VerticalDivider(
                      width: 1,
                      color: Colors.grey[300],
                      thickness: 1,
                    ),

                    // RIGHT SIDE: Advance History
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildColumnHeader(
                            "ADVANCE DISBURSEMENTS",
                            Icons.account_balance_wallet,
                            advances.length,
                          ),
                          Expanded(
                            child: advances.isEmpty
                                ? _buildEmptyColumnState("No advances yet")
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    itemCount: advances.length,
                                    itemBuilder: (context, index) =>
                                        _buildAdvanceCard(advances[index]),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBonusStatsHeader(Map<String, dynamic> summary) {
    double lifetimeEarnings = (summary['lifetime_earnings'] ?? 0.0).toDouble();
    double bonusAmount = (lifetimeEarnings * _bonusPercentage) / 100;

    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF37474F),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem(
                "TOTAL SHIFTS",
                "${summary['lifetime_shifts']}",
                Icons.history_toggle_off,
              ),
              _statItem(
                "LIFETIME EARNINGS",
                "₹${lifetimeEarnings.toStringAsFixed(0)}",
                Icons.payments_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                // 1. Corrected Current Debt (Balanced)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "TRUE DEBT",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "₹${summary['current_debt']}",
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // 2. Owner Input for Bonus Percentage
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _bonusController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    decoration: const InputDecoration(
                      labelText: "BONUS %",
                      labelStyle: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      suffixText: "%",
                      suffixStyle: TextStyle(color: Colors.white70),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _bonusPercentage = double.tryParse(val) ?? 0.0;
                      });
                    },
                  ),
                ),
                // 3. Calculated Bonus Total
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "TOTAL BONUS PAYABLE",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "₹${bonusAmount.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(String title, IconData icon, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(
            "$title ($count)",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementCard(Map<String, dynamic> tx) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "PAYMENT PERIOD",
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tx['period'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "NET PAID",
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹${tx['net']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[50]?.withOpacity(0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoChip(Icons.calendar_today, "SHIFTS", "${tx['shifts']}"),
                _infoChip(
                  Icons.account_balance_wallet,
                  "GROSS",
                  "₹${tx['gross']}",
                ),
                _infoChip(
                  Icons.money_off,
                  "ADVANCE CUT",
                  "₹${tx['deductions']}",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvanceCard(Map<String, dynamic> tx) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange[50],
            radius: 18,
            child: const Icon(
              Icons.history_edu,
              color: Colors.orange,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Cash Advance Issued",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  tx['date'],
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "AMOUNT",
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "₹${tx['net']}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 10, color: Colors.blueGrey),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.orangeAccent, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyColumnState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(
          message,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}
