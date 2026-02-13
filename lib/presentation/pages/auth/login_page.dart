/// Login Page
/// Combined Login/Signup page with tabs and guest mode
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login form controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginPasswordVisible = false;

  // Signup form controllers
  final _signupFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _signupPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  String? _selectedGender;
  DateTime? _selectedDOB;

  // Password validation state
  Map<String, bool> _passwordRequirements = {
    'minLength': false,
    'hasUppercase': false,
    'hasLowercase': false,
    'hasNumber': false,
    'hasSpecialChar': false,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _signupPasswordController.addListener(_updatePasswordValidation);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _signupEmailController.dispose();
    _phoneController.dispose();
    _signupPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordValidation() {
    setState(() {
      _passwordRequirements = Validators.validatePasswordRequirements(
        _signupPasswordController.text,
      );
    });
  }

  bool get _isPasswordValid {
    return _passwordRequirements.values.every((v) => v);
  }

  bool get _isSignupFormValid {
    return _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _signupEmailController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _signupPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _selectedGender != null &&
        _selectedDOB != null &&
        _isPasswordValid &&
        _signupPasswordController.text == _confirmPasswordController.text;
  }

  Future<void> _handleLogin() async {
    if (_loginFormKey.currentState!.validate()) {
      try {
        await ref
            .read(authProvider.notifier)
            .login(
              _loginEmailController.text.trim(),
              _loginPasswordController.text,
            );
        // Navigation handled by ref.listen
      } catch (e) {
        // Error handling handled by ref.listen
      }
    }
  }

  Future<void> _handleSignup() async {
    if (!_isSignupFormValid) return;
    if (_signupFormKey.currentState!.validate()) {
      try {
        await ref
            .read(authProvider.notifier)
            .register(
              email: _signupEmailController.text.trim(),
              phone: _phoneController.text.trim(),
              password: _signupPasswordController.text,
              fullName:
                  '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
            );

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success!'),
              content: const Text(
                'Registration successful! You can now login with your credentials.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _tabController.animateTo(0); // Switch to login tab
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } catch (_) {
        // Error is handled by ref.listen in build()
      }
    }
  }

  Future<void> _handleGuestMode() async {
    await ref.read(authProvider.notifier).switchToGuestMode();
    if (mounted) {
      context.go('/home');
    }
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked != null) {
      setState(() {
        _selectedDOB = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ONLY watch the loading state - this minimizes rebuilds
    // Navigation and error handling are done via ref.listen (side effects)
    final isLoading = ref.watch(
      authProvider.select((state) => state.isLoading),
    );
    final theme = Theme.of(context);

    // Listen to Auth State for Navigation and Errors (side effects only)
    // This does NOT cause rebuilds - it only fires callbacks
    ref.listen<AuthState>(authProvider, (previous, next) {
      // 1. Handle Navigation ONLY on Successful Authentication
      if (!next.isLoading && next.isAuthenticated && next.user != null) {
        // Only navigate if we weren't already authenticated
        if (previous?.isAuthenticated != true) {
          context.go('/home');
        }
      }

      // 2. Handle Errors - Show SnackBar without navigation
      if (!next.isLoading &&
          next.error != null &&
          (previous?.isLoading == true || previous?.error != next.error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!.replaceAll('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4), // Give user time to read
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Column(
                children: [
                  // Title changes based on tab
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, child) {
                      final isLogin = _tabController.index == 0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            textAlign: TextAlign.center,
                            isLogin
                                ? StringConstants.welcomeBack
                                : StringConstants.createAccount,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Theme.of(
                                context,
                              ).appBarTheme.foregroundColor,
                            ),
                          ),
                          Text(
                            isLogin
                                ? StringConstants.signInToAccount
                                : StringConstants.signUpToGetStarted,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Theme.of(
                                context,
                              ).appBarTheme.foregroundColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  // Custom Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        width: 1,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.4),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: theme.colorScheme.onSurface,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: StringConstants.login),
                          Tab(text: StringConstants.signup),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Tab Content
              SizedBox(
                height: MediaQuery.of(context).size.height - 280,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLoginForm(isLoading),
                    SingleChildScrollView(child: _buildSignupForm(isLoading)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDividerWithText() {
    return Column(
      children: [
        // Divider with text
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                StringConstants.orContinueWith,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        // Google Login Button (placeholder)
        CustomButton(
          borderRadius: BorderRadius.all(Radius.circular(50)),
          text: StringConstants.loginWithGoogle,
          type: ButtonType.outline,
          onPressed: null, // Placeholder
          icon: Icons.g_mobiledata,
          iconSize: 22,
        ),
        const SizedBox(height: 16),
        // Continue as Guest
        CustomButton(
          text: StringConstants.continueAsGuest,
          type: ButtonType.text,
          onPressed: _handleGuestMode,
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isLoading) {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          CustomTextField(
            controller: _loginEmailController,
            label: StringConstants.emailOrPhone,
            hint: StringConstants.enterEmailOrPhone,
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email or phone';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _loginPasswordController,
            label: StringConstants.password,
            hint: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            obscureText: !_loginPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _loginPasswordVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _loginPasswordVisible = !_loginPasswordVisible;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
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
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  onPressed: null, // TODO: Forgot password
                  child: const Text("Reset"),
                ),
              ],
            ),
          ),
          CustomButton(
            borderRadius: BorderRadius.all(Radius.circular(50)),
            text: StringConstants.login,
            onPressed: _handleLogin,
            isLoading: isLoading,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          ),
          const SizedBox(height: 16),
          _buildDividerWithText(),
        ],
      ),
    );
  }

  Widget _buildSignupForm(bool isLoading) {
    return Form(
      key: _signupFormKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // First Name & Last Name Row
            CustomTextField(
              controller: _firstNameController,
              label: StringConstants.firstName,
              hint: 'First name',
              prefixIcon: const Icon(Icons.person_outline),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _lastNameController,
              label: StringConstants.lastName,
              hint: 'Last name',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child:
                      // Date of Birth
                      GestureDetector(
                        onTap: _selectDateOfBirth,
                        child: AbsorbPointer(
                          child: CustomTextField(
                            controller: TextEditingController(
                              text: _selectedDOB != null
                                  ? '${_selectedDOB!.day}/${_selectedDOB!.month}/${_selectedDOB!.year}'
                                  : '',
                            ),
                            label: StringConstants.dateOfBirth,
                            hint: 'Select date of birth',
                            prefixIcon: const Icon(
                              Icons.calendar_today_outlined,
                            ),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                          ),
                        ),
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      // Gender Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        decoration: InputDecoration(
                          labelText: StringConstants.gender,
                          prefixIcon: const Icon(Icons.people_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Male',
                            child: Text(StringConstants.male),
                          ),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text(StringConstants.female),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text(StringConstants.other),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Email
            CustomTextField(
              controller: _signupEmailController,
              label: StringConstants.email,
              hint: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            // Phone
            CustomTextField(
              controller: _phoneController,
              label: StringConstants.phone,
              hint: 'Enter your phone number',
              prefixIcon: const Icon(Icons.phone_outlined),
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            // Password
            CustomTextField(
              controller: _signupPasswordController,
              label: StringConstants.password,
              hint: 'Create a password',
              prefixIcon: const Icon(Icons.lock_outline),
              obscureText: !_signupPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _signupPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _signupPasswordVisible = !_signupPasswordVisible;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            // Password Requirements
            _buildPasswordRequirements(),
            const SizedBox(height: 12),
            // Confirm Password
            CustomTextField(
              controller: _confirmPasswordController,
              label: StringConstants.confirmPassword,
              hint: 'Confirm your password',
              prefixIcon: const Icon(Icons.lock_outline),
              obscureText: !_confirmPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _confirmPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _confirmPasswordVisible = !_confirmPasswordVisible;
                  });
                },
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            // Signup Button
            CustomButton(
              text: StringConstants.signup,
              onPressed: _isSignupFormValid ? _handleSignup : null,
              isLoading: isLoading,
            ),
            const SizedBox(height: 16),
            _buildDividerWithText(),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    return Column(
      children: [
        _buildRequirementRow(
          StringConstants.minEightCharacters,
          _passwordRequirements['minLength'] ?? false,
        ),
        _buildRequirementRow(
          StringConstants.oneUppercase,
          _passwordRequirements['hasUppercase'] ?? false,
        ),
        _buildRequirementRow(
          StringConstants.oneLowercase,
          _passwordRequirements['hasLowercase'] ?? false,
        ),
        _buildRequirementRow(
          StringConstants.oneNumber,
          _passwordRequirements['hasNumber'] ?? false,
        ),
        _buildRequirementRow(
          StringConstants.oneSpecialChar,
          _passwordRequirements['hasSpecialChar'] ?? false,
        ),
      ],
    );
  }

  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isMet ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
