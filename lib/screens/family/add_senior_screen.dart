import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import '../../widgets/seva_widgets.dart';
import '../../services/dependency_injection.dart';
import '../../repositories/senior_repository.dart';
import '../../utils/app_logger.dart';

class AddSeniorScreen extends StatefulWidget {
  const AddSeniorScreen({super.key});

  @override
  State<AddSeniorScreen> createState() => _AddSeniorScreenState();
}

class _AddSeniorScreenState extends State<AddSeniorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNotesController = TextEditingController();

  // Dropdown States
  String _gender = 'male';
  String _tier = 'Care Plus';
  String _status = 'stable';
  String _mobility = 'independent';

  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _conditionsController.dispose();
    _addressController.dispose();
    _emergencyNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
    });

    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final phone = _phoneController.text.trim();
    final city = _cityController.text.trim();
    final conditionsStr = _conditionsController.text.trim();
    final address = _addressController.text.trim();
    final emergencyNotes = _emergencyNotesController.text.trim();

    // Parse conditions
    List<String> conditions = [];
    if (conditionsStr.isNotEmpty) {
      conditions = conditionsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    final payload = <String, dynamic>{
      'name': name,
      'age': age,
      'gender': _gender,
      if (phone.isNotEmpty) 'phone': phone,
      if (city.isNotEmpty) 'city': city,
      'tier': _tier,
      'status': _status,
      'mobility': _mobility,
      'conditions': conditions,
      if (address.isNotEmpty) 'address': address,
      if (emergencyNotes.isNotEmpty) 'emergencyNotes': emergencyNotes,
    };

    AppLogger.i('Submitting add senior payload: $payload');

    try {
      final senior = await locator<SeniorRepository>().createSenior(data: payload);
      AppLogger.i('Senior created successfully: ${senior.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${senior.name} has been added successfully!'),
            backgroundColor: SevaColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // Pop back with success indicator
      }
    } catch (e, stack) {
      AppLogger.e('Create senior failed', e, stack);
      String errMsg = e.toString().replaceFirst('Exception: ', '');
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        errMsg = 'Unable to connect. Please check your internet connection.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: SevaColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SevaColors.background,
      appBar: AppBar(
        title: const Text('Add New Senior'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: Basic Info
                _buildHeaderSection('Personal Details', Icons.person),
                const SizedBox(height: 12),
                SevaCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        enabled: !_submitting,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: Icon(Icons.person_outline),
                          hintText: 'Enter full name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              enabled: !_submitting,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Age *',
                                prefixIcon: Icon(Icons.cake_outlined),
                                hintText: 'Age',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Required';
                                }
                                final age = int.tryParse(value);
                                if (age == null || age <= 0 || age > 120) {
                                  return 'Enter a valid age';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _gender,
                              decoration: const InputDecoration(
                                labelText: 'Gender *',
                                prefixIcon: Icon(Icons.wc_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'male', child: Text('Male')),
                                DropdownMenuItem(value: 'female', child: Text('Female')),
                                DropdownMenuItem(value: 'other', child: Text('Other')),
                              ],
                              onChanged: _submitting ? null : (val) {
                                if (val != null) {
                                  setState(() {
                                    _gender = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        enabled: !_submitting,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                          hintText: 'Enter phone number',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section 2: Care Configuration
                _buildHeaderSection('Care Configuration', Icons.settings_suggest),
                const SizedBox(height: 12),
                SevaCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _tier,
                        decoration: const InputDecoration(
                          labelText: 'Care Tier *',
                          prefixIcon: Icon(Icons.workspace_premium_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Care Lite', child: Text('Care Lite')),
                          DropdownMenuItem(value: 'Care Plus', child: Text('Care Plus')),
                          DropdownMenuItem(value: 'Care Premium', child: Text('Care Premium')),
                        ],
                        onChanged: _submitting ? null : (val) {
                          if (val != null) {
                            setState(() {
                              _tier = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Health Status *',
                          prefixIcon: Icon(Icons.health_and_safety_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'stable', child: Text('Stable')),
                          DropdownMenuItem(value: 'monitoring', child: Text('Monitoring')),
                          DropdownMenuItem(value: 'critical', child: Text('Critical')),
                        ],
                        onChanged: _submitting ? null : (val) {
                          if (val != null) {
                            setState(() {
                              _status = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _mobility,
                        decoration: const InputDecoration(
                          labelText: 'Mobility Status *',
                          prefixIcon: Icon(Icons.accessible_forward_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'independent', child: Text('Independent')),
                          DropdownMenuItem(value: 'assisted', child: Text('Assisted')),
                          DropdownMenuItem(value: 'wheelchair', child: Text('Wheelchair')),
                          DropdownMenuItem(value: 'bedridden', child: Text('Bedridden')),
                        ],
                        onChanged: _submitting ? null : (val) {
                          if (val != null) {
                            setState(() {
                              _mobility = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cityController,
                        enabled: !_submitting,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          prefixIcon: Icon(Icons.location_city_outlined),
                          hintText: 'Enter city (e.g. Hyderabad)',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section 3: Medical & Notes
                _buildHeaderSection('Medical & Details', Icons.medical_services_outlined),
                const SizedBox(height: 12),
                SevaCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _conditionsController,
                        enabled: !_submitting,
                        decoration: const InputDecoration(
                          labelText: 'Health Conditions (comma-separated)',
                          prefixIcon: Icon(Icons.favorite_border),
                          hintText: 'e.g. Diabetes, Hypertension',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        enabled: !_submitting,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.map_outlined),
                          hintText: 'Enter physical address',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emergencyNotesController,
                        enabled: !_submitting,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Emergency Notes',
                          prefixIcon: Icon(Icons.warning_amber_outlined),
                          hintText: 'Any special emergency instructions',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SevaColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save Senior Citizen',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: SevaColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: SevaColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
