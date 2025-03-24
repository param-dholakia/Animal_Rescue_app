// google_drive_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/services.dart' show rootBundle;

class GoogleDriveService {
  drive.DriveApi? _driveApi;

  Future<void> authenticateWithGoogleDrive() async {
    try {
      print('Starting Google Drive authentication...');
      final credentials = await rootBundle.loadString('assets/pawsaviour1-2766f14f96af.json');
      print('Loaded credentials: ${credentials.substring(0, 50)}...');
      final serviceAccount = auth.ServiceAccountCredentials.fromJson(jsonDecode(credentials));
      print('Parsed service account credentials.');

      final client = await auth.clientViaServiceAccount(
        serviceAccount,
        [drive.DriveApi.driveFileScope],
      );
      print('Authenticated with Google Drive successfully.');

      _driveApi = drive.DriveApi(client);
    } catch (e) {
      print('Error authenticating with Google Drive: $e');
      rethrow;
    }
  }

  Future<String> createCaseFolder(String caseNumber) async {
    if (_driveApi == null) {
      print('Drive API is null, authenticating...');
      await authenticateWithGoogleDrive();
    }

    final drive.File folder = drive.File()
      ..name = "case-$caseNumber"
      ..mimeType = "application/vnd.google-apps.folder"
      ..parents = ["1LRjIa12Fwdy2jlKW5vDZH84xfjuO-2RO"];

    try {
      print('Creating folder for case: $caseNumber');
      final createdFolder = await _driveApi!.files.create(folder);
      print('Folder created with ID: ${createdFolder.id}');

      final permission = drive.Permission()
        ..type = 'anyone'
        ..role = 'reader';
      await _driveApi!.permissions.create(permission, createdFolder.id!);
      print('Set folder permissions to "Anyone with the link"');

      if (createdFolder.id == null) {
        throw Exception('Failed to create folder: No folder ID returned');
      }
      return "https://drive.google.com/drive/folders/${createdFolder.id}";
    } catch (e) {
      print('Error creating folder: $e');
      throw Exception('Failed to create folder: $e');
    }
  }

  Future<String> uploadFileToCaseFolder(File file, String folderId) async {
    if (_driveApi == null) {
      print('Drive API is null, authenticating...');
      await authenticateWithGoogleDrive();
    }

    final drive.File driveFile = drive.File()
      ..name = file.path.split('/').last
      ..parents = [folderId];

    final drive.Media media = drive.Media(file.openRead(), file.lengthSync());

    try {
      print('Uploading file: ${file.path} to folder ID: $folderId');
      final uploadedFile = await _driveApi!.files.create(driveFile, uploadMedia: media);
      print('File uploaded with ID: ${uploadedFile.id}');

      final permission = drive.Permission()
        ..type = 'anyone'
        ..role = 'reader';
      await _driveApi!.permissions.create(permission, uploadedFile.id!);
      print('Set file permissions to "Anyone with the link"');

      if (uploadedFile.id == null) {
        throw Exception('Failed to upload file: No file ID returned');
      }
      return "https://drive.google.com/uc?export=download&id=${uploadedFile.id}";
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Failed to upload file: $e');
    }
  }
}