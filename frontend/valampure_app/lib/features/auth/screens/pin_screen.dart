import 'package:flutter/material.dart';
import 'package:valampure_app/features/auth/screens/signup_screen.dart';
import '../../../api/profiles_api.dart';
import '../../../theme/app_colors.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class PinScreen extends StatefulWidget {
  final String mobileNumber;

  const PinScreen({super.key, required this.mobileNumber});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;

  // USE: Authenticates the user using the ProfilesApi.
  // WHEN: Triggered when the user clicks 'LOGIN'.
  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      bool success = await ProfilesApi.login(
        widget.mobileNumber,
        _pinController.text,
      );
      if (success && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Check if the error message contains 'not found' (from backend 404)
      if (e.toString().contains("not found")) {
        _showSignupDialog();
      } else {
        _showError(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSignupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Business?"),
        content: Text(
          "No account found for ${widget.mobileNumber}. Would you like to register Valampure ERP?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SignupScreen(mobile: widget.mobileNumber),
                ),
              );
            },
            child: const Text("REGISTER"),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                "Verify PIN for ${widget.mobileNumber}",
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _pinController,
                obscureText: true, // Hides the PIN as they type
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 16),
                decoration: const InputDecoration(
                  hintText: "0000",
                  counterText: "", // Hides the character counter
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 32),

              _isLoading
                  ? const CircularProgressIndicator(color: AppColors.accent)
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          "LOGIN",
                          style: TextStyle(
                            color: Colors.white,
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
