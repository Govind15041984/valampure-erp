import 'dart:typed_data'; // For Web/Mobile compatible bytes
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:valampure_app/api/profiles_api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  Map<String, dynamic> _profileData = {};

  // PLATFORM AWARE IMAGE HANDLING
  Uint8List? _selectedImageBytes;
  String? _imageExtension;

  final ImagePicker _picker = ImagePicker();

  // Controllers
  final TextEditingController _ownerController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _addr1Controller = TextEditingController();
  final TextEditingController _addrController = TextEditingController();
  final TextEditingController _stateCodeController = TextEditingController();
  final TextEditingController _areaCodeController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accNoController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await ProfilesApi.getProfile();
      setState(() {
        _profileData = data;
        _populateControllers(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Error fetching profile: $e", Colors.red);
    }
  }

  void _populateControllers(Map<String, dynamic> data) {
    _ownerController.text = data['owner_name'] ?? '';
    _companyController.text = data['company_name'] ?? '';
    _gstinController.text = data['gstin'] ?? '';
    _addr1Controller.text = data['address1'] ?? '';
    _addrController.text = data['address'] ?? '';
    _stateCodeController.text = data['state_code'] ?? '33';
    _areaCodeController.text = data['area_code'] ?? '';
    _bankNameController.text = data['bank_name'] ?? '';
    _accNoController.text = data['account_no'] ?? '';
    _ifscController.text = data['ifsc_code'] ?? '';
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Optimize size
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _imageExtension = image.name.split('.').last.toLowerCase();
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      String? logoTempName;

      // STEP 1: If user picked a new image, upload to MinIO first
      if (_selectedImageBytes != null) {
        // A. Get the presigned URL from FastAPI
        final uploadInfo = await ProfilesApi.getLogoUploadUrl();

        // B. Upload raw bytes directly to MinIO
        await ProfilesApi.uploadToMinio(
          uploadInfo['upload_url'],
          _selectedImageBytes!,
        );

        // C. Keep the temporary object name for the final profile update
        logoTempName = uploadInfo['object_name'];
      }

      // STEP 2: Prepare the data for FastAPI update
      final Map<String, dynamic> updateData = {
        "owner_name": _ownerController.text,
        "company_name": _companyController.text,
        "gstin": _gstinController.text,
        "address1": _addr1Controller.text,
        "address": _addrController.text,
        "state_code": _stateCodeController.text,
        "area_code": _areaCodeController.text,
        "bank_name": _bankNameController.text,
        "account_no": _accNoController.text,
        "ifsc_code": _ifscController.text,
        "logo_temp_name":
            logoTempName, // Send the temp name to trigger finalize logic
      };

      // STEP 3: Send the update request
      bool success = await ProfilesApi.updateProfile(updateData);

      if (success) {
        // Refresh profile to get the final canonical logo_url from DB
        await _fetchProfile();
        setState(() {
          _isEditing = false;
          _selectedImageBytes = null; // Clear local preview
        });
        _showSnackBar("Profile updated successfully!", Colors.green);
      }
    } catch (e) {
      _showSnackBar("Update failed: $e", Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Company Profile",
          style: TextStyle(
            color: Color(0xFF37474F),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              if (_isEditing) _populateControllers(_profileData);
              setState(() {
                _isEditing = !_isEditing;
                _selectedImageBytes = null;
              });
            },
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit,
              size: 18,
              color: Colors.blueGrey,
            ),
            label: Text(
              _isEditing ? "Cancel" : "Edit",
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildBrandingCard(),
              const SizedBox(height: 20),
              _buildSection("Business Identity", Icons.badge_outlined, [
                _displayOrInput(
                  "Owner Name",
                  _ownerController,
                  _profileData['owner_name'],
                ),
                _displayOrInput(
                  "Company Name",
                  _companyController,
                  _profileData['company_name'],
                ),
                _displayReadOnly(
                  "Mobile Number",
                  _profileData['mobile_number'],
                ),
                _displayReadOnly("User Role", _profileData['role']),
              ]),
              const SizedBox(height: 16),
              _buildSection("Tax & Address", Icons.location_on_outlined, [
                _displayOrInput(
                  "GSTIN",
                  _gstinController,
                  _profileData['gstin'],
                ),
                _displayOrInput(
                  "Address Line 1",
                  _addr1Controller,
                  _profileData['address1'],
                ),
                _displayOrInput(
                  "Address Line 2",
                  _addrController,
                  _profileData['address'],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _displayOrInput(
                        "State Code",
                        _stateCodeController,
                        _profileData['state_code'],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _displayOrInput(
                        "Area Code",
                        _areaCodeController,
                        _profileData['area_code'],
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 16),
              _buildSection("Banking Details", Icons.account_balance_outlined, [
                _displayOrInput(
                  "Bank Name",
                  _bankNameController,
                  _profileData['bank_name'],
                ),
                _displayOrInput(
                  "Account Number",
                  _accNoController,
                  _profileData['account_no'],
                ),
                _displayOrInput(
                  "IFSC Code",
                  _ifscController,
                  _profileData['ifsc_code'],
                ),
              ]),
              if (_isEditing) ...[
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF37474F),
                    minimumSize: const Size(double.infinity, 54),
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
                          "SAVE CHANGES",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isEditing ? _pickImage : null,
            child: Stack(
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    image: _selectedImageBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_selectedImageBytes!),
                            fit: BoxFit.cover,
                          )
                        : (_profileData['logo_url'] != null
                              ? DecorationImage(
                                  image: NetworkImage(_profileData['logo_url']),
                                  fit: BoxFit.cover,
                                )
                              : null),
                  ),
                  child:
                      (_selectedImageBytes == null &&
                          _profileData['logo_url'] == null)
                      ? const Icon(Icons.business, size: 40, color: Colors.grey)
                      : null,
                ),
                if (_isEditing)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFF37474F),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Company Branding",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEditing
                      ? "Click the box to upload logo"
                      : "Official business logo",
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets remain largely the same ---
  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF37474F)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF37474F),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _displayOrInput(
    String label,
    TextEditingController controller,
    dynamic value,
  ) {
    if (!_isEditing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            Flexible(
              child: Text(
                value?.toString() ?? "-",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _displayReadOnly(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value?.toString() ?? "-",
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
