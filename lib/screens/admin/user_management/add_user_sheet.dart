import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/auth_service.dart';

const Color utmMaroon = Color(0xFF800000);
const Color goldHighlight = Color(0xFFFFD700);
const Color backgroundDark = Color(0xFF0F0F0F);
const Color cardGrey = Color(0xFF1B1B1B);

class AddUserSheet extends StatefulWidget {
  const AddUserSheet({super.key});

  @override
  State<AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends State<AddUserSheet> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _matricCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedRole = 'student';
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _matricCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all required fields.';
      });
      return;
    }

    if (_passwordCtrl.text.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await RepositoryProvider.of<AuthService>(context).createUserAsAdmin(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        name: _nameCtrl.text.trim(),
        matricNumber: _matricCtrl.text.trim(),
        role: _selectedRole,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _friendlyError(e);
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'New User',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _field('Full Name *', Icons.person_outline_rounded, _nameCtrl),
              const SizedBox(height: 12),
              _field(
                'Email Address *',
                Icons.alternate_email_rounded,
                _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _field('Matric Number', Icons.badge_outlined, _matricCtrl),
              const SizedBox(height: 12),
              _field(
                'Password *',
                Icons.lock_outline_rounded,
                _passwordCtrl,
                obscure: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  RoleOption(
                    label: 'Student',
                    icon: Icons.school_rounded,
                    selected: _selectedRole == 'student',
                    onTap: () => setState(() => _selectedRole = 'student'),
                  ),
                  const SizedBox(width: 12),
                  RoleOption(
                    label: 'Admin',
                    icon: Icons.admin_panel_settings_rounded,
                    selected: _selectedRole == 'admin',
                    onTap: () => setState(() => _selectedRole = 'admin'),
                  ),
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _errorMessage == null
                    ? const SizedBox.shrink()
                    : Padding(
                        key: ValueKey(_errorMessage),
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: utmMaroon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create User',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');

    if (message.contains('email-already-in-use')) {
      return 'An account already exists for this email address.';
    }
    if (message.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (message.contains('weak-password')) {
      return 'The password is too weak. Please use a stronger password.';
    }

    return message;
  }

  Widget _field(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          icon: Icon(icon, color: Colors.white38, size: 20),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class RoleOption extends StatelessWidget {
  const RoleOption({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? utmMaroon.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? goldHighlight.withValues(alpha: 0.6)
                  : Colors.white12,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? goldHighlight : Colors.white38,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
