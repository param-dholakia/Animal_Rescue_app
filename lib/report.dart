import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'google_drive_service.dart';

final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class ReportPageWidget extends StatefulWidget {
  const ReportPageWidget({super.key});

  @override
  State<ReportPageWidget> createState() => _ReportPageWidgetState();
}

class _ReportPageWidgetState extends State<ReportPageWidget> {
  File? _image;
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;
  Position? _currentPosition;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  String? _audioPath;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _recordAudio() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      if (_isRecording) {
        final path = await _recorder.stopRecorder();
        setState(() {
          _audioPath = path;
          _isRecording = false;
        });
      } else {
        await _recorder.startRecorder(toFile: 'audio_record.aac');
        setState(() {
          _isRecording = true;
        });
      }
    } else {
      _showSnackBar('Microphone permission required', Colors.red);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _getLocation() async {
    var status = await Permission.location.request();
    if (!status.isGranted) {
      _showSnackBar('Location permission required', Colors.red);
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });
  }

  /// 🔥 Fetches the latest case ID from Firestore and generates the next case ID
  Future<String> _getNextCaseId() async {
    var reports = await FirebaseFirestore.instance
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (reports.docs.isEmpty) {
      return 'case-1';
    } else {
      String lastCaseId = reports.docs.first.id;
      int caseNumber = int.parse(lastCaseId.split('-')[1]);
      return 'case-${caseNumber + 1}';
    }
  }

  Future<void> _submitReport() async {
    try {
      if (_image == null && _audioPath == null) {
        _showSnackBar(
            'Please capture an image or record an audio.', Colors.red);
        return;
      }

      // Get the next case ID
      String caseId = await _getNextCaseId();
      GoogleDriveService googleDriveService = GoogleDriveService();
      
      // Create folder in Google Drive with the same case ID
      String? folderId =
          await googleDriveService.createCaseFolder(caseId);

      if (folderId == null) {
        _showSnackBar('Failed to create folder on Google Drive.', Colors.red);
        return;
      }

      String? imageUrl;
      String? audioUrl;
      if (_image != null) {
        imageUrl =
            await googleDriveService.uploadFileToCaseFolder(_image!, folderId);
      }
      if (_audioPath != null) {
        audioUrl = await googleDriveService.uploadFileToCaseFolder(
            File(_audioPath!), folderId);
      }

      // Save the report with the case ID as the document ID
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(caseId)
          .set({
        'caseId': caseId,
        'folderUrl': "https://drive.google.com/drive/folders/$folderId",
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
        'category': _selectedCategory,
        'description': _descriptionController.text,
        'location': _currentPosition != null
            ? {
                'latitude': _currentPosition!.latitude,
                'longitude': _currentPosition!.longitude
              }
            : null,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Refresh the page after successful submission
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Report Submitted successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Reset the form and refresh the page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ReportPageWidget()),
      );
    } catch (e) {
      _showSnackBar('Error submitting report: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(title: const Text('Report an Incident')),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    _image != null
                        ? Image.file(_image!,
                            height: 150, width: 150, fit: BoxFit.cover)
                        : const Text('No image selected'),
                    ElevatedButton(
                        onPressed: _pickImage,
                        child: const Icon(Icons.camera_alt)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _recordAudio,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isRecording ? Colors.red : Colors.yellow,
                          ),
                          child: const Icon(Icons.mic),
                        ),
                        if (_audioPath != null)
                          ElevatedButton(
                            onPressed: () async {
                              await _player.startPlayer(fromURI: _audioPath);
                            },
                            child: const Icon(Icons.play_arrow),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: [
                  'Animal Abuse',
                  'Animal Accident',
                  'Animal Health Issue',
                  'Wild Animal'
                ]
                    .map((category) => DropdownMenuItem(
                        value: category, child: Text(category)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Select Category'),
              ),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Description', border: OutlineInputBorder()),
              ),
              ElevatedButton.icon(
                onPressed: _getLocation,
                icon: const Icon(Icons.location_on),
                label: Text(_currentPosition != null
                    ? 'Location: (${_currentPosition!.latitude}, ${_currentPosition!.longitude})'
                    : 'Share Location'),
              ),
              ElevatedButton(
                  onPressed: _submitReport, child: const Text('Submit Report')),
            ],
          ),
        ),
      ),
    );
  }
}