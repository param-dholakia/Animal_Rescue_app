// main.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart'; // Added this import
import 'firebase_options.dart';
import 'ngo_login.dart';
import 'admin_login.dart';
import 'report.dart';
import 'google_drive_service.dart';
import 'register.dart';
import 'ngo_dashboard.dart';
import 'admin_dashboard.dart';

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
              title: const Text('NGO Login'),
              onTap: () => Navigator.pushNamed(context, '/ngo_login'),
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Login'),
              onTap: () => Navigator.pushNamed(context, '/admin_login'),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Register'),
              onTap: () => Navigator.pushNamed(context, '/register'),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'), // Replace with your image path
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Semi-transparent overlay for readability
          Container(
            color: Colors.black.withOpacity(0.4),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Report Here",
                  style: GoogleFonts.roboto(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                Text(
                  "(click below red button to report)",
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.all(20),
                    shape: const CircleBorder(),
                    elevation: 8.0,
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
        ],
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
      '/ngo_login': (context) => const NGOLoginPage(),
      '/admin_login': (context) => const AdminLoginPage(),
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