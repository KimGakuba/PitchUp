import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/ui.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<SessionController>().firebaseUser;
    _phone.text = user?.phoneNumber ?? '+250';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<SessionController>().createProfile(
        name: _name.text,
        phone: _phone.text,
      );
    } catch (error) {
      if (mounted) showAppError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Icon(
                  Icons.badge_outlined,
                  size: 52,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Set up your player profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.headings,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your name and reliability score are shown to teammates '
                  'when you join a pickup game.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => (value ?? '').trim().length < 2
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_iphone),
                  ),
                  validator: (value) {
                    final text = (value ?? '').replaceAll(' ', '');
                    return RegExp(r'^\+250\d{9}$').hasMatch(text)
                        ? null
                        : 'Use +250 followed by 9 digits';
                  },
                ),
                if (session.firebaseUser?.email != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Signed in as ${session.firebaseUser!.email}',
                    style: const TextStyle(color: AppColors.secondaryText),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(_busy ? 'Creating…' : 'Create profile'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: session.signOut,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
