import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController(text: '+250');
  final _otp = TextEditingController();

  bool _phoneMode = false;
  bool _codeSent = false;
  bool _busy = false;
  String? _verificationId;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _signInEmail() async {
    if (!_emailForm.currentState!.validate()) return;
    await context.read<SessionController>().signInWithEmail(
      _email.text,
      _password.text,
    );
  }

  Future<void> _sendCode() async {
    final phone = _normalisePhone(_phone.text);
    if (!RegExp(r'^\+250\d{9}$').hasMatch(phone)) {
      showAppError(context, 'Use a Rwandan number, e.g. +250 78 000 0001');
      return;
    }
    setState(() => _busy = true);
    try {
      final id = await context.read<SessionController>().requestPhoneCode(
        phone,
      );
      if (!mounted) return;
      setState(() {
        _verificationId = id;
        _codeSent = true;
      });
      showAppSuccess(context, 'Code sent. Enter the 6-digit SMS code.');
    } catch (error) {
      if (mounted) showAppError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyCode() async {
    final id = _verificationId;
    if (id == null) return;
    if (_otp.text.trim().length < 4) {
      showAppError(context, 'Enter the code from the SMS.');
      return;
    }
    await context.read<SessionController>().confirmPhoneCode(
      id,
      _otp.text,
    );
  }

  String _normalisePhone(String raw) {
    var value = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (value.startsWith('0')) value = '+250${value.substring(1)}';
    if (!value.startsWith('+')) value = '+250$value';
    return value;
  }

  void _useDemo(String email) {
    _email.text = email;
    _password.text = 'pitchup123';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final error = session.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.sports_soccer,
                      color: AppColors.accent,
                      size: 42,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'PITCHUP',
                      style: TextStyle(
                        color: AppColors.onDarkContainerWhite,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Book the pitch. Find your team. Play together.',
                      style: TextStyle(
                        color: AppColors.onDarkContainerMint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Email'),
                    icon: Icon(Icons.mail_outline),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Phone OTP'),
                    icon: Icon(Icons.phone_iphone),
                  ),
                ],
                selected: {_phoneMode},
                onSelectionChanged: (value) {
                  setState(() => _phoneMode = value.first);
                },
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _phoneMode ? _phoneForm() : _emailFormWidget(),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Demo accounts (local emulator)',
                style: TextStyle(
                  color: AppColors.headings,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _demoChip('Player — Kim', 'kim@pitchup.rw'),
                  _demoChip('Owner — Jean Claude', 'owner@pitchup.rw'),
                  _demoChip('Admin — System', 'admin@pitchup.rw'),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Password: pitchup123. Seeded by `npm run seed`.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _demoChip(String label, String email) {
    return ActionChip(
      avatar: const Icon(Icons.person_outline, size: 18),
      label: Text(label),
      onPressed: () {
        setState(() => _phoneMode = false);
        _useDemo(email);
      },
    );
  }

  Widget _emailFormWidget() {
    return Form(
      key: _emailForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (!text.contains('@') || !text.contains('.')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            onFieldSubmitted: (_) => _signInEmail(),
            validator: (value) =>
                (value ?? '').length < 6 ? 'At least 6 characters' : null,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _signInEmail,
            icon: const Icon(Icons.login),
            label: const Text('Sign in'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Production uses phone OTP; email is available for the emulator '
            'demo accounts and as a fallback sign-in method.',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _phoneForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          enabled: !_codeSent,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: '+250780000001',
            prefixIcon: Icon(Icons.phone_iphone),
          ),
        ),
        const SizedBox(height: 12),
        if (!_codeSent)
          ElevatedButton.icon(
            onPressed: _busy ? null : _sendCode,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sms_outlined),
            label: Text(_busy ? 'Sending…' : 'Send code'),
          )
        else ...[
          TextField(
            controller: _otp,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: '6-digit code',
              prefixIcon: Icon(Icons.password),
              counterText: '',
            ),
            onSubmitted: (_) => _verifyCode(),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _verifyCode,
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('Verify & sign in'),
          ),
          TextButton(
            onPressed: () => setState(() {
              _codeSent = false;
              _otp.clear();
            }),
            child: const Text('Use a different number'),
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'In the Auth emulator the SMS code appears in the Emulator UI '
          '(http://localhost:4000/auth).',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
        ),
      ],
    );
  }
}
