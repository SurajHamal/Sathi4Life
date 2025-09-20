import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Step control
  bool _isStepOneComplete = false;

  // Step 1: essential dating prefs
  String? gender;
  String? interestedIn;

  // Step 2: full profile fields
  String name = '';
  String age = '';
  String location = '';
  String interests = '';
  String about = '';
  File? _imageFile;
  String? _webImage;
  bool _isLoading = false;

  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<bool> _hasInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void _goToStepTwo() {
    if (gender == null || interestedIn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both your gender and the gender you are interested in.')),
      );
      return;
    }
    setState(() {
      _isStepOneComplete = true;
    });
  }

  void _goBackToStepOne() {
    setState(() {
      _isStepOneComplete = false;
    });
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final hasConnection = await _hasInternetConnection();
    if (!hasConnection) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No internet connection')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      String? imageUrl;

      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'age': age,
        'gender': gender,
        'interestedIn': interestedIn,
        'location': location,
        'interests': interests,
        'about': about,
        'imageUrl': imageUrl,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required FormFieldSetter<String> onSaved,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(labelText: label),
        keyboardType: keyboardType,
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  ImageProvider? _getImageProvider() {
    if (_imageFile != null) return FileImage(_imageFile!);
    if (_webImage != null) return NetworkImage(_webImage!);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isStepOneComplete) {
      // Step 1 UI: select gender and interested in
      return Scaffold(
        appBar: AppBar(title: Text('Step 1: Select Preferences')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Your Gender'),
                value: gender,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) => setState(() => gender = val),
                validator: (val) => val == null ? 'Please select your gender' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Interested In'),
                value: interestedIn,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                  DropdownMenuItem(value: 'Everyone', child: Text('Everyone')),
                ],
                onChanged: (val) => setState(() => interestedIn = val),
                validator: (val) => val == null ? 'Please select interested gender' : null,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _goToStepTwo,
                child: Text('Next'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 60),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Step 2 UI: full profile form, with Back button and hidden gender field (prefilled from Step 1)
      return Scaffold(
        appBar: AppBar(
          title: Text('Complete Your Profile'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _goBackToStepOne,
            tooltip: 'Back to Preferences',
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _getImageProvider(),
                    child: _getImageProvider() == null
                        ? Icon(Icons.camera_alt, size: 40, color: Colors.grey.shade700)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Show gender as readonly info since it's chosen in step 1
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Your Gender',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    gender ?? '',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              _buildTextField(
                label: 'Name',
                onSaved: (val) => name = val!.trim(),
                validator: (val) => val == null || val.isEmpty ? 'Enter your name' : null,
              ),
              _buildTextField(
                label: 'Age',
                onSaved: (val) => age = val!.trim(),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Enter your age' : null,
              ),
              _buildTextField(
                label: 'Location',
                onSaved: (val) => location = val!.trim(),
                validator: (val) => val == null || val.isEmpty ? 'Enter your location' : null,
              ),
              _buildTextField(
                label: 'Interests',
                onSaved: (val) => interests = val!.trim(),
                validator: (val) => val == null || val.isEmpty ? 'Enter your interests' : null,
              ),
              _buildTextField(
                label: 'About',
                onSaved: (val) => about = val!.trim(),
                validator: (val) => val == null || val.isEmpty ? 'Tell us about yourself' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitProfile,
                child: Text('Save & Continue'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
