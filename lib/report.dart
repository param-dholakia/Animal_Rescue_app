import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
    if (await Permission.microphone.request().isGranted) {
      if (_isRecording) {
        final path = await _recorder.stopRecorder();
        setState(() {
          _audioPath = path;
          _isRecording = false;
        });
        
        String fileName = '${DateTime.now().millisecondsSinceEpoch}.aac';
        Reference ref = FirebaseStorage.instance.ref().child('audio/$fileName');
        await ref.putFile(File(_audioPath!));
      } else {
        await _recorder.startRecorder(toFile: 'audio_record.aac');
        setState(() {
          _isRecording = true;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required')),
      );
    }
  }

  Future<void> _playAudio() async {
    if (_audioPath != null) {
      await _player.startPlayer(fromURI: _audioPath!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audio recorded')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      String fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      Reference ref = FirebaseStorage.instance.ref().child('images/$fileName');
      await ref.putFile(_image!);
    }
  }

  Future<void> _getLocation() async {
    final permissionStatus = await Permission.location.request();
    if (permissionStatus.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentPosition = position;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get location. Please try again.')),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    try {
      if (_image != null) {
        String imageUrl = await _uploadFile(_image!, 'images');
        
        String? audioUrl;
        if (_audioPath != null) {
          audioUrl = await _uploadFile(File(_audioPath!), 'audio');
        }

        await FirebaseFirestore.instance.collection('reports').add({
          'imageUrl': imageUrl,
          'audioUrl': audioUrl,
          'category': _selectedCategory,
          'description': _descriptionController.text,
          'location': _currentPosition != null
              ? {'latitude': _currentPosition!.latitude, 'longitude': _currentPosition!.longitude}
              : null,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image before submitting.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting report: $e')),
      );
    }
  }

  Future<String> _uploadFile(File file, String folder) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}';
      Reference ref = FirebaseStorage.instance.ref().child('$folder/$fileName');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('File upload failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Incident'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text('Click a photo or record audio',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Center(
              child: Column(
                children: [
                  _image != null
                      ? Image.file(_image!, height: 150, width: 150, fit: BoxFit.cover)
                      : const Text('No image selected'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Icon(Icons.camera_alt),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitReport,
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }
}