import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:valampure_app/api/manufacturing_api.dart';
import 'package:valampure_app/features/sales/screens/sales_list_screen.dart';
import '../../../api/partners_api.dart';
import '../../../api/profiles_api.dart';
import '../../../api/sales_api.dart';
import '../../../core/pdf_service.dart';
import '../../../theme/app_colors.dart';

// 1. DATA MODEL
class SalesItemRow {
  String description = "";
  String sizeMm = "";
  int boxes = 0;
  double mts = 0.0;
  double rate = 0.0;
}

class SalesEntryScreen extends StatefulWidget {
  const SalesEntryScreen({super.key});

  @override
  _SalesEntryScreenState createState() => _SalesEntryScreenState();
}

class _SalesEntryScreenState extends State<SalesEntryScreen> {
  Map<String, dynamic>? _myProfile;
  List<Map<String, dynamic>> _buyers = [];
  Map<String, dynamic>? _selectedBuyer;
  bool _isSaving = false;

  // NEW: State for tracking saved invoice
  String? _savedSaleId;
  bool _isSuccessfullySaved = false;

  final TextEditingController _invoiceNoController = TextEditingController();
  final TextEditingController _orderNoController = TextEditingController();
  DateTime _invoiceDate = DateTime.now();
  bool _isGstInvoice = true;

  final List<SalesItemRow> _items = [SalesItemRow()];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  List<Map<String, dynamic>> _stockItems = [];
  List<String> _displaySuggestions = [];

  Future<void> _loadInitialData() async {
    try {
      final profile = await ProfilesApi.getProfile();
      final List<dynamic> buyerResponse = await PartnersApi.getPartners(
        'BUYER',
      );
      final stockData = await ManufacturingApi.getCurrentStock();
      final nextInv = await SalesApi.getNextInvoiceNumber();

      setState(() {
        _myProfile = profile;
        _buyers = List<Map<String, dynamic>>.from(buyerResponse);
        _stockItems = List<Map<String, dynamic>>.from(stockData);
        _displaySuggestions = _stockItems
            .map((s) => "${s['size_mm']} MM ${s['description']}".toUpperCase())
            .toList();

        if (nextInv.isNotEmpty) {
          _invoiceNoController.text = nextInv;
        }
      });
    } catch (e) {
      debugPrint("Data Load Error: $e");
    }
  }

  // MATH LOGIC
  int get _totalBoxes => _items.fold(0, (sum, item) => sum + item.boxes);
  double get _subTotal => _items.fold(
    0.0,
    (sum, item) => sum + (item.boxes * item.mts * item.rate),
  );
  double get _tax => _isGstInvoice ? (_subTotal * 0.05) : 0.0;
  double get _grandTotal => (_subTotal + _tax).roundToDouble();

