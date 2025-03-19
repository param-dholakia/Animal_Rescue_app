import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_dashboard.dart';

class AdminLoginWidget extends StatefulWidget {
  const AdminLoginWidget({super.key});

  @override
  State<AdminLoginWidget> createState() => _AdminLoginWidgetState();
}

class _AdminLoginWidgetState extends State<AdminLoginWidget> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool passwordVisible = false;
  String? selectedRole;

  Future<void> loginAdmin() async {
    if (selectedRole != "Admin") {
      showMessage("Please select 'Admin' to login");
      return;
    }

    String id = idController.text.trim();
    String password = passwordController.text.trim();

    if (id.isEmpty || password.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(id).get();

    if (adminDoc.exists && adminDoc['password'] == password) {
      showMessage("Login Successful", success: true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboard()),
      );
    } else {
      showMessage("Invalid credentials");
    }
  }

  void showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: success ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Login', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedRole,
              items: ['Admin', 'NGO', 'Govt. Org.']
                  .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                  .toList(),
              onChanged: (val) => setState(() => selectedRole = val),
              decoration: const InputDecoration(labelText: 'Login as'),
            ),
            TextField(
              controller: idController,
              decoration: const InputDecoration(labelText: 'Admin ID'),
            ),
            TextField(
              controller: passwordController,
              obscureText: !passwordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => passwordVisible = !passwordVisible),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loginAdmin,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}