// admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';

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

  final List<Widget> _pages = [
    const ReportManagementPage(),
    const AnalyticsPage(),
    const ContentManagementPage(),
    const PushNotificationPage(),
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
        elevation: 10,
      ),
    );
  }
}

class ReportManagementPage extends StatefulWidget {
  const ReportManagementPage({super.key});

  @override
  State<ReportManagementPage> createState() => _ReportManagementPageState();
}

class _ReportManagementPageState extends State<ReportManagementPage> {
  final CollectionReference reportsCollection = FirebaseFirestore.instance.collection('reports');
  String _statusFilter = 'All'; // Filter for status: "All", "Unsolved", "Solved"
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoadingAudio = false; // Track audio loading state

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updateReport(String docId, Map<String, dynamic> currentData) async {
    try {
      String newStatus = (currentData['status'] == 'Solved') ? 'Unsolved' : 'Solved';
      await reportsCollection.doc(docId).update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating report: $e')));
    }
  }

  void _deleteReport(String docId) async {
    try {
      await reportsCollection.doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report deleted')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting report: $e')));
    }
  }

  void _showImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Icon(Icons.error, color: Colors.red, size: 50),
                ),
                fit: BoxFit.contain,
                height: 300,
                width: 300,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: Colors.blue)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playAudio(String audioUrl) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Playing Audio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              _isLoadingAudio
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                          onPressed: () async {
                            if (_isPlaying) {
                              await _audioPlayer.pause();
                              setState(() {
                                _isPlaying = false;
                              });
                            } else {
                              setState(() {
                                _isLoadingAudio = true;
                              });
                              try {
                                await _audioPlayer.play(UrlSource(audioUrl));
                                setState(() {
                                  _isPlaying = true;
                                  _isLoadingAudio = false;
                                });
                              } catch (e) {
                                setState(() {
                                  _isLoadingAudio = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error playing audio: $e')),
                                );
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop),
                          onPressed: () async {
                            await _audioPlayer.stop();
                            setState(() {
                              _isPlaying = false;
                            });
                          },
                        ),
                      ],
                    ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextButton(
                  onPressed: () async {
                    await _audioPlayer.stop();
                    setState(() {
                      _isPlaying = false;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Close', style: TextStyle(color: Colors.blue)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Status Filter Dropdown
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButton<String>(
            value: _statusFilter,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All Reports')),
              DropdownMenuItem(value: 'Unsolved', child: Text('Unsolved Reports')),
              DropdownMenuItem(value: 'Solved', child: Text('Solved Reports')),
            ],
            onChanged: (value) {
              setState(() {
                _statusFilter = value!;
              });
            },
          ),
        ),
        // Report List
        Expanded(
          child: StreamBuilder(
            stream: reportsCollection.orderBy('timestamp', descending: true).snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final reports = snapshot.data!.docs;
              final filteredReports = reports.where((report) {
                final data = report.data() as Map<String, dynamic>;
                final status = data['status'] ?? 'Unsolved';
                return _statusFilter == 'All' || status == _statusFilter;
              }).toList();

              if (filteredReports.isEmpty) {
                return const Center(child: Text('No reports available'));
              }
              return ListView.builder(
                itemCount: filteredReports.length,
                itemBuilder: (context, index) {
                  final report = filteredReports[index];
                  final data = report.data() as Map<String, dynamic>;
                  final location = data['location'] as Map<String, dynamic>?;
                  final status = (data['status'] ?? 'Unsolved').toString().trim();
                  print('Report ${data['caseId']}: Status = "$status"');
                  final hasImage = data['imageUrl'] != null;
                  final hasAudio = data['audioUrl'] != null;
                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                  final formattedTimestamp = timestamp != null
                      ? DateFormat('MMM dd, yyyy - HH:mm').format(timestamp)
                      : 'N/A';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              data['caseId'] ?? 'Case ID N/A',
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              status,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: status.toLowerCase() == 'solved' ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        subtitle: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.3,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Category: ${data['category'] ?? 'N/A'}'),
                                Text(
                                  'Location: ${location != null ? "${location['latitude']}, ${location['longitude']}" : 'N/A'}',
                                ),
                                Text(
                                  'Description: ${data['description'] ?? 'No Description'}',
                                  style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                                ),
                                Text(
                                  'Submitted: $formattedTimestamp',
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.remove_red_eye,
                                        color: hasImage ? Colors.blue : Colors.grey,
                                      ),
                                      onPressed: hasImage ? () => _showImage(data['imageUrl']) : null,
                                      tooltip: 'View Image',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.remove_red_eye,
                                        color: hasAudio ? Colors.blue : Colors.grey,
                                      ),
                                      onPressed: hasAudio ? () => _playAudio(data['audioUrl']) : null,
                                      tooltip: 'Play Audio',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _updateReport(report.id, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteReport(report.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CollectionReference reportsCollection = FirebaseFirestore.instance.collection('reports');

    return StreamBuilder(
      stream: reportsCollection.snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snapshot.data!.docs;
        final totalReports = reports.length;
        final categoryCounts = <String, int>{};
        for (var report in reports) {
          final data = report.data() as Map<String, dynamic>;
          final category = data['category'] ?? 'Unknown';
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics Dashboard',
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text('Total Reports: $totalReports', style: GoogleFonts.inter(fontSize: 18)),
              const SizedBox(height: 10),
              Text('Reports by Category:', style: GoogleFonts.inter(fontSize: 18)),
              const SizedBox(height: 8),
              ...categoryCounts.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: GoogleFonts.inter(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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