  // PREVIEW MODAL
  void _showPreviewModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Invoice Preview",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _previewText(
                        "Consignee",
                        _selectedBuyer?['name'] ?? "Not Selected",
                      ),
                      _previewText("Invoice No", _invoiceNoController.text),
                      _previewText(
                        "Date",
                        DateFormat('dd-MM-yyyy').format(_invoiceDate),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "ITEMS",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const Divider(),
                      ..._items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "${item.sizeMm} MM ${item.description}",
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Text(
                                "${item.boxes * item.mts} Mts x ₹${item.rate}",
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      _rowVal(
                        "Total Boxes",
                        _totalBoxes.toDouble(),
                        isCurrency: false,
                      ),
                      _rowVal("Taxable Amount", _subTotal),
                      if (_isGstInvoice) _rowVal("GST (5%)", _tax),
                      const Divider(),
                      _rowVal("GRAND TOTAL", _grandTotal, isBold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // DYNAMIC ACTION BUTTONS
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isSuccessfullySaved
                    ? Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                // 1. Fetch official record by ID
                                final saleData = await SalesApi.getSaleDetails(
                                  _savedSaleId!,
                                );
                                // 2. Generate PDF using official record
                                await _printInvoice(saleData);
                              },
                              icon: const Icon(Icons.print),
                              label: const Text("PRINT INVOICE"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () {
                              Navigator.pop(context); // Close modal
                              Navigator.pop(context); // Exit entry screen
                            },
                            child: const Text("DONE"),
                          ),
                        ],
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await _saveInvoiceToDatabase();
                          setModalState(() {}); // Refresh buttons inside modal
                        },
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "CONFIRM & SAVE INVOICE",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveInvoiceToDatabase() async {
    if (_selectedBuyer == null || _items.isEmpty || _myProfile == null) return;

    setState(() => _isSaving = true);

    try {
      final List<Map<String, dynamic>> details = _items.map((item) {
        double totalQty = item.boxes * item.mts;
        return {
          "description": item.description,
          "size_mm": item.sizeMm,
          "hsn_code": "60",
          "box_count": item.boxes,
          "mts_count": item.mts,
          "total_qty": totalQty,
          "rate": item.rate,
          "line_total": totalQty * item.rate,
        };
      }).toList();

      final Map<String, dynamic> payload = {
        "profile_id": _myProfile!['id'],
        "partner_id": _selectedBuyer!['id'],
        "invoice_number": _invoiceNoController.text,
        "invoice_date": _invoiceDate.toIso8601String().split('T')[0],
        "is_gst": _isGstInvoice,
        "total_taxable_value": _subTotal,
        "cgst_amount": _isGstInvoice ? (_tax / 2) : 0,
        "sgst_amount": _isGstInvoice ? (_tax / 2) : 0,
        "igst_amount": 0,
        "round_off": 0,
        "grand_total": _grandTotal,
        "items": details,
      };

      // Ensure your API returns the Map with {'id': ...}
      final dynamic response = await SalesApi.createInvoice(payload);

      if (response != null && response['id'] != null) {
        setState(() {
          _savedSaleId = response['id'].toString();
          _isSuccessfullySaved = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Invoice Recorded Successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Save Error: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // UNIFIED PRINT HELPER (Mirroring SalesDetailView logic)
  Future<void> _printInvoice(Map<String, dynamic> sale) async {
    if (_myProfile == null) return;

    final List<Map<String, dynamic>> invoiceItems =
        (sale['items'] as List<dynamic>? ?? []).map((e) {
          final size = e['size'] ?? e['size_mm'] ?? '';
          final desc = e['description'] ?? '';
          return {
            'description': "$size MM $desc".toUpperCase(),
            'hsn': e['hsn'] ?? e['hsn_code'] ?? '60',
            'boxes': (e['boxes'] ?? e['box_count'] ?? 0).toDouble(),
            'mts': (e['mts'] ?? e['mts_count'] ?? 0.0).toDouble(),
            'rate': (e['rate'] ?? 0.0).toDouble(),
          };
        }).toList();

    await PdfService.generateAndPrintInvoice(
      invoiceNo: sale['invoice_no'] ?? '',
      orderNo: sale['order_no'] ?? '-',
      buyerName: sale['partner_name'] ?? '',
      buyerGST: sale['partner_gstin'] ?? 'N/A',
      buyerState: 'Tamil Nadu',
      buyerStateCode: '33',
      items: invoiceItems,
      subTotal: (sale['taxable_value'] ?? 0).toDouble(),
      tax: ((sale['sgst'] ?? 0) + (sale['cgst'] ?? 0)).toDouble(),
      grandTotal: (sale['grand_total'] ?? 0).toDouble(),
      company: {
        'name': _myProfile!['company_name'] ?? '',
        'gstin': _myProfile!['gstin'] ?? '',
        'address1': _myProfile!['address1'] ?? '',
        'address2': '${_myProfile!['address'] ?? ''}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "New Sales Invoice",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "View Sales History",
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SalesListScreen()),
            ),
          ),
          Switch(
            value: _isGstInvoice,
            activeThumbColor: AppColors.accent,
            onChanged: (val) => setState(() => _isGstInvoice = val),
          ),
        ],
      ),
      body: _myProfile == null || _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderSection(),
                  _buildSectionLabel("ITEM DETAILS"),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildItemsTable(),
                  ),
                  _buildAddRowAction(),
                  const SizedBox(height: 20),
                  _buildSummarySection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildItemsTable() {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FixedColumnWidth(35),
        2: FixedColumnWidth(50),
        3: FixedColumnWidth(60),
        4: FixedColumnWidth(45),
        5: FixedColumnWidth(70),
        6: FixedColumnWidth(30),
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
            _th(""),
          ],
        ),
        ..._items.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          double totalQty = item.boxes * item.mts.toDouble();
          double totalAmt = totalQty * item.rate;

          return TableRow(
            children: [
              Autocomplete<String>(
                optionsBuilder: (textValue) => textValue.text.isEmpty
                    ? const Iterable<String>.empty()
                    : _displaySuggestions.where(
                        (s) => s.contains(textValue.text.toUpperCase()),
                      ),
                onSelected: (selection) {
                  final matchedStock = _stockItems.firstWhere(
                    (s) =>
                        "${s['size_mm']} MM ${s['description']}"
                            .toUpperCase() ==
                        selection,
                    orElse: () => {},
                  );
                  if (matchedStock.isNotEmpty) {
                    setState(() {
                      item.description = matchedStock['description'] ?? "";
                      item.sizeMm = matchedStock['size_mm']?.toString() ?? "";
                    });
                  }
                },
                fieldViewBuilder: (context, controller, focus, onSubmitted) {
                  if (item.description.isNotEmpty && controller.text.isEmpty) {
                    controller.text = "${item.sizeMm} MM ${item.description}"
                        .toUpperCase();
                  }
                  return TextField(
                    controller: controller,
                    focusNode: focus,
                    style: const TextStyle(fontSize: 10),
                    decoration: const InputDecoration(
                      hintText: "Search size...",
                      contentPadding: EdgeInsets.all(8),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  );
                },
              ),
              _tdInput(
                hint: "0",
                onChanged: (v) =>
                    setState(() => item.boxes = int.tryParse(v) ?? 0),
                keyboard: TextInputType.number,
              ),
              _tdInput(
                hint: "0",
                onChanged: (v) =>
                    setState(() => item.mts = double.tryParse(v) ?? 0.0),
                keyboard: TextInputType.number,
              ),
              _tdText(
                totalQty.toStringAsFixed(0),
                isBold: true,
                color: Colors.blueGrey,
              ),
              _tdInput(
                hint: "0.0",
                onChanged: (v) =>
                    setState(() => item.rate = double.tryParse(v) ?? 0.0),
                keyboard: TextInputType.number,
              ),
              _tdText(totalAmt.toStringAsFixed(2), isBold: true),
              IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.remove_circle_outline,
                  size: 16,
                  color: Colors.red,
                ),
                onPressed: () => setState(() => _items.removeAt(idx)),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSummarySection() {
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
          _rowVal("Total Boxes", _totalBoxes.toDouble(), isCurrency: false),
          _rowVal("Taxable Value", _subTotal),
          if (_isGstInvoice) ...[
            _rowVal("SGST (2.5%)", _tax / 2),
            _rowVal("CGST (2.5%)", _tax / 2),
          ],
          const Divider(height: 20),
          _rowVal("GRAND TOTAL", _grandTotal, isBold: true),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _showPreviewModal,
              child: const Text(
                "GENERATE & PREVIEW",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // UI HELPERS
  Widget _previewText(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Text("$label: $val", style: const TextStyle(fontSize: 14)),
  );
  Widget _tdText(String val, {bool isBold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
    child: Text(
      val,
      style: TextStyle(
        fontSize: 10,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: color,
      ),
      textAlign: TextAlign.right,
    ),
  );
  Widget _rowVal(
    String label,
    double val, {
    bool isBold = false,
    bool isCurrency = true,
  }) {
    String display = isCurrency
        ? "₹ ${val.toStringAsFixed(2)}"
        : val.toInt().toString();
    return Row(
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
          display,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _th(String label) => Padding(
    padding: const EdgeInsets.all(8),
    child: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
    ),
  );
  Widget _tdInput({
    required Function(String) onChanged,
    String hint = "",
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      onChanged: onChanged,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.all(8),
        border: InputBorder.none,
        isDense: true,
        hintStyle: const TextStyle(fontSize: 10),
      ),
      style: const TextStyle(fontSize: 11),
    );
  }

  Widget _headerField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        fillColor: Colors.white,
        filled: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        border: const Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedBuyer,
            isExpanded: true,
            hint: const Text("Select Consignee (Buyer)"),
            decoration: const InputDecoration(
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
            ),
            items: _buyers
                .map(
                  (b) => DropdownMenuItem(
                    value: b,
                    child: Text(b['name'] ?? 'Unknown'),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() {
              _selectedBuyer = val;
              _isSuccessfullySaved = false;
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _headerField("Inv No", _invoiceNoController)),
              const SizedBox(width: 5),
              Expanded(child: _headerField("Order No", _orderNoController)),
              const SizedBox(width: 5),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Date",
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(10),
                    ),
                    child: Text(
                      DateFormat('dd-MM-yy').format(_invoiceDate),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
  Widget _buildAddRowAction() => TextButton.icon(
    onPressed: () => setState(() => _items.add(SalesItemRow())),
    icon: const Icon(Icons.add, size: 16),
    label: const Text("ADD LINE"),
  );
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _invoiceDate = picked);
  }
}
