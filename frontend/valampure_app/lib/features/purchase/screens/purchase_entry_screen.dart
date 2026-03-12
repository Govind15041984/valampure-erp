import 'dart:typed_data'; // Use this for bytes
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../api/partners_api.dart';
import '../../../api/purchase_api.dart';

class PurchaseEntryScreen extends StatefulWidget {
  const PurchaseEntryScreen({super.key});

  @override
  State<PurchaseEntryScreen> createState() => _PurchaseEntryScreenState();
}

class _PurchaseEntryScreenState extends State<PurchaseEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _billNoController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _finalAmountController = TextEditingController();

  // State Variables
  String? _selectedPartnerId;
  List<dynamic> _partners = [];
  String _selectedCategory = "Yarn";
  String _uom = "Kgs";
  bool _isGst = false;

  // CROSS-PLATFORM IMAGE HANDLING
  Uint8List? _billBytes; // Stores the image data
  bool _isSaving = false;

  final List<String> _categories = [
    "Yarn",
    "Rubber",
    "Boxes",
    "Labels",
    "Others",
  ];

  @override
  void initState() {
    super.initState();
    _loadPartners();
    _qtyController.addListener(_calculateTotal);
    _rateController.addListener(_calculateTotal);
  }

  void _loadPartners() async {
    final data = await PartnersApi.getPartners("SUPPLIER");
    setState(() => _partners = data);
  }

  void _calculateTotal() {
    double qty = double.tryParse(_qtyController.text) ?? 0;
    double rate = double.tryParse(_rateController.text) ?? 0;
    double subTotal = qty * rate;
    double total = _isGst ? subTotal * 1.05 : subTotal;
    _finalAmountController.text = total.toStringAsFixed(2);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      // Read bytes immediately to be Web-compatible
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _billBytes = bytes;
      });
    }
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate() || _selectedPartnerId == null)
      return;

    setState(() => _isSaving = true);
    try {
      String? tempObjectName;

      // 1. Handle MinIO Upload using Bytes
      if (_billBytes != null) {
        final presign = await PurchaseApi.getPresignedUrl("jpg");
        // We pass _billBytes directly to our new API method
        await PurchaseApi.uploadToMinio(presign['upload_url'], _billBytes!);
        tempObjectName = presign['object_name'];
      }

      // 2. Prepare Data
      final purchaseData = {
        "partner_id": _selectedPartnerId,
        "bill_number": _billNoController.text,
        "bill_date": DateTime.now().toIso8601String().split('T')[0],
        "is_gst": _isGst,
        "total_sub_total":
            double.parse(_qtyController.text) *
            double.parse(_rateController.text),
        "total_tax_amount": _isGst
            ? (double.parse(_qtyController.text) *
                  double.parse(_rateController.text) *
                  0.05)
            : 0,
        "final_amount": double.parse(_finalAmountController.text),
        "temp_object_name": tempObjectName,
        "items": [
          {
            "category": _selectedCategory,
            "quantity": double.parse(_qtyController.text),
            "uom": _uom,
            "rate": double.parse(_rateController.text),
            "line_total":
                double.parse(_qtyController.text) *
                double.parse(_rateController.text),
          },
        ],
      };

      // 3. Save to Postgres
      final success = await PurchaseApi.createPurchase(purchaseData);
      if (success) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Purchase")),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Select Supplier",
                      border: OutlineInputBorder(),
                    ),
                    items: _partners
                        .map(
                          (p) => DropdownMenuItem<String>(
                            value: p['id'],
                            child: Text(p['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedPartnerId = val),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Category",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8,
                    children: _categories
                        .map(
                          (cat) => ChoiceChip(
                            label: Text(cat),
                            selected: _selectedCategory == cat,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = cat;
                                _uom = (cat == "Boxes" || cat == "Labels")
                                    ? "Pcs"
                                    : "Kgs";
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _billNoController,
                          decoration: const InputDecoration(
                            labelText: "Bill No",
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(
                          _billBytes == null
                              ? Icons.camera_alt
                              : Icons.check_circle,
                        ),
                        label: Text(
                          _billBytes == null ? "Snap Bill" : "Captured",
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _billBytes != null
                              ? Colors.green.shade100
                              : null,
                        ),
                      ),
                    ],
                  ),
                  // PREVIEW IMAGE (Optional but helpful)
                  if (_billBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Image.memory(
                        _billBytes!,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: "Qty ($_uom)"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _rateController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Rate"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text("Include 5% GST"),
                          value: _isGst,
                          onChanged: (val) {
                            setState(() => _isGst = val);
                            _calculateTotal();
                          },
                        ),
                        TextFormField(
                          controller: _finalAmountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          decoration: const InputDecoration(
                            labelText: "Final Bill Amount (Editable)",
                            prefixText: "₹",
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _savePurchase,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text("SAVE PURCHASE ENTRY"),
                  ),
                ],
              ),
            ),
    );
  }
}
