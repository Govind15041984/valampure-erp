import 'package:flutter/material.dart';
import '../../../api/staff_api.dart';

class AddEmployeeSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const AddEmployeeSheet({super.key, required this.onSuccess});

  @override
  State<AddEmployeeSheet> createState() => _AddEmployeeSheetState();
}

class _AddEmployeeSheetState extends State<AddEmployeeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rateController = TextEditingController();

  String _selectedDesignation = 'Operator';
  bool _isSaving = false;

  final List<String> _designations = [
    'Master',
    'Operator',
    'Helper',
    'Tailor',
    'Checker',
    'Ironing',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  // LOGIC REMAINS EXACTLY THE SAME
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final employeeData = {
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "designation": _selectedDesignation,
        "current_shift_rate": double.tryParse(_rateController.text) ?? 0.0,
        "joining_date": DateTime.now().toIso8601String().split('T')[0],
      };
      final success = await StaffApi.createEmployee(employeeData);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Employee added successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          widget.onSuccess();
          Navigator.pop(context);
        }
      } else {
        throw Exception("Backend returned failure");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // REUSABLE MODERN DECORATION
    InputDecoration modernInput(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
      labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14),
      floatingLabelStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // BOTTOM SHEET HANDLE
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                children: [
                  const Icon(Icons.person_add_rounded, color: Colors.black87),
                  const SizedBox(width: 10),
                  const Text(
                    "New Staff Registration",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey.shade400),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // NAME
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: modernInput("Full Name", Icons.badge_outlined),
                validator: (v) => v!.isEmpty ? "Enter full name" : null,
              ),
              const SizedBox(height: 16),

              // PHONE
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: modernInput(
                  "Phone (Optional)",
                  Icons.phone_android,
                ),
              ),
              const SizedBox(height: 16),

              // DESIGNATION
              DropdownButtonFormField<String>(
                value: _selectedDesignation,
                icon: const Icon(
                  Icons.arrow_drop_down_circle_outlined,
                  size: 20,
                ),
                decoration: modernInput("Designation", Icons.work_outline),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                items: _designations
                    .map(
                      (val) => DropdownMenuItem(value: val, child: Text(val)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedDesignation = val!),
              ),
              const SizedBox(height: 16),

              // SHIFT RATE
              TextFormField(
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: modernInput(
                  "Base Shift Rate (₹)",
                  Icons.currency_rupee_rounded,
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Enter rate" : null,
              ),
              const SizedBox(height: 32),

              // SAVE BUTTON (Professional Grey)
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.grey.shade900, // Matches Login "Continue"
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                          "SAVE EMPLOYEE",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
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
