import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'report.dart';
import 'google_drive_service.dart';
import 'register.dart';
import 'ngo_dashboard.dart'; // Import NGODashboardPage
import 'admin_dashboard.dart'; // Import AdminDashboardPage

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
              onTap: () => Navigator.pushNamed(context, '/login'),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Register'),
              onTap: () => Navigator.pushNamed(context, '/register'),
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
              onPressed: () => Navigator.pushNamed(context, '/report'),
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

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization failed: $e");
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Failed to initialize Firebase. Please check your configuration.',
            style: TextStyle(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ));
    return;
  }

  // Initialize Google Drive Service
  final driveService = GoogleDriveService();
  try {
    await driveService.authenticateWithGoogleDrive();
    print("✅ Google Drive authenticated successfully");
  } catch (e) {
    print("❌ Google Drive authentication failed: $e");
  }

  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => const HomePageWidget(),
      '/login': (context) => const LoginPage(),
      '/register': (context) => const RegisterPageWidget(),
      '/report': (context) => const ReportPageWidget(),
      '/ngo_dashboard': (context) {
        final ngoName = ModalRoute.of(context)!.settings.arguments as String?;
        if (ngoName == null) {
          return const Scaffold(
            body: Center(child: Text('Error: NGO name not provided')),
          );
        }
        return NGODashboardPage(ngoName: ngoName);
      },
      '/admin_dashboard': (context) => const AdminDashboardPage(),
    },
    theme: ThemeData(
      primaryColor: Colors.blue,
      useMaterial3: true,
    ),
  ));
}