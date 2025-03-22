import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mytank/providers/update_data_provider.dart';

class UpdateDataScreen extends StatefulWidget {
  const UpdateDataScreen({Key? key}) : super(key: key);

  @override
  UpdateDataScreenState createState() => UpdateDataScreenState();
}

class UpdateDataScreenState extends State<UpdateDataScreen> {
  final _identityNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _identityNumberController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final updateDataProvider = Provider.of<UpdateDataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile Data'),
        backgroundColor: Colors.teal[800],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF004D40), Color(0xFF00796B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.teal.shade100,
                        backgroundImage:
                            _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : const NetworkImage(
                                      'https://randomuser.me/api/portraits/men/1.jpg',
                                    )
                                    as ImageProvider,
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.teal.shade800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildInputField(
                  controller: _identityNumberController,
                  label: 'Identity Number',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outlined,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 20),
                _buildInputField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_iphone_outlined,
                ),
                const SizedBox(height: 40),
                updateDataProvider.isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                    : ElevatedButton.icon(
                      icon: const Icon(Icons.save_outlined, size: 24),
                      label: const Text(
                        'SAVE CHANGES',
                        style: TextStyle(fontSize: 16, letterSpacing: 1.2),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                        shadowColor: Colors.black54,
                      ),
                      onPressed: () async {
                        try {
                          await updateDataProvider.updateData(
                            identityNumber:
                                _identityNumberController.text.trim(),
                            name: _nameController.text.trim(),
                            email: _emailController.text.trim(),
                            phone: _phoneController.text.trim(),
                          );
                          if (mounted) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Profile updated successfully!',
                                  ),
                                  backgroundColor: Colors.teal,
                                ),
                              );
                            });
                          }
                        } catch (e) {
                          if (mounted) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Update failed: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            });
                          }
                        }
                      },
                    ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        floatingLabelStyle: const TextStyle(color: Colors.white),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
      cursorColor: Colors.white,
      keyboardType:
          label == 'Phone Number' ? TextInputType.phone : TextInputType.text,
    );
  }
}
