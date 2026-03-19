import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../api/sales_api.dart';
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
  final int boxes;
  final double mts;
  final double rate;

  InvoiceItem({
    required this.description,
    required this.boxes,
    required this.mts,
    required this.rate,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      description: json['description'] ?? '',
      boxes: (json['boxes'] ?? 0) as int,
      mts: (json['mts_count'] ?? 0).toDouble(),
      rate: (json['rate'] ?? 0).toDouble(),
    );
  }
}

class _SalesDetailViewState extends State<SalesDetailView> {
  late Future<Map<String, dynamic>> _saleDetailFuture;

  @override
  void initState() {
    super.initState();
    _saleDetailFuture = SalesApi.getSaleDetails(widget.saleId);
  }

  Future<void> _printInvoice() async {
    try {
      final sale = await _saleDetailFuture;

      /// convert API map items -> InvoiceItem list
      final List<InvoiceItem> invoiceItems =
      (sale['items'] as List<dynamic>? ?? [])
          .map((e) => InvoiceItem.fromJson(e))
          .toList();

      await PdfService.generateAndPrintInvoice(
        invoiceNo: sale['invoice_no'] ?? '',
        orderNo: sale['order_no'] ?? '',
        buyerName: sale['partner_name'] ?? '',
        buyerGST: sale['partner_gstin'] ?? '',
        buyerState: sale['state'] ?? 'Tamil Nadu',
        buyerStateCode: sale['stateCode'] ?? '33',
        items: invoiceItems,
        subTotal: (sale['taxable_value'] ?? 0).toDouble(),
        tax: ((sale['sgst'] ?? 0) + (sale['cgst'] ?? 0)).toDouble(),
        grandTotal: (sale['grand_total'] ?? 0).toDouble(),
        company: {
          'name': 'Valampure Elastics',
          'gstin': '33AACFV9863A2Z6',
          'address1': 'S.F. No. 96, 1A1C, New Pillayar Nagar, Pudhuroad Pirivu,',
          'address2': 'Pollikalipalayam (P.O), Tiruppur - 641 665, Mobile: 9600911091',
          'stateCode': '33',
          'areaCode': '124'
        },
        bank: {
          'bankName': 'ICICI BANK',
          'accountNo': '410505001141',
          'ifsc': 'ICIC0004105',
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Print failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Sales Invoice Detail",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.print),
              onPressed: () async {
                await _printInvoice();
              }),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _saleDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
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
              Expanded(child: _readonlyField("Inv No", sale['invoice_no'])),
              const SizedBox(width: 5),
              Expanded(child: _readonlyField("Order No", sale['order_no'] ?? "-")),
              const SizedBox(width: 5),
              Expanded(child: _readonlyField("Date", sale['invoice_date'] ?? "")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadonlyItemsTable(List items) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FixedColumnWidth(35),
        2: FixedColumnWidth(50),
        3: FixedColumnWidth(60),
        4: FixedColumnWidth(45),
        5: FixedColumnWidth(70),
      },
      border: TableBorder.all(color: Colors.black12),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey[100]),
          children: [
            _th("Item"),
            _th("Box"),
            _th("Mts"),
            _th("Qty"),
            _th("Rate"),
            _th("Amt"),
          ],
        ),
        ...items.map((item) {
          final amount = (item['amount'] ?? 0).toDouble();

          return TableRow(
            children: [
              _tdText(
                "${item['size']} MM ${item['description']}".toUpperCase(),
                align: TextAlign.left,
              ),
              _tdText(item['boxes'].toString()),
              _tdText(item['mts_count']?.toString() ?? "0.0"),
              _tdText(
                item['total_qty'].toString(),
                isBold: true,
                color: Colors.blueGrey,
              ),
              _tdText(item['rate'].toString()),
              _tdText(amount.toStringAsFixed(2), isBold: true),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSummarySection(Map<String, dynamic> sale) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          _rowVal("Taxable Value", sale['taxable_value']),
          if (sale['sgst'] != null && sale['sgst'] > 0) ...[
            _rowVal("SGST (2.5%)", sale['sgst']),
            _rowVal("CGST (2.5%)", sale['cgst']),
          ],
          const Divider(height: 20),
          _rowVal("GRAND TOTAL", sale['grand_total'], isBold: true),
        ],
      ),
    );
  }

  Widget _readonlyField(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _th(String label) => Padding(
    padding: const EdgeInsets.all(8),
    child: Text(label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9)),
  );

  Widget _tdText(String val,
      {bool isBold = false,
        Color? color,
        TextAlign align = TextAlign.right}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Text(
          val,
          style: TextStyle(
              fontSize: 9,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color),
          textAlign: align,
        ),
      );

  Widget _rowVal(String label, dynamic val, {bool isBold = false}) {
    final num value = (val ?? 0) as num;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 16 : 14)),
          Text("₹ ${value.toStringAsFixed(2)}",
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
    child: Row(
      children: [
        const Icon(Icons.list_alt, size: 16, color: Colors.grey),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 11)),
      ],
    ),
  );

  Widget _buildStatusFooter() {
    return Container(
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
  }
}