import 'dart:convert';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart' show rootBundle;

class GoogleDriveService {
  drive.DriveApi? _driveApi;

  Future<String?> createCaseFolder(String caseNumber) async {
    if (_driveApi == null) {
      await authenticateWithGoogleDrive();
    }

    final drive.File folder = drive.File();
    folder.name = "case-$caseNumber";
    folder.mimeType = "application/vnd.google-apps.folder";
    folder.parents = [
      "1LRjIa12Fwdy2jlKW5vDZH84xfjuO-2RO"
    ]; // Parent folder ID of "Paw Saviour"

    final createdFolder = await _driveApi!.files.create(folder);
    return createdFolder.id; // Return folder ID
  }
  
  Future<String?> uploadFileToCaseFolder(File file, String folderId) async {
    if (_driveApi == null) {
      await authenticateWithGoogleDrive();
    }

    final drive.File driveFile = drive.File();
    driveFile.name = file.path.split('/').last; // Use the file name
    driveFile.parents = [folderId];

    final drive.Media media = drive.Media(file.openRead(), file.lengthSync());

    final uploadedFile = await _driveApi!.files.create(driveFile, uploadMedia: media);
    return uploadedFile.id != null ? "https://drive.google.com/file/d/${uploadedFile.id}/view" : null;
  }

  Future<void> authenticateWithGoogleDrive() async {
    final credentials =
        await rootBundle.loadString('assets/pawsaviour1-736680debc9a.json');
    final serviceAccount =
        auth.ServiceAccountCredentials.fromJson(jsonDecode(credentials));

    final client = await auth.clientViaServiceAccount(
      serviceAccount,
      [drive.DriveApi.driveFileScope],
    );

    _driveApi = drive.DriveApi(client);
  }

  Future<String?> uploadFileToDrive(File file, String folderId) async {
    if (_driveApi == null) {
      await authenticateWithGoogleDrive();
    }

    final drive.File driveFile = drive.File();
    driveFile.name = path.basename(file.path);
    driveFile.parents = [folderId];

    final media = drive.Media(file.openRead(), file.lengthSync());
    final uploadedFile =
        await _driveApi!.files.create(driveFile, uploadMedia: media);

    return uploadedFile.id != null
        ? "https://drive.google.com/file/d/${uploadedFile.id}/view"
        : null;
  }
}
