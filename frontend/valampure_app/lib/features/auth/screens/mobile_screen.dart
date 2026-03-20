import 'package:flutter/material.dart';
import '../../../api/profiles_api.dart';
import '../../../theme/app_colors.dart';

class MobileScreen extends StatefulWidget {
  const MobileScreen({super.key});

  @override
  State<MobileScreen> createState() => _MobileScreenState();
}

class _MobileScreenState extends State<MobileScreen> {
  final TextEditingController _mobileController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleContinue() async {
    String mobile = _mobileController.text.trim();
    if (mobile.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid 10-digit mobile number"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool exists = await ProfilesApi.checkUser(mobile);
      if (mounted) {
        if (exists) {
          Navigator.pushNamed(context, '/pin', arguments: mobile);
        } else {
          Navigator.pushNamed(context, '/signup', arguments: mobile);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Connection Error: ${e.toString()}"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Standard white background
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LOGO + HEADER INLINE (Row layout)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/Valampure-logo.jpeg',
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    // Wrap the text in Expanded to prevent the "14 pixel overflow"
                    Expanded(
                      child: Text(
                        "Valampure Elastics",
                        overflow: TextOverflow
                            .ellipsis, // Adds "..." if it still doesn't fit
                        style: TextStyle(
                          fontSize: 32, // Slightly reduced to help fit better
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Valampure',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Enter your mobile number to continue",
                  textAlign: TextAlign.center, // Center the descriptive text
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 48), // Space before input
                // INPUT FIELD
                TextField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  enabled: !_isLoading,
                  maxLength: 10,
                  decoration: InputDecoration(
                    counterText: "",
                    labelText: "Mobile Number",
                    prefixText: "+91 ",
                    prefixStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),

                // GREY BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _handleContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors
                                .grey
                                .shade800, // Matching the requested grey
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "CONTINUE",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 40), // Space before version
                const Center(
                  child: Text(
                    "v1.0.26",
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
