import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NGOProfilePage extends StatefulWidget {
  final String ngoName; // Use ngoName instead of ngoEmail
  const NGOProfilePage({super.key, required this.ngoName});

  @override
  State<NGOProfilePage> createState() => _NGOProfilePageState();
}

class _NGOProfilePageState extends State<NGOProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController, _emailController, _phoneController, _passwordController;
  bool _isEditing = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance.collection('approved-ngos').doc(widget.ngoName).get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data['ngoName'] ?? '';
      _emailController.text = data['email'] ?? '';
      _phoneController.text = data['phone'] ?? '';
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('approved-ngos').doc(widget.ngoName).update({
        'ngoName': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
      });
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    }
  }

  Future<void> _changePassword() async {
    if (_passwordController.text.isEmpty || _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('approved-ngos').doc(widget.ngoName).update({
        'password': _passwordController.text,
      });
      setState(() => _isChangingPassword = false);
      _passwordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update password: $e')));
    }
  }

  Future<void> _contactAdmin() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'paramdholakia1@gmail.com',
      queryParameters: {
        'subject': 'Paw Saviour: NGO Support Request',
        'body':
            'Dear Admin,\n\nI am contacting you regarding [issue/request]. My NGO name is ${widget.ngoName} and email is ${_emailController.text}.\n\nThank you,\n${_nameController.text}',
      },
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open email client')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NGO Profile',
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'NGO Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.group),
                  ),
                  enabled: _isEditing,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  enabled: _isEditing,
                  validator: (value) => value!.contains('@') ? null : 'Invalid email',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  enabled: _isEditing,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                if (_isChangingPassword)
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _isEditing
                          ? _updateProfile
                          : _isChangingPassword
                              ? _changePassword
                              : () => setState(() => _isEditing = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        _isEditing ? 'Save' : _isChangingPassword ? 'Update Password' : 'Edit',
                        style: GoogleFonts.inter(),
                      ),
                    ).animate().scale(duration: 300.ms),
                    if (!_isEditing && !_isChangingPassword)
                      OutlinedButton(
                        onPressed: _contactAdmin,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Contact Admin', style: GoogleFonts.inter(color: Colors.blue)),
                      ).animate().fadeIn(duration: 300.ms),
                    if (!_isEditing && !_isChangingPassword)
                      OutlinedButton(
                        onPressed: () => setState(() => _isChangingPassword = true),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Change Password', style: GoogleFonts.inter(color: Colors.blue)),
                      ).animate().fadeIn(duration: 300.ms),
                  ],
                ),
                if (_isEditing || _isChangingPassword)
                  TextButton(
                    onPressed: () {
                      _loadProfile();
                      setState(() {
                        _isEditing = false;
                        _isChangingPassword = false;
                        _passwordController.clear();
                      });
                    },
                    child: const Text('Cancel'),
                  ).animate().slideX(duration: 300.ms, begin: 0.1),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 500.ms),
    );
  }
}