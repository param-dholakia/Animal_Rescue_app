import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'admin_login.dart';
import 'report.dart';
import 'google_drive_service.dart'; // Added Google Drive service import

class HomePageWidget extends StatelessWidget {
  const HomePageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paw Saviour', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Text("Menu", style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Login'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminLoginWidget()),
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Report Here",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            Text("(click below red button to report)"),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.all(20),
                shape: CircleBorder(),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReportPageWidget()), // Ensure ReportPageWidget exists
              ),
              child: Icon(
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

// Updated main function to initialize Firebase and authenticate Google Drive
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
    await driveService.authenticateWithGoogleDrive(); // Authenticate Google Drive
    print("✅ Google Drive authenticated successfully");
  } catch (e) {
    print("❌ Google Drive authentication failed: $e");
  }

  runApp(MaterialApp(
    home: HomePageWidget(),
    theme: ThemeData(
      primaryColor: Colors.blue, // Set your primary color here
    ),
  ));
}