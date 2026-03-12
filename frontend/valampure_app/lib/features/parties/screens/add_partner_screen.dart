import 'package:flutter/material.dart';
import '../../../api/partners_api.dart';

class AddPartnerScreen extends StatefulWidget {
  final String initialType; // "SUPPLIER" or "BUYER"
  const AddPartnerScreen({super.key, required this.initialType});

  @override
  State<AddPartnerScreen> createState() => _AddPartnerScreenState();
}

class _AddPartnerScreenState extends State<AddPartnerScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _gstController = TextEditingController();
  final _addressController = TextEditingController();
  final _openingBalController = TextEditingController(text: "0.0");

  String _selectedType = "";

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  Future<void> _savePartner() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final partnerData = {
      "name": _nameController.text.trim(),
      "partner_type": _selectedType,
      "mobile_number": _mobileController.text.trim(),
      "gstin": _gstController.text.trim().toUpperCase(),
      "address": _addressController.text.trim(),
      "opening_balance": double.tryParse(_openingBalController.text) ?? 0.0,
      "state_code": _gstController.text.length >= 2
          ? _gstController.text.substring(0, 2)
          : "33", // Default to TN if no GST
    };

    bool success = await PartnersApi.createPartner(partnerData);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$_selectedType Added Successfully!")),
      );
      Navigator.pop(context, true); // Return true to refresh the list
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add New $_selectedType")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Partner Type Selector
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: "SUPPLIER",
                          label: Text("Supplier"),
                          icon: Icon(Icons.local_shipping),
                        ),
                        ButtonSegment(
                          value: "BUYER",
                          label: Text("Buyer"),
                          icon: Icon(Icons.person),
                        ),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (val) =>
                          setState(() => _selectedType = val.first),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Business Name *",
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? "Enter business name" : null,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        labelText: "Mobile Number",
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _gstController,
                      decoration: const InputDecoration(
                        labelText: "GSTIN (15 Digits)",
                        prefixIcon: Icon(Icons.receipt_long),
                      ),
                      onChanged: (v) =>
                          setState(() {}), // Refresh to update state code logic
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: "Full Address",
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _openingBalController,
                      decoration: const InputDecoration(
                        labelText: "Opening Balance (if any)",
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _savePartner,
                        child: const Text(
                          "SAVE PARTNER",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
