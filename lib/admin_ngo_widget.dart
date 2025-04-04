import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'ngo_approval_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class NGOAdminPanel extends StatelessWidget {
  const NGOAdminPanel({super.key});

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
                  MaterialPageRoute(
                      builder: (context) => const NGORegistriesPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('NGO Registries',
                  style: GoogleFonts.inter(fontSize: 18)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NGOManagementPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('NGO Management',
                  style: GoogleFonts.inter(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

class NGORegistriesPage extends StatefulWidget {
  const NGORegistriesPage({super.key});

  @override
  State<NGORegistriesPage> createState() => _NGORegistriesPageState();
}

class _NGORegistriesPageState extends State<NGORegistriesPage> {
  final CollectionReference ngoCollection =
      FirebaseFirestore.instance.collection('registration-queries');
  final NGOApprovalService _approvalService = NGOApprovalService();
  final Map<String, bool> _selectedNGOs = {};

  void _toggleSelection(String docId) =>
      setState(() => _selectedNGOs[docId] = !(_selectedNGOs[docId] ?? false));

  void _bulkAccept() async {
    for (var docId in _selectedNGOs.keys.where((id) => _selectedNGOs[id]!)) {
      final doc = await ngoCollection.doc(docId).get();
      await _approvalService.approveNGO(
          docId, doc.data() as Map<String, dynamic>);
    }
    setState(() => _selectedNGOs.clear());
  }

  void _bulkReject() async {
    for (var docId in _selectedNGOs.keys.where((id) => _selectedNGOs[id]!)) {
      await ngoCollection.doc(docId).delete();
    }
    setState(() => _selectedNGOs.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NGO Registries',
            style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('NGO Registration Requests',
                    style: GoogleFonts.inter(fontSize: 17)),
                if (_selectedNGOs.values.any((selected) => selected))
                  Row(
                    children: [
                      ElevatedButton(
                          onPressed: _bulkAccept, child: const Text('Accept')),
                      const SizedBox(width: 8),
                      OutlinedButton(
                          onPressed: _bulkReject, child: const Text('Reject')),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: ngoCollection
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData)
                  return const Center(
                      child: SpinKitFadingCircle(color: Colors.blue));
                final ngos = snapshot.data!.docs;
                if (ngos.isEmpty)
                  return const Center(
                      child: Text('No registration requests found'));
                return ListView.builder(
                  itemCount: ngos.length,
                  itemBuilder: (context, index) {
                    final ngo = ngos[index];
                    final data = ngo.data() as Map<String, dynamic>;
                    final timestamp =
                        (data['timestamp'] as Timestamp?)?.toDate();
                    final formattedTimestamp = timestamp != null
                        ? DateFormat('MMM dd, yyyy - HH:mm').format(timestamp)
                        : 'N/A';

                    return Card(
                      child: ListTile(
                        leading: Checkbox(
                          value: _selectedNGOs[ngo.id] ?? false,
                          onChanged: (value) => _toggleSelection(ngo.id),
                        ),
                        title: Text(data['ngoName'] ?? 'N/A',
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${data['status'] ?? 'Pending'}'),
                            Text('Email: ${data['email'] ?? 'N/A'}'),
                            Text('Phone: ${data['phone'] ?? 'N/A'}'),
                            Text('Submitted: $formattedTimestamp'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (data['status'] == 'pending') ...[
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () =>
                                    _approvalService.approveNGO(ngo.id, data),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () =>
                                    ngoCollection.doc(ngo.id).delete(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
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

class NGOManagementPage extends StatefulWidget {
  const NGOManagementPage({super.key});

  @override
  State<NGOManagementPage> createState() => _NGOManagementPageState();
}

class _NGOManagementPageState extends State<NGOManagementPage> {
  final CollectionReference approvedNGOsCollection =
      FirebaseFirestore.instance.collection('approved-ngos');

  void _removeNGO(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Removal'),
        content: const Text('Are you sure you want to remove this NGO?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await approvedNGOsCollection.doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NGO removed successfully')));
    }
  }

  void _viewDetails(String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['ngoName'] ?? 'NGO Details',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${data['email'] ?? 'N/A'}'),
              Text('Phone: ${data['phone'] ?? 'N/A'}'),
              Text('Address: ${data['address'] ?? 'N/A'}'),
              Text('Description: ${data['description'] ?? 'N/A'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NGO Management',
            style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                Text('Approved NGOs', style: GoogleFonts.inter(fontSize: 22)),
          ),
          Expanded(
            child: StreamBuilder(
              // Removed orderBy to test raw collection fetch
              stream: approvedNGOsCollection.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  print('Error in StreamBuilder: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  print('No data in snapshot for approved-ngos');
                  return const Center(
                      child: SpinKitFadingCircle(color: Colors.blue));
                }
                final ngos = snapshot.data!.docs;
                print('Number of approved NGOs: ${ngos.length}');
                if (ngos.isEmpty) {
                  print('Approved NGOs collection is empty or not accessible');
                  return const Center(child: Text('No approved NGOs found'));
                }
                for (var ngo in ngos) {
                  print('NGO ID: ${ngo.id}, Data: ${ngo.data()}');
                }
                return ListView.builder(
                  itemCount: ngos.length,
                  itemBuilder: (context, index) {
                    final ngo = ngos[index];
                    final data = ngo.data() as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        title: Text(data['ngoName'] ?? 'N/A',
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: ${data['email'] ?? 'N/A'}'),
                            Text('Phone: ${data['phone'] ?? 'N/A'}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.info, color: Colors.blue),
                              onPressed: () => _viewDetails(ngo.id, data),
                              tooltip: 'View Details',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeNGO(ngo.id),
                              tooltip: 'Remove NGO',
                            ),
                          ],
                        ),
                      ),
                    );
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
