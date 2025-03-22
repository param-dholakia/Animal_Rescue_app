// admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(const PawSaviorAdminDashboard());
}

class PawSaviorAdminDashboard extends StatelessWidget {
  const PawSaviorAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paw Savior Admin Dashboard',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AdminDashboardPage(),
    );
  }
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => AdminDashboardPageState();
}

class AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    ReportManagementPage(),
    AnalyticsPage(),
    ContentManagementPage(),
    PushNotificationPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Content Mgmt'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        elevation: 10,  // Adds a shadow for better contrast
      ),
    );
  }
}

// Report Management Page with Firestore CRUD operations
class ReportManagementPage extends StatefulWidget {
  const ReportManagementPage({super.key});

  @override
  State<ReportManagementPage> createState() => _ReportManagementPageState();
}

class _ReportManagementPageState extends State<ReportManagementPage> {
  final CollectionReference reportsCollection = FirebaseFirestore.instance.collection('reports');

  void _addReport() async {
    await reportsCollection.add({'title': 'New Report', 'status': 'Pending'});
  }

  void _updateReport(String docId) async {
    await reportsCollection.doc(docId).update({'title': 'Updated Report'});
  }

  void _deleteReport(String docId) async {
    await reportsCollection.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: reportsCollection.snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data!.docs;
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return ListTile(
                    title: Text(
                      report['title'],
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _updateReport(report.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteReport(report.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addReport,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Add Report', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

// Analytics Page
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Analytics Dashboard',
        style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Content Management Page
class ContentManagementPage extends StatelessWidget {
  const ContentManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Content Management Page',
        style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Push Notification Page
class PushNotificationPage extends StatelessWidget {
  const PushNotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Push Notification Control Page',
        style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}