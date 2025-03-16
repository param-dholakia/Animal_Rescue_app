import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'google_drive_service.dart';

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
      _showSnackBar('Microphone permission required');
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
      _showSnackBar('Location permission required');
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _submitReport() async {
    try {
      if (_image == null && _audioPath == null) {
        _showSnackBar('Please capture an image or record an audio.');
        return;
      }

      String caseId = DateTime.now().millisecondsSinceEpoch.toString();
      String caseFolderName = 'case-$caseId';
      GoogleDriveService googleDriveService = GoogleDriveService();
      String? folderId = await googleDriveService.createCaseFolder(caseFolderName);
      if (folderId == null) {
        _showSnackBar('Failed to create folder on Google Drive.');
        return;
      }

      String? imageUrl;
      String? audioUrl;
      if (_image != null) {
        imageUrl = await googleDriveService.uploadFileToCaseFolder(_image!, folderId);
      }
      if (_audioPath != null) {
        audioUrl = await googleDriveService.uploadFileToCaseFolder(File(_audioPath!), folderId);
      }

      await FirebaseFirestore.instance.collection('reports').add({
        'caseId': caseId,
        'folderUrl': "https://drive.google.com/drive/folders/$folderId",
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
        'category': _selectedCategory,
        'description': _descriptionController.text,
        'location': _currentPosition != null
            ? {'latitude': _currentPosition!.latitude, 'longitude': _currentPosition!.longitude}
            : null,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Report submitted successfully!');
    } catch (e) {
      _showSnackBar('Error submitting report: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      ? Image.file(_image!, height: 150, width: 150, fit: BoxFit.cover)
                      : const Text('No image selected'),
                  ElevatedButton(onPressed: _pickImage, child: const Icon(Icons.camera_alt)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _recordAudio,
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
              items: ['Animal Abuse', 'Animal Accident', 'Animal Health Issue', 'Wild Animal']
                  .map((category) => DropdownMenuItem(value: category, child: Text(category)))
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
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
            ElevatedButton.icon(
              onPressed: _getLocation,
              icon: const Icon(Icons.location_on),
              label: Text(_currentPosition != null
                  ? 'Location: (${_currentPosition!.latitude}, ${_currentPosition!.longitude})'
                  : 'Share Location'),
            ),
            ElevatedButton(onPressed: _submitReport, child: const Text('Submit Report')),
          ],
        ),
      ),
    );
  }
}