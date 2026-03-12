import 'package:flutter/material.dart';
import '../../../api/manufacturing_api.dart';
import '../../../theme/app_colors.dart';
// USE: To ensure we use the global font styles defined in your theme
import '../../../theme/app_colors.dart';

class ProductionLogScreen extends StatefulWidget {
  const ProductionLogScreen({super.key});

  @override
  State<ProductionLogScreen> createState() => _ProductionLogScreenState();
}

class _ProductionLogScreenState extends State<ProductionLogScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _yarnController = TextEditingController();
  final TextEditingController _rubberController = TextEditingController();
  final TextEditingController _descController = TextEditingController(
    text: "White Elastic",
  );
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _boxesController = TextEditingController();
  final TextEditingController _mtsController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> productionData = {
        "description": _descController.text.trim(),
        "size_mm": _sizeController.text.trim().toUpperCase(),
        "boxes": int.tryParse(_boxesController.text) ?? 0,
        "total_mts": double.tryParse(_mtsController.text) ?? 0.0,
        "yarn_used_kg": double.tryParse(_yarnController.text) ?? 0.0,
        "rubber_used_kg": double.tryParse(_rubberController.text) ?? 0.0,
      };

      bool success = await ManufacturingApi.logProduction(productionData);

      if (success && mounted) {
        // 1. Show a Themed Success SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text("Production Saved & Stock Updated!"),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // 2. Small delay so the user sees the message before the screen closes
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save: ${e.toString()}"),
            backgroundColor: AppColors.error, // Using your theme color
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // USE: Accessing the global theme to keep text consistent
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background, // Uses your themed background
      appBar: AppBar(
        title: const Text("Production Entry"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader("1. MATERIAL INPUTS", textTheme),
              Row(
                children: [
                  Expanded(
                    child: _buildThemedField(
                      _yarnController,
                      "Yarn (KG)",
                      Icons.scale,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildThemedField(
                      _rubberController,
                      "Rubber (KG)",
                      Icons.opacity,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              _sectionHeader("2. PRODUCT SPECIFICATION", textTheme),
              _buildThemedField(
                _descController,
                "Quality / Item Name",
                Icons.edit,
              ),
              const SizedBox(height: 16),
              _buildThemedField(
                _sizeController,
                "Size (e.g., 8.5 MM)",
                Icons.straighten,
              ),

              const SizedBox(height: 32),
              _sectionHeader("3. PRODUCTION OUTPUT", textTheme),
              Row(
                children: [
                  Expanded(
                    child: _buildThemedField(
                      _boxesController,
                      "Total Boxes",
                      Icons.inventory_2,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildThemedField(
                      _mtsController,
                      "Total Meters",
                      Icons.route,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS USING APP_THEME & APP_COLORS ---

  Widget _sectionHeader(String title, TextTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: theme.titleSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildThemedField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.6)),
        filled: true,
        fillColor: Colors.white,
        // Uses the border style likely defined in your AppTheme
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.1)),
        ),
      ),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitData,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "SAVE PRODUCTION",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
