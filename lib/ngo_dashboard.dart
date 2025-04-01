import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ngo_reports_page.dart';
import 'ngo_profile_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class NGODashboardPage extends StatefulWidget {
  final String ngoName; // Use ngoName instead of ngoEmail
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
      NGOReportsPage(ngoName: widget.ngoName),
      NGOProfilePage(ngoName: widget.ngoName),
    ];
  }

  Future<String> _getNGOName() async {
    final doc = await FirebaseFirestore.instance.collection('approved-ngos').doc(widget.ngoName).get();
    return doc.exists ? (doc.data()?['ngoName'] ?? 'NGO') : 'NGO';
  }

  Future<Map<String, int>> _getReportStats() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reports')
        .where('assignedTo', isEqualTo: widget.ngoName) // Use ngoName for assignedTo
        .get();
    final stats = {'Total': snapshot.docs.length, 'In Progress': 0, 'Solved': 0};
    for (var doc in snapshot.docs) {
      final status = doc['status'] ?? 'Unsolved';
      if (status == 'In Progress') stats['In Progress'] = stats['In Progress']! + 1;
      if (status == 'Solved') stats['Solved'] = stats['Solved']! + 1;
    }
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NGO Dashboard', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
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
    );
  }
}

class NGOHomePage extends StatelessWidget {
  final String ngoName;
  const NGOHomePage({super.key, required this.ngoName});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        (context.findAncestorStateOfType<_NGODashboardPageState>())!._getNGOName(),
        (context.findAncestorStateOfType<_NGODashboardPageState>())!._getReportStats(),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (!snapshot.hasData) return const Center(child: SpinKitFadingCircle(color: Colors.blue));
        final ngoName = snapshot.data![0] as String;
        final stats = snapshot.data![1] as Map<String, int>;

        return Padding(
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NGOReportsPage(ngoName: ngoName))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('View Reports', style: GoogleFonts.inter(fontSize: 16)),
              ).animate().scale(duration: 300.ms),
            ],
          ),
        );
      },
    );
  }
}