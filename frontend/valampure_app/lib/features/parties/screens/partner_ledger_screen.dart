import 'package:flutter/material.dart';
import '../../../api/partners_api.dart';
import 'payment_entry_screen.dart';

class PartnerLedgerScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  final String partnerType; // "SUPPLIER" or "BUYER"

  const PartnerLedgerScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    required this.partnerType,
  });

  @override
  State<PartnerLedgerScreen> createState() => _PartnerLedgerScreenState();
}

class _PartnerLedgerScreenState extends State<PartnerLedgerScreen> {
  Key _refreshKey = UniqueKey();

  void _refreshLedger() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSupplier = widget.partnerType == "SUPPLIER";

    // VALAMPURI GREY THEME COLORS
    final Color appHeaderColor = const Color(0xFF37474F); // Dark Blue-Grey
    final Color scaffoldBg = Colors.grey[50]!;

    // Standard Business Labels
    final String leftLabel = isSupplier ? "PURCHASE" : "SALES";
    final String rightLabel = isSupplier ? "PAID" : "RECEIVED";

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appHeaderColor, // Consistent Grey Theme
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.partnerName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "${widget.partnerType.toUpperCase()} LEDGER",
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        key: _refreshKey,
        future: PartnersApi.getPartnerLedger(widget.partnerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No transactions found."));
          }

          final transactions = snapshot.data!;
          final double currentTotal = double.parse(
            transactions.first['running_balance'].toString(),
          );

          return Column(
            children: [
              // 1. DYNAMIC SUMMARY CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.black12)),
                ),
                child: Column(
                  children: [
                    Text(
                      isSupplier ? "TOTAL PAYABLE" : "TOTAL RECEIVABLE",
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₹ ${currentTotal.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        // Color preserved for financial urgency
                        color: isSupplier ? Colors.red[800] : Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. COLUMN HEADERS
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                color: Colors.white, // Standard white row for header
                child: Row(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text(
                        "ENTRY DETAILS",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        leftLabel,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        rightLabel,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. TRANSACTION LIST
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final txn = transactions[index];
                    final bool isOpening = txn['is_opening'] ?? false;
                    final double debit = double.parse(txn['debit'].toString());
                    final double credit = double.parse(
                      txn['credit'].toString(),
                    );

                    double leftVal = isSupplier ? credit : debit;
                    double rightVal = isSupplier ? debit : credit;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isOpening ? Colors.grey[100] : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isOpening)
                                  Text(
                                    txn['date'],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  txn['description'] ?? "",
                                  style: TextStyle(
                                    fontWeight: isOpening
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 14,
                                    color: isOpening
                                        ? Colors.blueGrey[300]
                                        : Colors.blueGrey[800],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "Bal: ₹${txn['running_balance']}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isOpening) ...[
                            Expanded(
                              flex: 2,
                              child: Text(
                                leftVal > 0
                                    ? "₹${leftVal.toStringAsFixed(0)}"
                                    : "-",
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                rightVal > 0
                                    ? "₹${rightVal.toStringAsFixed(0)}"
                                    : "-",
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ] else
                            const Expanded(flex: 4, child: SizedBox()),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black12)),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: appHeaderColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _showPaymentForm(context),
          child: Text(
            isSupplier ? "ADD PAYMENT (PAID)" : "ADD RECEIPT (RECEIVED)",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPaymentForm(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentEntryScreen(
          partnerId: widget.partnerId,
          partnerName: widget.partnerName,
          partnerType: widget.partnerType,
        ),
      ),
    );

    if (result == true) {
      _refreshLedger();
    }
  }
}
