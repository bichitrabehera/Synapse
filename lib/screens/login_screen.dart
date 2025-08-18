import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final success = await context.read<AuthProvider>().login(
            _email.text.trim(),
            _password.text.trim(),
          );

      if (!mounted) return;

      if (!success) {
        setState(() {
          _error = "Incorrect email or password. Please try again.";
          _loading = false;
        });
        return;
      }

      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Login failed. Please try again.";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- Header ---
                  Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign in to access your account",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // --- Email Input ---
                  _buildInputField(
                    controller: _email,
                    hint: "Email Address",
                    icon: Icons.mail_outline,
                    validator: (v) => v != null && v.contains("@")
                        ? null
                        : "Enter a valid email",
                    keyboardType: TextInputType.emailAddress,
                  ),

                  // --- Password Input ---
                  _buildInputField(
                    controller: _password,
                    hint: "Password",
                    icon: Icons.lock_outline,
                    validator: (v) =>
                        (v ?? "").length >= 4 ? null : "Minimum 6 characters",
                    obscure: true,
                  ),

                  // --- Enhanced Error message ---
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color.fromARGB(255, 255, 6, 31)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // --- Sign In Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      onPressed: _loading ? null : _handleLogin,
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
                              "Sign In",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Divider ---
                  Row(
                    children: [
                      Expanded(
                        child:
                            Divider(color: Colors.grey.shade300, thickness: 1),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          "OR CONTINUE WITH",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child:
                            Divider(color: Colors.grey.shade300, thickness: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- Footer ---
                  Text(
                    "Don't have an account?",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => context.push('/register'),
                      child: const Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              obscureText: obscure,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                errorStyle: const TextStyle(height: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}