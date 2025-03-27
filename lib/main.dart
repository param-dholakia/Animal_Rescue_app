import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login.dart'; // Import the updated login.dart file
import 'report.dart';
import 'google_drive_service.dart';
import 'register.dart'; // Import the new register.dart file

class HomePageWidget extends StatelessWidget {
  const HomePageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paw Saviour', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Text("Menu", style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Login'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()), // Updated to LoginPage
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_add), // Icon for registration
              title: const Text('Register'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPageWidget()),
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Report Here",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const Text("(click below red button to report)"),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(20),
                shape: const CircleBorder(),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportPageWidget()),
              ),
              child: const Icon(
                FontAwesomeIcons.paw,
                color: Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization failed: $e");
  }

  final driveService = GoogleDriveService();
  try {
    await driveService.authenticateWithGoogleDrive();
    print("✅ Google Drive authenticated successfully");
  } catch (e) {
    print("❌ Google Drive authentication failed: $e");
  }

  runApp(MaterialApp(
    home: const HomePageWidget(),
    theme: ThemeData(
      primaryColor: Colors.blue,
      useMaterial3: true, // Added for consistency with LoginPage
    ),
  ));
}