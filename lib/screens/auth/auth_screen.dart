import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/active_profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

enum _AuthStep { phone, password, createPassword }

class AuthCheckScreen extends ConsumerStatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  ConsumerState<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends ConsumerState<AuthCheckScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  _AuthStep _step = _AuthStep.phone;
  bool _isLoading = false;
  String? _errorText;
  String _phone = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitPhone() async {
    final rawPhone = _phoneController.text.trim();
    final phone = rawPhone.replaceAll(RegExp(r'\D'), '');

    if (phone.length < 10) {
      setState(() => _errorText = 'Enter a valid phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final repository = await ref.read(authRepositoryProvider.future);
      final result = await repository.checkPhone(phone);

      if (!mounted) return;

      final exists = result['exists'] == true;
      final hasPassword = result['has_password'] == true;

      if (!exists) {
        setState(() {
          _isLoading = false;
          _errorText = 'This number is not registered with TAP';
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _phone = phone;
        _step = hasPassword ? _AuthStep.password : _AuthStep.createPassword;
      });
      _passwordFocusNode.requestFocus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _submitPassword() async {
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() => _errorText = 'Enter your password');
      return;
    }

    await _login(password);
  }

  Future<void> _submitCreatePassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.length < 6) {
      setState(() => _errorText = 'Password must be at least 6 characters');
      return;
    }
    if (password != confirm) {
      setState(() => _errorText = 'Passwords do not match');
      return;
    }

    await _login(password);
  }

  Future<void> _login(String password) async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final repository = await ref.read(authRepositoryProvider.future);
      final result = await repository.login(phone: _phone, password: password);

      if (!mounted) return;

      if (result['success'] != true) {
        final error = result['error'] as String?;
        setState(() {
          _isLoading = false;
          _errorText = _messageForError(error);
        });
        return;
      }

      if (!mounted) return;

      final rawProfiles = result['profiles'];
      final profiles = rawProfiles is List ? rawProfiles : const [];

      if (profiles.isEmpty) {
        setState(() => _isLoading = false);
        context.go(AppRoutes.onboarding);
        return;
      }

      if (profiles.length == 1) {
        final only = Map<String, dynamic>.from(profiles.first as Map);
        final learnerId = only['learner_id'] as String?;
        if (learnerId != null) {
          await _selectSingleProfileAndRoute(learnerId, only);
          return;
        }
      }

      setState(() => _isLoading = false);
      context.go('${AppRoutes.profileSelect}?phone=$_phone');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _selectSingleProfileAndRoute(
    String learnerId,
    Map<String, dynamic> profileJson,
  ) async {
    try {
      final profileRepository = await ref.read(
        profileRepositoryProvider.future,
      );
      final learnerState = await profileRepository.selectProfile(
        phone: _phone,
        learnerId: learnerId,
      );

      final onboardingCompleted = profileRepository.isOnboardingCompleted(
        learnerId,
        fallback: profileJson['onboarding_completed'] as bool? ?? false,
      );

      await setActiveProfile(
        ref,
        ActiveProfileModel(
          phone: _phone,
          learnerId: learnerId,
          studentName:
              learnerState.profile?.studentName ??
              profileJson['student_name'] as String?,
          grade: profileJson['grade']?.toString(),
          division: profileJson['division'] as String?,
          avatar: profileJson['avatar']?.toString(),
          onboardingCompleted: onboardingCompleted,
        ),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      context.go(onboardingCompleted ? AppRoutes.home : AppRoutes.onboarding);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.go('${AppRoutes.profileSelect}?phone=$_phone');
    }
  }

  String _messageForError(String? error) {
    switch (error) {
      case 'invalid_credentials':
        return 'Incorrect phone or password';
      case 'password_too_short':
        return 'Password must be at least 6 characters';
      case 'missing_token':
      case 'invalid_token_type':
      case 'token_phone_mismatch':
      case 'token_expired':
      case 'invalid_signature':
      case 'malformed_token':
        return 'Your session expired. Please try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  void _backToPhone() {
    setState(() {
      _step = _AuthStep.phone;
      _errorText = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
    _phoneFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 0 : 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 440 : 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Logos(isDesktop: isDesktop),
                      SizedBox(height: isDesktop ? 48 : 36),
                      _buildCard(isDesktop),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 40 : 24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: isDesktop
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _titleForStep(),
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 26 : 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _subtitleForStep(),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.subheadingColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          if (_step == _AuthStep.phone) _buildPhoneStep(),
          if (_step == _AuthStep.password) _buildPasswordStep(),
          if (_step == _AuthStep.createPassword) _buildCreatePasswordStep(),
          if (_errorText != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(text: _errorText!),
          ],
        ],
      ),
    );
  }

  String _titleForStep() {
    switch (_step) {
      case _AuthStep.phone:
        return 'Sign in to TAP';
      case _AuthStep.password:
        return 'Welcome back';
      case _AuthStep.createPassword:
        return 'Create a password';
    }
  }

  String _subtitleForStep() {
    switch (_step) {
      case _AuthStep.phone:
        return 'Enter the phone number linked with your school account.';
      case _AuthStep.password:
        return 'Enter your password for $_phone.';
      case _AuthStep.createPassword:
        return 'This number does not have a password yet. Set one to secure your account.';
    }
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel('Phone number'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _phoneController,
          focusNode: _phoneFocusNode,
          hintText: '9876543210',
          keyboardType: TextInputType.phone,
          autofocus: true,
          onSubmitted: (_) => _submitPhone(),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: 'Continue',
          isLoading: _isLoading,
          onPressed: _submitPhone,
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel('Password'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          hintText: 'Enter your password',
          obscureText: _obscurePassword,
          autofocus: true,
          onSubmitted: (_) => _submitPassword(),
          suffixIcon: _VisibilityToggle(
            obscured: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: 'Sign in',
          isLoading: _isLoading,
          onPressed: _submitPassword,
        ),
        const SizedBox(height: 12),
        _TextLinkButton(
          label: 'Use a different number',
          onPressed: _backToPhone,
        ),
      ],
    );
  }

  Widget _buildCreatePasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel('New password'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          hintText: 'At least 6 characters',
          obscureText: _obscurePassword,
          autofocus: true,
          suffixIcon: _VisibilityToggle(
            obscured: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 16),
        _FieldLabel('Confirm password'),
        const SizedBox(height: 8),
        _AuthTextField(
          controller: _confirmPasswordController,
          hintText: 'Re-enter your password',
          obscureText: _obscureConfirmPassword,
          onSubmitted: (_) => _submitCreatePassword(),
          suffixIcon: _VisibilityToggle(
            obscured: _obscureConfirmPassword,
            onToggle: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: 'Create password',
          isLoading: _isLoading,
          onPressed: _submitCreatePassword,
        ),
        const SizedBox(height: 12),
        _TextLinkButton(
          label: 'Use a different number',
          onPressed: _backToPhone,
        ),
      ],
    );
  }
}

class _Logos extends StatelessWidget {
  final bool isDesktop;

  const _Logos({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/logos/gov-logo.png',
          height: isDesktop ? 48 : 40,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
        const SizedBox(width: 12),
        Image.asset(
          'assets/logos/tap_logo.png',
          height: isDesktop ? 38 : 32,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.textColor,
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autofocus;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  const _AuthTextField({
    required this.controller,
    this.focusNode,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.autofocus = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.fieldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        autofocus: autofocus,
        textInputAction: TextInputAction.done,
        style: GoogleFonts.inter(
          color: AppTheme.textColor,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(color: AppTheme.faintText, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: suffixIcon,
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  final bool obscured;
  final VoidCallback onToggle;

  const _VisibilityToggle({required this.obscured, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      icon: Icon(
        obscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        color: AppTheme.faintText,
        size: 20,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.buttonColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class _TextLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _TextLinkButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.buttonColor,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String text;

  const _ErrorBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF5C2C2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFD34B40),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD34B40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
