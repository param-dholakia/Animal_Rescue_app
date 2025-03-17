import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminRegisterWidget extends StatefulWidget {
  const AdminRegisterWidget({super.key});

  @override
  State<AdminRegisterWidget> createState() => _AdminRegisterWidgetState();
}

class _AdminRegisterWidgetState extends State<AdminRegisterWidget> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool passwordVisible = false;

  Future<void> registerAdmin() async {
    String name = nameController.text.trim();
    String id = idController.text.trim();
    String password = passwordController.text.trim();

    if (name.isEmpty || id.isEmpty || password.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    final adminDoc = FirebaseFirestore.instance.collection('admins').doc(id);
    final docSnapshot = await adminDoc.get();

    if (docSnapshot.exists) {
      showMessage("Admin ID already exists");
    } else {
      await adminDoc.set({
        'name': name,
        'password': password,
      });
      showMessage("Admin Registered Successfully", success: true);
      Navigator.pop(context);
    }
  }

  void showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Registration',
            style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
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
                  icon: Icon(passwordVisible
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => passwordVisible = !passwordVisible),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: registerAdmin,
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
