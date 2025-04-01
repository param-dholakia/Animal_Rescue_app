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

class NGOReportsPage extends StatefulWidget {
  final String ngoName; // Use ngoName instead of ngoEmail
  const NGOReportsPage({super.key, required this.ngoName});

  @override
  State<NGOReportsPage> createState() => _NGOReportsPageState();
}

class _NGOReportsPageState extends State<NGOReportsPage> {
  final CollectionReference reportsCollection = FirebaseFirestore.instance.collection('reports');
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isPlaying = false;
  bool _isLoadingAudio = false;
  bool _showAssigned = true;
  String _statusFilter = 'All';

  @override
  void dispose() {
    _audioPlayer.dispose();
    _commentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _takeCase(String docId) async {
    await reportsCollection.doc(docId).update({
      'assignedTo': widget.ngoName, // Use ngoName for assignedTo
      'status': 'In Progress',
      'takenAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Case taken')));
  }

  Future<void> _completeRescue(String docId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Rescue'),
        content: TextField(
          controller: _commentController,
          decoration: const InputDecoration(labelText: 'Rescue Details'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await reportsCollection.doc(docId).update({
                'status': 'Solved',
                'resolutionComment': _commentController.text,
                'resolvedAt': FieldValue.serverTimestamp(),
                'resolvedBy': widget.ngoName, // Use ngoName for resolvedBy
              });
              _commentController.clear();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rescue completed')));
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _showImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: CachedNetworkImage(imageUrl: imageUrl, height: 300, width: 300, fit: BoxFit.contain),
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
      if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by Case ID',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          DropdownMenuItem(value: 'Unsolved', child: Text('Unsolved')),
                          DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                          DropdownMenuItem(value: 'Solved', child: Text('Solved')),
                        ],
                        onChanged: (value) => setState(() => _statusFilter = value!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _showAssigned,
                      onChanged: (value) => setState(() => _showAssigned = value),
                      activeColor: Colors.blue,
                    ),
                    Text(_showAssigned ? 'Assigned' : 'Unassigned', style: GoogleFonts.inter()),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: reportsCollection.orderBy('timestamp', descending: true).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return const Center(child: SpinKitFadingCircle(color: Colors.blue));
                final reports = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'Unsolved';
                  final caseId = data['caseId']?.toString().toLowerCase() ?? '';
                  final assignedTo = data['assignedTo'];
                  return (_statusFilter == 'All' || status == _statusFilter) &&
                      caseId.contains(_searchController.text.toLowerCase()) &&
                      (_showAssigned ? assignedTo == widget.ngoName : (assignedTo == null || assignedTo == ''));
                }).toList();

                if (reports.isEmpty) {
                  return Center(child: Text('No reports found', style: GoogleFonts.inter(fontSize: 16)));
                }

                return ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final data = reports[index].data() as Map<String, dynamic>;
                    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                    final takenAt = (data['takenAt'] as Timestamp?)?.toDate();
                    final resolvedAt = (data['resolvedAt'] as Timestamp?)?.toDate();
                    final formattedTimestamp = timestamp != null
                        ? DateFormat('MMM dd, yyyy - HH:mm').format(timestamp)
                        : 'N/A';
                    final formattedTakenAt = takenAt != null
                        ? DateFormat('MMM dd, yyyy - HH:mm').format(takenAt)
                        : 'Not Started';
                    final formattedResolvedAt = resolvedAt != null
                        ? DateFormat('MMM dd, yyyy - HH:mm').format(resolvedAt)
                        : 'Not Resolved';
                    final status = data['status'] ?? 'Unsolved';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  data['caseId'] ?? 'N/A',
                                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Chip(
                                  label: Text(status, style: GoogleFonts.inter(color: Colors.white)),
                                  backgroundColor: status == 'Solved'
                                      ? Colors.green
                                      : status == 'In Progress'
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Category: ${data['category'] ?? 'N/A'}', style: GoogleFonts.inter()),
                            TextButton(
                              onPressed: () => _openInGoogleMaps(
                                  data['location']?['latitude'], data['location']?['longitude']),
                              child: const Text('See Location', style: TextStyle(color: Colors.blue)),
                            ),
                            Text('Description: ${data['description'] ?? 'N/A'}', style: GoogleFonts.inter()),
                            Text('Submitted: $formattedTimestamp', style: GoogleFonts.inter(color: Colors.grey)),
                            Text('Started: $formattedTakenAt', style: GoogleFonts.inter(color: Colors.blue)),
                            if (status == 'Solved')
                              Text('Resolved: $formattedResolvedAt', style: GoogleFonts.inter(color: Colors.green)),
                            if (data['resolutionComment'] != null)
                              Text('Details: ${data['resolutionComment']}', style: GoogleFonts.inter(color: Colors.green)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (data['imageUrl'] != null)
                                  IconButton(
                                    icon: const Icon(Icons.image, color: Colors.blue),
                                    onPressed: () => _showImage(data['imageUrl']),
                                  ),
                                if (data['audioUrl'] != null)
                                  IconButton(
                                    icon: const Icon(Icons.audiotrack, color: Colors.blue),
                                    onPressed: () => _playAudio(data['audioUrl']),
                                  ),
                                if (status == 'Unsolved')
                                  IconButton(
                                    icon: const Icon(FontAwesomeIcons.handHolding, color: Colors.blue),
                                    onPressed: () => _takeCase(reports[index].id),
                                    tooltip: 'Take Case',
                                  ),
                                if (status == 'In Progress' && data['assignedTo'] == widget.ngoName)
                                  IconButton(
                                    icon: const Icon(FontAwesomeIcons.checkCircle, color: Colors.green),
                                    onPressed: () => _completeRescue(reports[index].id),
                                    tooltip: 'Complete Rescue',
                                  ),
                              ],
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
      ),
    );
  }
}