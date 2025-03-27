import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPageWidget extends StatefulWidget {
  const RegisterPageWidget({super.key});

  @override
  State<RegisterPageWidget> createState() => _RegisterPageWidgetState();
}

class _RegisterPageWidgetState extends State<RegisterPageWidget> {
  final _formKey = GlobalKey<FormState>();
  final _ngoNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaOfOperationController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedService;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _ngoNameController.dispose();
    _registrationNumberController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _areaOfOperationController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        String ngoName = _ngoNameController.text.trim();

        // Check if an NGO with the same name already exists
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('registration-queries')
            .doc(ngoName)
            .get();

        if (doc.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An NGO with this name already exists!'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        // Save the registration details to Firestore with ngoName as the document ID
        await FirebaseFirestore.instance
            .collection('registration-queries')
            .doc(ngoName)
            .set({
          'ngoName': ngoName,
          'registrationNumber': _registrationNumberController.text.trim(),
          'contactPerson': _contactPersonController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'areaOfOperation': _areaOfOperationController.text.trim(),
          'servicesOffered': _selectedService,
          'website': _websiteController.text.trim(),
          'description': _descriptionController.text.trim(),
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration submitted successfully! Awaiting admin approval.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Reset the form
        setState(() {
          _ngoNameController.clear();
          _registrationNumberController.clear();
          _contactPersonController.clear();
          _emailController.clear();
          _phoneController.clear();
          _addressController.clear();
          _areaOfOperationController.clear();
          _websiteController.clear();
          _descriptionController.clear();
          _selectedService = null;
        });

        // Navigate back to the home page after a short delay
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting registration: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NGO Registration'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: Theme.of(context).primaryColor,
              child: const Column(
                children: [
                  Icon(
                    Icons.group_add,
                    color: Colors.white,
                    size: 50,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Register Your NGO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Form Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _ngoNameController,
                          decoration: InputDecoration(
                            labelText: 'NGO Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the NGO name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _registrationNumberController,
                          decoration: InputDecoration(
                            labelText: 'NGO Registration Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the NGO registration number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contactPersonController,
                          decoration: InputDecoration(
                            labelText: 'Contact Person',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the contact person\'s name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an email address';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a phone number';
                            }
                            if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(value)) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _areaOfOperationController,
                          decoration: InputDecoration(
                            labelText: 'Area of Operation (e.g., City, State)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the area of operation';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedService,
                          items: const [
                            DropdownMenuItem(value: 'Animal Rescue', child: Text('Animal Rescue')),
                            DropdownMenuItem(value: 'Veterinary Care', child: Text('Veterinary Care')),
                            DropdownMenuItem(value: 'Adoption Services', child: Text('Adoption Services')),
                            DropdownMenuItem(value: 'Awareness Campaigns', child: Text('Awareness Campaigns')),
                            DropdownMenuItem(value: 'Other', child: Text('Other')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedService = value;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Services Offered',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a service';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _websiteController,
                          decoration: InputDecoration(
                            labelText: 'Website URL (Optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          keyboardType: TextInputType.url,
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              if (!RegExp(r'^(https?:\/\/)?([\w-]+\.)+[\w-]{2,4}(\/.*)?$').hasMatch(value)) {
                                return 'Please enter a valid URL';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description of NGO (Mission/Purpose)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a description of the NGO';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitRegistration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Submit Registration',
                                    style: TextStyle(fontSize: 16, color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}