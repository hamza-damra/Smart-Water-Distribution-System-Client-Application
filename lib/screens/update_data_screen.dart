import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mytank/providers/update_data_provider.dart';

class UpdateDataScreen extends StatefulWidget {
  const UpdateDataScreen({super.key});

  @override
  UpdateDataScreenState createState() => UpdateDataScreenState();
}

class UpdateDataScreenState extends State<UpdateDataScreen> {
  final TextEditingController _identityNumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final updateDataProvider = Provider.of<UpdateDataProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Update Profile Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _identityNumberController,
              decoration: InputDecoration(
                labelText: 'Identity Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            updateDataProvider.isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: () async {
                try {
                  await updateDataProvider.updateData(
                    identityNumber: _identityNumberController.text.trim(),
                    name: _nameController.text.trim(),
                    email: _emailController.text.trim(),
                    phone: _phoneController.text.trim(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Data updated successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update data: $e')),
                  );
                }
              },
              child: Text('Update Data'),
            ),
          ],
        ),
      ),
    );
  }
}