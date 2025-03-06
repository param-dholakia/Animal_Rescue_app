import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
// ignore: unused_import
import 'package:google_api_headers/google_api_headers.dart';
import 'package:geolocator/geolocator.dart';

class ReportPageWidget extends StatefulWidget {
  const ReportPageWidget({super.key});

  @override
  State<ReportPageWidget> createState() => _ReportPageWidgetState();
}

class _ReportPageWidgetState extends State<ReportPageWidget> {
  File? _image;
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;
  LatLng? _selectedLocation;
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  String? _audioPath;
  bool _isRecording = false;
  static const String googleMapsApiKey = "YOUR_GOOGLE_MAPS_API_KEY"; // Replace with your API key

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
    }
  }

  Future<void> _selectLocation(BuildContext context) async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlacePicker(
          apiKey: googleMapsApiKey,
          onPlacePicked: (result) {
            setState(() {
              _selectedLocation = LatLng(
                  result.geometry!.location.lat, result.geometry!.location.lng);
            });
            Navigator.of(context).pop();
          },
          initialPosition: LatLng(position.latitude, position.longitude),
          useCurrentLocation: true,
        ),
      ),
    );
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
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(15),
                    ),
                    child: const Icon(Icons.camera_alt),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _recordAudio,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(15),
                          backgroundColor: _isRecording ? Colors.red : null,
                        ),
                        child: const Icon(Icons.mic),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: _playAudio,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(10),
                        ),
                        child: const Icon(Icons.play_arrow),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: [
                'Animal Abuse',
                'Animal Accident',
                'Animal Health Issue',
                'Wild Animal',
              ].map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Select Category'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _selectLocation(context),
              icon: const Icon(Icons.map),
              label: Text(_selectedLocation != null
                  ? 'Location Selected: (${_selectedLocation!.latitude}, ${_selectedLocation!.longitude})'
                  : 'Pick Location on Map'),
            ),
          ],
        ),
      ),
    );
  }
}