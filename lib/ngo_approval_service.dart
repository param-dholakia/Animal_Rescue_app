import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:math';

class NGOApprovalService {
  // Generate a random password
  String _generateRandomPassword() {
    const String chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
          12, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  // Send email to the NGO with login credentials
  Future<String> _sendApprovalEmail(
      String email, String ngoName, String password) async {
    // Replace with your SMTP server details (e.g., Gmail SMTP)
    final smtpServer = gmail('paramdholakia1@gmail.com', 'wjhjqvbwhlfukczs');

    // Create the email message
    final message = Message()
      ..from = const Address('paramdholakia1@gmail.com', 'Paw Saviour Admin')
      ..recipients.add(email)
      ..subject = 'Paw Saviour: NGO Registration Approved'
      ..text = '''
Dear $ngoName,

We are pleased to inform you that your NGO registration with Paw Saviour has been approved!

You can now log in to the Paw Saviour platform using the following credentials:
- Login ID: $email
- Password: $password

Please keep this password secure and do not share it with others. You can change your password after logging in if needed.

To log in, visit the Paw Saviour app and use the "NGO Login" option.

If you have any questions or need assistance, feel free to contact us at meetd19174@gmail.com.

Thank you for joining us in our mission to help animals in need!

Best regards,
The Paw Saviour Team
''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Email sent successfully: ${sendReport.toString()}');
      return 'Email sent successfully';
    } catch (e) {
      print('Error sending email: $e');
      return 'Failed to send email: $e';
    }
  }

  // Approve the NGO: Move to approved-ngos, generate password, and attempt to send email
  Future<String> approveNGO(String ngoId, Map<String, dynamic> ngoData) async {
    try {
      // Generate a random password
      String generatedPassword = _generateRandomPassword();

      // Add the generated password to the NGO data
      ngoData['password'] = generatedPassword;

      // Move the NGO to the approved-ngos collection
      print('Adding NGO to approved-ngos: $ngoId');
      await FirebaseFirestore.instance
          .collection('approved-ngos')
          .doc(ngoId)
          .set(ngoData);

      // Delete the NGO from the registration-queries collection
      print('Deleting NGO from registration-queries: $ngoId');
      await FirebaseFirestore.instance
          .collection('registration-queries')
          .doc(ngoId)
          .delete();

      // Attempt to send the approval email
      print('Sending approval email to: ${ngoData['email']}');
      String emailResult = await _sendApprovalEmail(
          ngoData['email'], ngoData['ngoName'], generatedPassword);

      if (emailResult.startsWith('Failed')) {
        // Email failed, but the NGO is still approved
        return 'NGO approved, but failed to send email: ${emailResult.split(': ')[1]}';
      }

      return 'NGO approved and email sent successfully';
    } catch (e) {
      print('Error in approveNGO: $e');
      throw Exception('Error approving NGO: $e');
    }
  }
}
