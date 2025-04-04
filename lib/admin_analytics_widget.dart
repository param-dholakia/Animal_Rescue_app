import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

// Parent widget with two buttons
class AnalyticsDashboard extends StatelessWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportsAnalysisPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Reports Analysis', style: GoogleFonts.inter(fontSize: 18)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NGOAnalysisPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('NGO Analysis', style: GoogleFonts.inter(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

// Page for Reports Analysis
class ReportsAnalysisPage extends StatelessWidget {
  const ReportsAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports Analysis', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('reports').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: SpinKitFadingCircle(color: Colors.blue));
          final reports = snapshot.data!.docs;
          final total = reports.length;
          final statusCounts = {'Unsolved': 0, 'In Progress': 0, 'Solved': 0};
          final categoryCounts = <String, int>{};

          for (var report in reports) {
            final data = report.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'Unsolved';
            final category = data['category'] ?? 'Unknown';

            statusCounts[status] = (statusCounts[status] ?? 0) + 1;
            categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reports Analysis', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Total Reports: $total'),
                  const SizedBox(height: 16),
                  Text('Status:', style: GoogleFonts.inter(fontSize: 18)),
                  ...statusCounts.entries.map((e) => Text('${e.key}: ${e.value}')),
                  const SizedBox(height: 16),
                  Text('Categories:', style: GoogleFonts.inter(fontSize: 18)),
                  ...categoryCounts.entries.map((e) => Text('${e.key}: ${e.value}')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Page for NGO Analysis
class NGOAnalysisPage extends StatelessWidget {
  const NGOAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NGO Analysis', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('approved-ngos').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> ngoSnapshot) {
          if (!ngoSnapshot.hasData) return const Center(child: SpinKitFadingCircle(color: Colors.blue));
          final ngos = ngoSnapshot.data!.docs;

          return StreamBuilder(
            stream: FirebaseFirestore.instance.collection('reports').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> reportSnapshot) {
              if (!reportSnapshot.hasData) return const Center(child: SpinKitFadingCircle(color: Colors.blue));
              final reports = reportSnapshot.data!.docs;

              // Initialize NGO stats
              final ngoStats = <String, Map<String, int>>{};
              for (var ngo in ngos) {
                final ngoData = ngo.data() as Map<String, dynamic>;
                final ngoName = ngoData['ngoName'] ?? 'Unnamed NGO';
                ngoStats[ngoName] = {'Pending': 0, 'Solved': 0};
              }

              // Process Reports
              for (var report in reports) {
                final reportData = report.data() as Map<String, dynamic>;
                final assignedNGOId = reportData['assignedNGOId'] as String?;
                final status = reportData['status'] ?? 'Unsolved';

                if (assignedNGOId != null) {
                  final ngoList = ngos.where((n) => n.id == assignedNGOId).toList();
                  if (ngoList.isNotEmpty) {
                    final ngoName = (ngoList.first.data() as Map<String, dynamic>)['ngoName'] ?? 'Unnamed NGO';
                    if (status == 'Unsolved' || status == 'In Progress') {
                      ngoStats[ngoName]!['Pending'] = (ngoStats[ngoName]!['Pending'] ?? 0) + 1;
                    } else if (status == 'Solved') {
                      ngoStats[ngoName]!['Solved'] = (ngoStats[ngoName]!['Solved'] ?? 0) + 1;
                    }
                  }
                }
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NGO Analysis', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text('NGO Report Statistics:', style: GoogleFonts.inter(fontSize: 18)),
                      if (ngoStats.isEmpty)
                        const Text('No NGOs with assigned reports found.')
                      else
                        ...ngoStats.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.key, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text('Pending: ${e.value['Pending']}'),
                                Text('Solved: ${e.value['Solved']}'),
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
        },
      ),
    );
  }
}
