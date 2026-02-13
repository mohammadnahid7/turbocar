/// Change Password Page
/// Page for changing user password with secure UX patterns
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_text_field.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Password visibility states
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref
            .read(authProvider.notifier)
            .changePassword(
              _currentPasswordController.text,
              _newPasswordController.text,
            );
        // Success handled by ref.listen
      } catch (_) {
        // Error handled by ref.listen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ONLY watch loading state - minimizes rebuilds
    // Input fields use TextEditingController which preserves values
    final isLoading = ref.watch(
      authProvider.select((state) => state.isLoading),
    );
    final theme = Theme.of(context);

    // Listen to Auth State for Errors and Success
    // This does NOT cause rebuilds - only fires callbacks
    ref.listen<AuthState>(authProvider, (previous, next) {
      // Handle Success
      if (!next.isLoading &&
          previous?.isLoading == true &&
          next.error == null) {
        // Success - show message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(StringConstants.passwordChangedSuccess),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }

      // Handle Errors - Show SnackBar without navigation
      if (!next.isLoading &&
          next.error != null &&
          (previous?.isLoading == true || previous?.error != next.error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!.replaceAll('Exception: ', '')),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: theme.primaryColorDark,
      appBar: CustomAppBar(title: StringConstants.changePasswordTitle),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current Password Field
              CustomTextField(
                label: StringConstants.currentPassword,
                controller: _currentPasswordController,
                obscureText: !_showCurrentPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showCurrentPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  onPressed: () {
                    setState(() {
                      _showCurrentPassword = !_showCurrentPassword;
                    });
                  },
                ),
                validator: (value) => Validators.validateRequired(
                  value,
                  StringConstants.currentPassword,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    textAlign: TextAlign.right,
                    StringConstants.forgotPassword,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    onPressed: null, // TODO: Forgot password
                    child: const Text("Reset"),
                  ),
                ],
              ),

              // New Password Field
              CustomTextField(
                label: StringConstants.newPassword,
                controller: _newPasswordController,
                obscureText: !_showNewPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNewPassword ? Icons.visibility_off : Icons.visibility,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  onPressed: () {
                    setState(() {
                      _showNewPassword = !_showNewPassword;
                    });
                  },
                ),
                validator: Validators.validatePassword,
              ),

              // Password Requirements Display
              Padding(
                padding: const EdgeInsets.only(
                  left: 8.0,
                  top: 8.0,
                  bottom: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password Requirements:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildRequirement('At least 8 characters'),
                    _buildRequirement('One uppercase letter'),
                    _buildRequirement('One lowercase letter'),
                    _buildRequirement('One number'),
                    _buildRequirement('One special character (!@#\$%^&*)'),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Confirm New Password Field
              CustomTextField(
                label: StringConstants.confirmNewPassword,
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  onPressed: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                ),
                validator: (value) => Validators.validateConfirmPassword(
                  _newPasswordController.text,
                  value ?? '',
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              CustomButton(
                text: StringConstants.save,
                isLoading: isLoading,
                onPressed: isLoading ? null : _handleChangePassword,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
