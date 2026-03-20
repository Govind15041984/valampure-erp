import 'package:flutter/material.dart';
import '../../../api/sales_api.dart';
import '../../../api/profiles_api.dart';
import '../../../theme/app_colors.dart';
import '../../../core/pdf_service.dart';

class SalesDetailView extends StatefulWidget {
  final String saleId;
  const SalesDetailView({super.key, required this.saleId});

  @override
  State<SalesDetailView> createState() => _SalesDetailViewState();
}

class InvoiceItem {
  final String description;
  final String size;
  final String hsn;
  final double boxes;
  final double mts;
  final double totalQty;
  final double rate;
  final double amount;

  InvoiceItem({
    required this.description,
    required this.size,
    required this.hsn,
    required this.boxes,
    required this.mts,
    required this.totalQty,
    required this.rate,
    required this.amount,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: json['description'] ?? '',
      size: json['size']?.toString() ?? '',
      hsn: json['hsn']?.toString() ?? '60',
      boxes: (json['boxes'] ?? 0).toDouble(),
      mts: (json['mts'] ?? 0.0).toDouble(),
      totalQty: (json['total_qty'] ?? 0.0).toDouble(),
      rate: (json['rate'] ?? 0.0).toDouble(),
      amount: (json['amount'] ?? 0.0).toDouble(),
    );
  }
}

class _SalesDetailViewState extends State<SalesDetailView> {
  late Future<Map<String, dynamic>> _saleDetailFuture;
  Map<String, dynamic>? _myProfile;

  @override
  void initState() {
    super.initState();
    _saleDetailFuture = SalesApi.getSaleDetails(widget.saleId);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfilesApi.getProfile();
      if (mounted) setState(() => _myProfile = profile);
    } catch (e) {
      debugPrint("Profile load error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        // FIXED: Explicit text color for visibility
        title: const Text(
          "Sales Invoice Detail",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white, // Visible against primary background
          ),
        ),
        backgroundColor: AppColors.primary,
        // FIXED: Icon color and Back button visibility
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white), // Visible icon
            onPressed: () async {
              final sale = await _saleDetailFuture;
              _printInvoice(sale);
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _saleDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Invoice not found."));
          }

          final sale = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildReadonlyHeader(sale),
                _buildSectionLabel("ITEM DETAILS"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildReadonlyItemsTable(sale['items'] ?? []),
                ),
                const SizedBox(height: 20),
                _buildSummarySection(sale),
                const SizedBox(height: 40),
                _buildStatusFooter(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReadonlyHeader(Map<String, dynamic> sale) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        border: const Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _readonlyField("Consignee", sale['partner_name'] ?? "N/A"),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _readonlyField("Inv No", sale['invoice_no'] ?? ""),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _readonlyField("Order No", sale['order_no'] ?? "-"),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _readonlyField("Date", sale['invoice_date'] ?? ""),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadonlyItemsTable(List itemsList) {
    final items = itemsList.map((e) => InvoiceItem.fromJson(e)).toList();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Table(
        // FIXED: Optimized column widths to reduce description space
        columnWidths: const {
          0: FixedColumnWidth(30), // S.No
          1: FlexColumnWidth(1.8), // Description (Tighter width)
          2: FixedColumnWidth(40), // HSN
          3: FixedColumnWidth(35), // Box
          4: FixedColumnWidth(40), // MTS
          5: FixedColumnWidth(55), // Qty
          6: FixedColumnWidth(45), // Rate
          7: FixedColumnWidth(75), // Amt
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade100),
            children: [
              _th("S.No"),
              _th("Description"),
              _th("HSN"),
              _th("Box"),
              _th("MTS"),
              _th("Qty"),
              _th("Rate"),
              _th("Amt"),
            ],
          ),
          ...items.asMap().entries.map((entry) {
            int idx = entry.key + 1;
            var item = entry.value;
            return TableRow(
              children: [
                _tdText(idx.toString(), align: TextAlign.center),
                // Description with Size included
                _tdText(
                  "${item.size} MM ${item.description}".toUpperCase(),
                  align: TextAlign.left,
                ),
                _tdText(item.hsn, align: TextAlign.center),
                _tdText(item.boxes.toStringAsFixed(0)),
                _tdText(item.mts.toStringAsFixed(0)),
                _tdText(item.totalQty.toStringAsFixed(0), isBold: true),
                _tdText(item.rate.toStringAsFixed(2)),
                _tdText(item.amount.toStringAsFixed(2), isBold: true),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummarySection(Map<String, dynamic> sale) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _rowVal("Taxable Value", sale['taxable_value']),
            const SizedBox(height: 8),
            _rowVal("SGST (2.5%)", sale['sgst']),
            _rowVal("CGST (2.5%)", sale['cgst']),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(thickness: 1),
            ),
            _rowVal("GRAND TOTAL", sale['grand_total'], isBold: true),
          ],
        ),
      ),
    );
  }

