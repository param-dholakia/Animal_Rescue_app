import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'ngo_dashboard.dart';
import 'admin_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _idFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  String _selectedRole = 'NGO'; // Default role
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _idFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_selectedRole == 'NGO') {
        await _loginNGO();
      } else {
        await _loginAdmin();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loginNGO() async {
    final email = _idController.text.trim();
    final password = _passwordController.text.trim();

    final snapshot = await FirebaseFirestore.instance
        .collection('approved-ngos')
        .where('email', isEqualTo: email)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('No NGO found with this email');
    }

    final ngoData = snapshot.docs.first.data();
    if (ngoData['password'] != password) {
      throw Exception('Incorrect password');
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const NGODashboardPage()),
    );
  }

  Future<void> _loginAdmin() async {
    final adminId = _idController.text.trim();
    final password = _passwordController.text.trim();

    final docRef = FirebaseFirestore.instance.collection('admins').doc(adminId);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      throw Exception('No admin found with this ID');
    }

    final adminData = docSnapshot.data()!;
    if (adminData['password'] != password) {
      throw Exception('Incorrect password');
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
    );
  }

  Future<void> _contactAdminForPassword() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'paramdholakia1@gmail.com',
      queryParameters: {
        'subject': 'Paw Saviour: Password Reset Request',
        'body':
            'Dear Admin,\n\nI have forgotten my password for the Paw Saviour app. My ${_selectedRole == 'NGO' ? 'email' : 'ID'} is ${_idController.text.trim()}. Please assist me with resetting my password.\n\nThank you,\n[Your Name]',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email client')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pets, size: 80, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  'Paw Saviour',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login to your account',
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24.0),
                  color: Colors.white,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Login As',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'NGO', child: Text('NGO')),
                            DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                              _idController.clear();
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _idController,
                          focusNode: _idFocusNode,
                          decoration: InputDecoration(
                            labelText: _selectedRole == 'NGO' ? 'Email' : 'Admin ID',
                            prefixIcon: Icon(
                              _selectedRole == 'NGO' ? Icons.email : Icons.person,
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: _selectedRole == 'NGO'
                              ? TextInputType.emailAddress
                              : TextInputType.text,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_passwordFocusNode),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return _selectedRole == 'NGO'
                                  ? 'Please enter your email'
                                  : 'Please enter your Admin ID';
                            }
                            if (_selectedRole == 'NGO' &&
                                !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your password';
                            if (value.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _contactAdminForPassword,
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.inter(color: Colors.blue),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _isLoading
                            ? const SpinKitFadingCircle(color: Colors.blue, size: 50)
                            : ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  'Login',
                                  style: GoogleFonts.inter(fontSize: 18),
                                ),
                              ).animate().fadeIn(duration: 300.ms),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}