import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminLoginWidget extends StatefulWidget {
  const AdminLoginWidget({super.key});

  @override
  State<AdminLoginWidget> createState() => _AdminLoginWidgetState();
}

class _AdminLoginWidgetState extends State<AdminLoginWidget> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool passwordVisible = false;
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Paw Saviour',
          style: GoogleFonts.inter(fontSize: 22, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
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
              decoration: InputDecoration(labelText: 'Login as'),
            ),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Enter Username'),
            ),
            TextField(
              controller: passwordController,
              obscureText: !passwordVisible,
              decoration: InputDecoration(
                labelText: 'Enter Password',
                suffixIcon: IconButton(
                  icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => passwordVisible = !passwordVisible),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => print("Login button pressed"),
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
