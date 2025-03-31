import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class NGOProfilePage extends StatefulWidget {
  const NGOProfilePage({super.key});

  @override
  State<NGOProfilePage> createState() => _NGOProfilePageState();
}

class _NGOProfilePageState extends State<NGOProfilePage> {
  final String ngoId = 'sample-ngo-id'; // Replace with auth
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController, _emailController, _phoneController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance.collection('approved-ngos').doc(ngoId).get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data['ngoName'] ?? '';
      _emailController.text = data['email'] ?? '';
      _phoneController.text = data['phone'] ?? '';
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('approved-ngos').doc(ngoId).update({
        'ngoName': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
      });
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    }
  }

  Future<void> _contactAdmin() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'paramdholakia1@gmail.com',
      queryParameters: {
        'subject': 'Paw Saviour: NGO Support Request',
        'body': 'Dear Admin,\n\nI am contacting you regarding [issue/request]. My NGO ID is $ngoId and email is ${_emailController.text}.\n\nThank you,\n${_nameController.text}',
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _isEditing ? _updateProfile : () => setState(() => _isEditing = true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    child: Text(_isEditing ? 'Save' : 'Edit', style: GoogleFonts.inter()),
                  ),
                  if (!_isEditing)
                    OutlinedButton(
                      onPressed: _contactAdmin,
                      child: Text('Contact Admin', style: GoogleFonts.inter(color: Colors.blue)),
                    ),
                ],
              ),
              if (_isEditing)
                TextButton(
                  onPressed: () {
                    _loadProfile();
                    setState(() => _isEditing = false);
                  },
                  child: const Text('Cancel'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}