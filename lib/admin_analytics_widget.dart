import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Analytics', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Total Reports: $total'),
              const SizedBox(height: 16),
              Text('Status:', style: GoogleFonts.inter(fontSize: 18)),
              ...statusCounts.entries.map((e) => Text('${e.key}: ${e.value}')),
              const SizedBox(height: 16),
              Text('Categories:', style: GoogleFonts.inter(fontSize: 18)),
              ...categoryCounts.entries.map((e) => Text('${e.key}: ${e.value}')),
            ],
          ),
        );
      },
    );
  }
}