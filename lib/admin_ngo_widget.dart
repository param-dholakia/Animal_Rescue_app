import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'ngo_approval_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class NGORegistriesPage extends StatefulWidget {
  const NGORegistriesPage({super.key});

  @override
  State<NGORegistriesPage> createState() => _NGORegistriesPageState();
}

class _NGORegistriesPageState extends State<NGORegistriesPage> {
  final CollectionReference ngoCollection = FirebaseFirestore.instance.collection('registration-queries');
  final NGOApprovalService _approvalService = NGOApprovalService();
  final Map<String, bool> _selectedNGOs = {};

  void _toggleSelection(String docId) => setState(() => _selectedNGOs[docId] = !(_selectedNGOs[docId] ?? false));

  void _bulkAccept() async {
    for (var docId in _selectedNGOs.keys.where((id) => _selectedNGOs[id]!)) {
      final doc = await ngoCollection.doc(docId).get();
      await _approvalService.approveNGO(docId, doc.data() as Map<String, dynamic>);
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NGO Registries', style: GoogleFonts.inter(fontSize: 22)),
              if (_selectedNGOs.values.any((selected) => selected))
                Row(
                  children: [
                    ElevatedButton(onPressed: _bulkAccept, child: const Text('Accept')),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: _bulkReject, child: const Text('Reject')),
                  ],
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: ngoCollection.orderBy('timestamp', descending: true).snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) return const Center(child: SpinKitFadingCircle(color: Colors.blue));
              final ngos = snapshot.data!.docs;
              return ListView.builder(
                itemCount: ngos.length,
                itemBuilder: (context, index) {
                  final ngo = ngos[index];
                  final data = ngo.data() as Map<String, dynamic>;
                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                  final formattedTimestamp = timestamp != null
                      ? DateFormat('MMM dd, yyyy - HH:mm').format(timestamp)
                      : 'N/A';

                  return Card(
                    child: ListTile(
                      leading: Checkbox(
                        value: _selectedNGOs[ngo.id] ?? false,
                        onChanged: (value) => _toggleSelection(ngo.id),
                      ),
                      title: Text(data['ngoName'] ?? 'N/A', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
                              icon: const Icon(Icons.check),
                              onPressed: () => _approvalService.approveNGO(ngo.id, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => ngoCollection.doc(ngo.id).delete(),
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
    );
  }
}