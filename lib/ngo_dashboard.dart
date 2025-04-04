import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'ngo_reports_page.dart' as reports;
import 'ngo_profile_widget.dart';

class NGODashboardPage extends StatefulWidget {
  final String ngoName;
  const NGODashboardPage({super.key, required this.ngoName});

  @override
  State<NGODashboardPage> createState() => _NGODashboardPageState();
}

class _NGODashboardPageState extends State<NGODashboardPage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      NGOHomePage(ngoName: widget.ngoName),
      reports.NGOReportsPage(ngoName: widget.ngoName),
      NGOProfilePage(ngoName: widget.ngoName),
    ];
  }

  Future<Map<String, int>> _getReportStats() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reports')
        .where('assignedTo', isEqualTo: widget.ngoName)
        .get();
    final stats = {'Total': snapshot.docs.length, 'In Progress': 0, 'Solved': 0};
    for (var doc in snapshot.docs) {
      final status = doc['status'] ?? 'Unsolved';
      if (status == 'In Progress') stats['In Progress'] = stats['In Progress']! + 1;
      if (status == 'Solved') stats['Solved'] = stats['Solved']! + 1;
    }
    return stats;
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Confirm
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    // If user confirms logout, proceed
    if (shouldLogout == true) {
      Navigator.pushReplacementNamed(context, '/ngo_login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('NGO Dashboard', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: Colors.blue,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => setState(() {}),
              tooltip: 'Refresh',
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout, // Call the logout function with confirmation
              tooltip: 'Logout',
            ),
          ],
        ),
        body: _pages[_selectedIndex].animate().fadeIn(duration: 300.ms),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}

class NGOHomePage extends StatelessWidget {
  final String ngoName;
  const NGOHomePage({super.key, required this.ngoName});

  @override
  Widget build(BuildContext context) {
    final dashboardState = context.findAncestorStateOfType<_NGODashboardPageState>()!;
    return FutureBuilder<Map<String, int>>(
      future: dashboardState._getReportStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: SpinKitFadingCircle(color: Colors.blue));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading stats'));
        }
        final stats = snapshot.data!;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $ngoName!',
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Stats', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Cases:', style: GoogleFonts.inter()),
                            Text('${stats['Total']}', style: GoogleFonts.inter(color: Colors.blue)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('In Progress:', style: GoogleFonts.inter()),
                            Text('${stats['In Progress']}', style: GoogleFonts.inter(color: Colors.orange)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Completed:', style: GoogleFonts.inter()),
                            Text('${stats['Solved']}', style: GoogleFonts.inter(color: Colors.green)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}