  // Reusable Helper Methods
  Widget _readonlyField(String label, String value) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.black12),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );

  Widget _th(String label) => Padding(
    padding: const EdgeInsets.all(8),
    child: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
    ),
  );

  Widget _tdText(
    String val, {
    bool isBold = false,
    TextAlign align = TextAlign.right,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
    child: Text(
      val,
      textAlign: align,
      style: TextStyle(
        fontSize: 9,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );

  Widget _rowVal(String label, dynamic val, {bool isBold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
        Text(
          "₹ ${(val ?? 0).toStringAsFixed(2)}",
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    ),
  );

  Widget _buildSectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
    child: Row(
      children: [
        const Icon(Icons.list_alt, size: 16, color: Colors.grey),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );

  Widget _buildStatusFooter() => Container(
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.green.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user, size: 14, color: Colors.green),
        SizedBox(width: 8),
        Text(
          "OFFICIAL LEDGER RECORD",
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );

  // Inside _SalesDetailViewState class
  Future<void> _printInvoice(Map<String, dynamic> sale) async {
    if (_myProfile == null) return;

    // Map items and ensure the description is fully formed (Size + Name)
    final List<Map<String, dynamic>> invoiceItems =
        (sale['items'] as List<dynamic>? ?? []).map((e) {
          final item = InvoiceItem.fromJson(e);
          return {
            'description': "${item.size} MM ${item.description}".toUpperCase(),
            'hsn': item.hsn,
            'boxes': item.boxes,
            'mts': item.mts,
            'rate': item.rate,
          };
        }).toList();

    print("DEBUG SALE DATA: $sale");
    await PdfService.generateAndPrintInvoice(
      invoiceNo: sale['invoice_no'] ?? '',
      orderNo: sale['order_no'] ?? '-',
      buyerName: sale['partner_name'] ?? '',
      buyerGST: sale['partner_gstin'] ?? '', // Pass actual GST if available
      buyerState: 'Tamil Nadu',
      buyerStateCode: '33',
      items: invoiceItems, // Passing the list of maps
      subTotal: (sale['taxable_value'] ?? 0).toDouble(),
      tax: ((sale['sgst'] ?? 0) + (sale['cgst'] ?? 0)).toDouble(),
      grandTotal: (sale['grand_total'] ?? 0).toDouble(),
      company: {
        'name': _myProfile!['company_name'] ?? '',
        'gstin': _myProfile!['gstin'] ?? '',
        'address1': _myProfile!['address1'] ?? '',
        'address2': _myProfile!['address'] ?? '',
        'stateCode': '33',
        'areaCode': '124',
      },
      bank: {
        'bankName': _myProfile!['bank_name'] ?? '',
        'accountNo': _myProfile!['account_no'] ?? '',
        'ifsc': _myProfile!['ifsc_code'] ?? '',
      },
    );
  }
}
