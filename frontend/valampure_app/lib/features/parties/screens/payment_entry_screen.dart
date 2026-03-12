import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../api/client_api.dart';
import '../../../api/payments_api.dart'; // Ensure this points to your ApiClient location

class PaymentEntryScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  final String partnerType; // "SUPPLIER" or "BUYER"

  const PaymentEntryScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    required this.partnerType,
  });

  @override
  State<PaymentEntryScreen> createState() => _PaymentEntryScreenState();
}

class _PaymentEntryScreenState extends State<PaymentEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  final _refController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _paymentMode = "Cash";
  bool _isSaving = false;

  // Options for Payment Mode mapping to your SQL schema
  final List<String> _modes = ["Cash", "UPI", "Bank Transfer", "Cheque"];

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final Map<String, dynamic> paymentData = {
      "partner_id": widget.partnerId,
      "amount": double.parse(_amountController.text),
      "payment_mode": _paymentMode,
      "payment_type": widget.partnerType == "SUPPLIER" ? "PAYMENT" : "RECEIPT",
      "reference_no": _refController.text,
      "remarks": _remarksController.text,
      "payment_date": DateFormat('yyyy-MM-dd').format(_selectedDate),
    };

    // Using the new PaymentsApi file
    bool success = await PaymentsApi.createPayment(paymentData);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Entry Saved Successfully")),
        );
        Navigator.pop(
          context,
          true,
        ); // Returns true to trigger the Ledger refresh
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to save entry. Check Connection."),
          ),
        );
      }
    }

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.partnerType == "SUPPLIER"
        ? Colors.green
        : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Record ${widget.partnerType == "SUPPLIER" ? 'Payment' : 'Receipt'}",
        ),
        backgroundColor: themeColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Info
              Text(
                "Partner: ${widget.partnerName}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Date Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Date"),
                subtitle: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const Divider(),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount (₹)",
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? "Enter amount" : null,
              ),
              const SizedBox(height: 16),

              // Payment Mode
              DropdownButtonFormField<String>(
                value: _paymentMode,
                decoration: const InputDecoration(
                  labelText: "Payment Mode",
                  border: OutlineInputBorder(),
                ),
                items: _modes.map((mode) {
                  return DropdownMenuItem(value: mode, child: Text(mode));
                }).toList(),
                onChanged: (val) => setState(() => _paymentMode = val!),
              ),
              const SizedBox(height: 16),

              // Reference Number
              TextFormField(
                controller: _refController,
                decoration: const InputDecoration(
                  labelText: "Reference No (UPI ID / Cheque No)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Remarks
              TextFormField(
                controller: _remarksController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Remarks",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "SAVE ${widget.partnerType == "SUPPLIER" ? 'PAYMENT' : 'RECEIPT'}",
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
