import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class ReportManagementPage extends StatefulWidget {
  const ReportManagementPage({super.key});

  @override
  State<ReportManagementPage> createState() => _ReportManagementPageState();
}

class _ReportManagementPageState extends State<ReportManagementPage> {
  final CollectionReference reportsCollection = FirebaseFirestore.instance.collection('reports');
  final CollectionReference ngoCollection = FirebaseFirestore.instance.collection('approved-ngos');
  String _statusFilter = 'All';
  String _searchQuery = '';
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoadingAudio = false;
  final Map<String, bool> _selectedReports = {};

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _assignToNGO(String docId, String ngoId) async {
    await reportsCollection.doc(docId).update({'assignedTo': ngoId, 'status': 'In Progress'});
    final reportDoc = await reportsCollection.doc(docId).get();
    _notifyNGO(ngoId, docId, reportDoc.data() as Map<String, dynamic>);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report assigned')));
  }

  void _notifyNGO(String ngoId, String reportId, Map<String, dynamic> reportData) async {
    final ngoDoc = await ngoCollection.doc(ngoId).get();
    final ngoEmail = ngoDoc['email'];
    final smtpServer = gmail('your-email@gmail.com', 'your-app-password');
    final message = Message()
      ..from = const Address('your-email@gmail.com', 'Admin')
      ..recipients.add(ngoEmail)
      ..subject = 'New Report Assignment: ${reportData['caseId']}'
      ..text = 'A new report has been assigned to your NGO.\nCase ID: ${reportData['caseId']}\nDescription: ${reportData['description']}';

    try {
      await send(message, smtpServer);
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  void _updateReport(String docId, Map<String, dynamic> data) async {
    String newStatus = data['status'] == 'Solved' ? 'Unsolved' : 'Solved';
    await reportsCollection.doc(docId).update({'status': newStatus});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
  }

  void _deleteReport(String docId) async {
    await reportsCollection.doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report deleted')));
  }

  void _showImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CachedNetworkImage(imageUrl: imageUrl, height: 300, width: 300, fit: BoxFit.contain),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  void _playAudio(String audioUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Playing Audio', style: TextStyle(fontSize: 18)),
              _isLoadingAudio
                  ? const SpinKitFadingCircle(color: Colors.blue, size: 50)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                          onPressed: () async {
                            if (_isPlaying) {
                              await _audioPlayer.pause();
                              setState(() => _isPlaying = false);
                            } else {
                              setState(() => _isLoadingAudio = true);
                              await _audioPlayer.play(UrlSource(audioUrl));
                              setState(() {
                                _isPlaying = true;
                                _isLoadingAudio = false;
                              });
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.stop),
                          onPressed: () async {
                            await _audioPlayer.stop();
                            setState(() => _isPlaying = false);
                          },
                        ),
                      ],
                    ),
              TextButton(
                onPressed: () async {
                  await _audioPlayer.stop();
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInGoogleMaps(double? latitude, double? longitude) async {
    if (latitude != null && longitude != null) {
      final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }

  void _showAssignNGODialog(String reportId, Map<String, dynamic> reportData) async {
    final ngoSnapshot = await ngoCollection.get();
    String searchQuery = '';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Assign NGO'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Search NGOs'),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
              SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView(
                  shrinkWrap: true,
                  children: ngoSnapshot.docs
                      .where((doc) => doc['ngoName'].toLowerCase().contains(searchQuery.toLowerCase()))
                      .map((doc) => ListTile(
                            title: Text(doc['ngoName']),
                            subtitle: Text('Email: ${doc['email']}'),
                            onTap: () {
                              _assignToNGO(reportId, doc.id);
                              Navigator.pop(context);
                            },
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkAssignDialog() async {
    final ngoSnapshot = await ngoCollection.get();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Selected Reports'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: ngoSnapshot.docs
                .map((doc) => ListTile(
                      title: Text(doc['ngoName']),
                      onTap: () async {
                        for (var reportId in _selectedReports.keys.where((id) => _selectedReports[id]!)) {
                          _assignToNGO(reportId, doc.id);
                        }
                        setState(() => _selectedReports.clear());
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search by Case ID',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _statusFilter,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All')),
                  DropdownMenuItem(value: 'Unsolved', child: Text('Unsolved')),
                  DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'Solved', child: Text('Solved')),
                ],
                onChanged: (value) => setState(() => _statusFilter = value!),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reports', style: GoogleFonts.inter(fontSize: 22)),
              if (_selectedReports.values.any((selected) => selected))
                ElevatedButton(
                  onPressed: () => _showBulkAssignDialog(),
                  child: const Text('Assign Selected'),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: reportsCollection.orderBy('timestamp', descending: true).snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) return const Center(child: SpinKitFadingCircle(color: Colors.blue));
              final filteredReports = snapshot.data!.docs.where((report) {
                final data = report.data() as Map<String, dynamic>;
                final status = data['status'] ?? 'Unsolved';
                final caseId = data['caseId']?.toString().toLowerCase() ?? '';
                return (_statusFilter == 'All' || status == _statusFilter) &&
                    caseId.contains(_searchQuery.toLowerCase());
              }).toList();

              return ListView.builder(
                itemCount: filteredReports.length,
                itemBuilder: (context, index) {
                  final report = filteredReports[index];
                  final data = report.data() as Map<String, dynamic>;
                  final location = data['location'] as Map<String, dynamic>?;
                  final status = data['status'] ?? 'Unsolved';
                  final hasImage = data['imageUrl'] != null;
                  final hasAudio = data['audioUrl'] != null;
                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                  final formattedTimestamp = timestamp != null
                      ? DateFormat('MMM dd, yyyy - HH:mm').format(timestamp)
                      : 'N/A';
                  final resolvedAt = (data['resolvedAt'] as Timestamp?)?.toDate();
                  final resolvedTimestamp = resolvedAt != null
                      ? DateFormat('MMM dd, yyyy - HH:mm').format(resolvedAt)
                      : 'N/A';

                  return Card(
                    color: data['assignedTo'] != null && data['assignedTo'] != 'Unassigned' ? Colors.blue[50] : null,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      leading: Checkbox(
                        value: _selectedReports[report.id] ?? false,
                        onChanged: (value) => setState(() => _selectedReports[report.id] = value!),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(data['caseId'] ?? 'N/A', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          Text(status,
                              style: GoogleFonts.inter(
                                  color: status == 'Solved' ? Colors.green : Colors.orange)),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Category: ${data['category'] ?? 'N/A'}'),
                          TextButton(
                            onPressed: () => _openInGoogleMaps(location?['latitude'], location?['longitude']),
                            child: const Text('See Location'),
                          ),
                          Text('Description: ${data['description'] ?? 'N/A'}'),
                          Text('Assigned To: ${data['assignedTo'] ?? 'Unassigned'}'),
                          Text('Submitted: $formattedTimestamp'),
                          if (data['resolutionComment'] != null) ...[
                            Text('Rescue Details: ${data['resolutionComment']}', style: GoogleFonts.inter(color: Colors.green)),
                            Text('Resolved: $resolvedTimestamp', style: GoogleFonts.inter(color: Colors.green)),
                          ],
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.image, color: hasImage ? Colors.blue : Colors.grey),
                                onPressed: hasImage ? () => _showImage(data['imageUrl']) : null,
                              ),
                              IconButton(
                                icon: Icon(Icons.audiotrack, color: hasAudio ? Colors.blue : Colors.grey),
                                onPressed: hasAudio ? () => _playAudio(data['audioUrl']) : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (data['assignedTo'] == null || data['assignedTo'] == 'Unassigned')
                            IconButton(
                              icon: const Icon(FontAwesomeIcons.userPlus),
                              onPressed: () => _showAssignNGODialog(report.id, data),
                            ),
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
                  ).animate().fadeIn(duration: 300.ms);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}