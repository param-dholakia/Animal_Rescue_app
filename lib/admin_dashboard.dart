import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'admin_report_service.dart';
import 'admin_ngo_widget.dart';
import 'admin_analytics_widget.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => AdminDashboardPageState();
}

class AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const ReportManagementPage(),
    const AnalyticsPage(),
    const NGORegistriesPage(),
  ];

  // Function to handle back button press and prompt for logout confirmation
  Future<bool> _onWillPop() async {
    // Show a confirmation dialog when back is pressed
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Do you want to logout?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // No, don't logout
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true); // Yes, logout
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false; // Default to false if dialog is dismissed
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Intercept back button press
      child: Scaffold(
        appBar: AppBar(
          title: Text('Admin Dashboard', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: Colors.blue,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0), // Adjust the padding to move the button 3px left
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () => setState(() {}),
              ),
            ),
          ],
        ),
        body: _pages[_selectedIndex]
            .animate()
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.2, end: 0, duration: 300.ms),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
            BottomNavigationBarItem(icon: Icon(Icons.group), label: 'NGOs'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
