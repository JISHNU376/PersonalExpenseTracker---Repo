import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _loading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),

              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_outlined,
                  size: 32,
                  color: Color(0xFF2F6BFF),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "Create Account",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 6),

              const Text(
                "Sign up to get started with secure access",
                style: TextStyle(color: Color(0xFF7A869A)),
              ),

              const SizedBox(height: 25),

              _label("Full Name"),
              _inputField(
                hint: "Enter your name",
                icon: Icons.person_outline,
                controller: _nameController,
              ),

              const SizedBox(height: 20),

              _label("Email Address"),
              _emailField(),

              const SizedBox(height: 20),

              _label("Password"),
              _passwordField(
                controller: _passwordController,
                visible: _passwordVisible,
                toggle: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
              ),

              const SizedBox(height: 20),

              _label("Confirm Password"),
              _passwordField(
                controller: _confirmPasswordController,
                visible: _confirmPasswordVisible,
                toggle: () => setState(() =>
                _confirmPasswordVisible = !_confirmPasswordVisible),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F6BFF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Sign Up",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      "Log In",
                      style: TextStyle(
                        color: Color(0xFF2F6BFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _label(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child:
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _inputField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8FBFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // 🔥 Email always lowercase
  Widget _emailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textCapitalization: TextCapitalization.none,
      onChanged: (value) {
        final lower = value.toLowerCase();
        if (value != lower) {
          _emailController.value = TextEditingValue(
            text: lower,
            selection: TextSelection.collapsed(offset: lower.length),
          );
        }
      },
      decoration: InputDecoration(
        hintText: "Enter your email",
        prefixIcon: const Icon(Icons.mail_outline),
        filled: true,
        fillColor: const Color(0xFFF8FBFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required bool visible,
    required VoidCallback toggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            visible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: toggle,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FBFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ================= LOGIC =================

  bool _isStrongPassword(String password) {
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$',
    );
    return regex.hasMatch(password);
  }

  Future<void> _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final confirmPassword =
    _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMsg("All fields are required");
      return;
    }

    if (password != confirmPassword) {
      _showMsg("Passwords do not match");
      return;
    }

    if (!_isStrongPassword(password)) {
      _showMsg(
          "Password must contain uppercase, lowercase, number, special character & minimum 8 characters");
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
        },
      );

      if (res.user != null) {
        _showMsg("Signup successful. Please login.");
        context.go('/login');
      }
    } on AuthException catch (e) {
      // 🔐 THIS IS THE FIX
      if (e.message.toLowerCase().contains('already')) {
        _showMsg("Email already registered. Please login.");
      } else {
        _showMsg(e.message);
      }
    } catch (_) {
      _showMsg("Signup failed. Try again.");
    }

    setState(() => _loading = false);
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
