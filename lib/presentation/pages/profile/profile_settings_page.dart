import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:turbo_car/data/providers/auth_provider.dart';
import 'package:turbo_car/presentation/widgets/common/custom_app_bar.dart';
import 'package:turbo_car/presentation/widgets/common/custom_text_field.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Placeholder for now, assumes these exist or will be created
// import 'package:turbo_car/data/providers/user_provider.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() =>
      _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  String? _gender;
  DateTime? _dob;
  File? _newProfileImage;
  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    // Initialize controllers first
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    // Defer initialization to after build to access ref
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null) {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _phoneController.text = user.phone ?? '';
        setState(() {
          _gender = user.gender;
          _dob = user.dateOfBirth;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _newProfileImage = File(image.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _dob ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dob) {
      setState(() {
        _dob = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Upload Image if new one selected
      String? photoUrl;
      if (_newProfileImage != null) {
        photoUrl = await ref
            .read(authProvider.notifier)
            .uploadImage(_newProfileImage!);
      }

      // 2. Update Profile
      final formattedDob = _dob != null
          ? DateFormat('yyyy-MM-dd').format(_dob!)
          : null;

      await ref
          .read(authProvider.notifier)
          .updateProfile(
            fullName: _nameController.text,
            gender: _gender,
            dob: formattedDob,
            photoUrl: photoUrl,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-fetch user from provider to ensure up-to-date
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark,
      appBar: CustomAppBar(title: 'Profile Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _newProfileImage != null
                      ? FileImage(_newProfileImage!)
                      : (user?.profilePicture != null &&
                                user!.profilePicture!.isNotEmpty
                            ? NetworkImage(user.profilePicture!)
                                  as ImageProvider
                            : null),
                  child:
                      (_newProfileImage == null &&
                          (user?.profilePicture == null ||
                              user!.profilePicture!.isEmpty))
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _pickImage,
                child: const Text('Change Photo'),
              ),
              const SizedBox(height: 24),

              // Name (Editable)
              CustomTextField(
                label: 'Full Name',
                controller: _nameController,
                validator: (v) => v!.isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date of Birth',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dob != null
                                  ? DateFormat('MMM dd, yyyy').format(_dob!)
                                  : 'Select Date',
                            ),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Gender (Editable Dropdown)
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items: _genders
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _gender = val),
                    ),
                  ),
                ],
              ),
              // DOB (Editable)
              const SizedBox(height: 32),

              // Phone (Read-only)
              CustomTextField(
                label: 'Phone Number',
                controller: _phoneController,
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: 16),

              // Email (Read-only)
              CustomTextField(
                label: 'Email',
                controller: _emailController,
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: 60),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16),
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
