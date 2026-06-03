import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/seva_widgets.dart';
import '../../core/storage/local_storage_service.dart';
import '../../services/dependency_injection.dart';
import '../../utils/app_logger.dart';
import '../../core/api/api_client.dart';
import '../../models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _countryController;
  late TextEditingController _timezoneController;
  late TextEditingController _languageController;

  bool _loading = false;
  String? _nameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    final storage = locator<LocalStorageService>();
    _nameController = TextEditingController(text: storage.getUserName() ?? '');
    _phoneController = TextEditingController(text: storage.getUserPhone() ?? '');
    _countryController = TextEditingController(text: storage.getUserCountry() ?? '');
    _timezoneController = TextEditingController(text: storage.getUserTimezone() ?? '');
    _languageController = TextEditingController(text: storage.getUserLanguage() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _timezoneController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      _nameError = null;
      _phoneError = null;
    });

    final nameVal = _nameController.text.trim();
    if (nameVal.isEmpty) {
      setState(() => _nameError = 'Name cannot be empty');
      isValid = false;
    }

    final phoneVal = _phoneController.text.trim();
    if (phoneVal.isEmpty) {
      setState(() => _phoneError = 'Phone number cannot be empty');
      isValid = false;
    } else {
      // Must contain valid phone format (e.g. at least 6 digits, digits/pluses/dashes)
      final phoneRegex = RegExp(r'^\+?[0-9\s\-]{6,15}$');
      if (!phoneRegex.hasMatch(phoneVal)) {
        setState(() => _phoneError = 'Please enter a valid phone number');
        isValid = false;
      }
    }

    return isValid;
  }

  Future<void> _saveProfile() async {
    if (!_validateInputs()) return;

    setState(() => _loading = true);
    AppLogger.i('Update profile started');

    final payload = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'country': _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : null,
      'timezone': _timezoneController.text.trim().isNotEmpty ? _timezoneController.text.trim() : null,
      'language': _languageController.text.trim().isNotEmpty ? _languageController.text.trim() : null,
    };

    AppLogger.i('Payload sent: $payload');

    try {
      final result = await locator<ApiClient>().put('auth/me', body: payload);

      if (result.success && result.data != null) {
        final updatedUser = UserModel.fromJson(result.data as Map<String, dynamic>);
        
        final storage = locator<LocalStorageService>();
        await storage.saveUserId(updatedUser.id);
        await storage.saveUserName(updatedUser.name);
        await storage.saveUserEmail(updatedUser.email);
        await storage.saveUserRole(updatedUser.role);
        await storage.saveUserPhone(updatedUser.phone);
        await storage.saveUserAvatar(updatedUser.avatar);
        await storage.saveUserCountry(updatedUser.country);
        await storage.saveUserTimezone(updatedUser.timezone);
        await storage.saveUserLanguage(updatedUser.language);
        await storage.saveUserStatus(updatedUser.status);

        AppLogger.i('Profile updated successfully');
        AppLogger.i('Cache updated');
        AppLogger.i('Profile refresh completed');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: SevaColors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true); // Returns true to trigger state refresh on pop
        }
      } else {
        AppLogger.e('Update failed: ${result.errorMessage}');
        _showError(result.errorMessage);
      }
    } catch (e, stack) {
      AppLogger.e('Update failed with exception', e, stack);
      String displayError = 'Something went wrong. Please try again.';
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        displayError = 'Unable to connect. Please check internet connection.';
      }
      _showError(displayError);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: SevaColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Details',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: SevaColors.textPrimary),
              ),
              const SizedBox(height: 12),
              SevaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Field
                    _buildFieldLabel('Full Name *'),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                        errorText: _nameError,
                      ),
                      enabled: !_loading,
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    _buildFieldLabel('Phone Number *'),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Enter phone number',
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        errorText: _phoneError,
                      ),
                      enabled: !_loading,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Regional Settings',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: SevaColors.textPrimary),
              ),
              const SizedBox(height: 12),
              SevaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country Field
                    _buildFieldLabel('Country (Optional)'),
                    TextField(
                      controller: _countryController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. India',
                        prefixIcon: Icon(Icons.public, size: 20),
                      ),
                      enabled: !_loading,
                    ),
                    const SizedBox(height: 16),

                    // Timezone Field
                    _buildFieldLabel('Timezone (Optional)'),
                    TextField(
                      controller: _timezoneController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Asia/Kolkata',
                        prefixIcon: Icon(Icons.schedule, size: 20),
                      ),
                      enabled: !_loading,
                    ),
                    const SizedBox(height: 16),

                    // Language Field
                    _buildFieldLabel('Language (Optional)'),
                    TextField(
                      controller: _languageController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. en',
                        prefixIcon: Icon(Icons.translate, size: 20),
                      ),
                      enabled: !_loading,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _loading ? null : SevaColors.sevaGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _loading
                        ? []
                        : [
                            BoxShadow(
                              color: SevaColors.primary.withAlpha(76),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                  ),
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            'Save Changes',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
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

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: SevaColors.textSecondary),
      ),
    );
  }
}
