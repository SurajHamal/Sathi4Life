import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _gender = 'Male';

  // For multiple photos
  List<String> _photoUrls = [];
  String? _selectedProfilePhotoUrl;

  // Temporarily picked images before upload
  List<File> _pickedImagesFiles = [];
  List<Uint8List> _pickedImagesBytes = [];

  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final data = await UserService().getUserProfile(user.uid);
    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _ageController.text = (data['age']?.toString() ?? '');
      _locationController.text = data['location'] ?? '';
      _gender = data['gender'] ?? 'Male';

      _photoUrls = List<String>.from(data['photoUrls'] ?? []);
      _selectedProfilePhotoUrl = data['profileImageUrl'];
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();

    if (kIsWeb) {
      // Web: pick single image (multiple not supported)
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _pickedImagesBytes.add(bytes);
          _pickedImagesFiles.clear();
        });
      }
    } else {
      // Mobile: pick multiple images
      final pickedFiles = await picker.pickMultiImage(imageQuality: 80);
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          _pickedImagesFiles = pickedFiles.map((e) => File(e.path)).toList();
          _pickedImagesBytes.clear();
        });
      }
    }
  }

  Future<void> _uploadMultiplePhotos() async {
    if (_pickedImagesFiles.isEmpty && _pickedImagesBytes.isEmpty) return;

    setState(() => _isUploading = true);

    List<String> newPhotoUrls = [];

    if (kIsWeb) {
      for (var bytes in _pickedImagesBytes) {
        final url = await UserService().uploadPhoto(imageBytes: bytes);
        if (url != null) newPhotoUrls.add(url);
      }
    } else {
      for (var file in _pickedImagesFiles) {
        final url = await UserService().uploadPhoto(imageFile: file);
        if (url != null) newPhotoUrls.add(url);
      }
    }

    setState(() => _isUploading = false);

    if (newPhotoUrls.isNotEmpty) {
      _photoUrls.addAll(newPhotoUrls);

      if (_selectedProfilePhotoUrl == null && _photoUrls.isNotEmpty) {
        _selectedProfilePhotoUrl = _photoUrls.first;
      }

      await UserService().updateUserPhotos(
        photoUrls: _photoUrls,
        profileImageUrl: _selectedProfilePhotoUrl ?? '',
      );

      setState(() {
        _pickedImagesFiles.clear();
        _pickedImagesBytes.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photos uploaded successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo upload failed.')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final profileData = {
      'uid': user.uid,
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'gender': _gender,
      'location': _locationController.text.trim(),
      'profileImageUrl': _selectedProfilePhotoUrl,
      'photoUrls': _photoUrls,
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await UserService().updateUserProfile(profileData);

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );

      Future.delayed(Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, '/home');
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? profileImageProvider;

    if (_selectedProfilePhotoUrl != null && _selectedProfilePhotoUrl!.isNotEmpty) {
      profileImageProvider = NetworkImage(
        '$_selectedProfilePhotoUrl?cb=${DateTime.now().millisecondsSinceEpoch}',
      );
    } else {
      profileImageProvider = AssetImage('assets/default_profile.png');
    }

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile main photo
              CircleAvatar(
                radius: 60,
                backgroundImage: profileImageProvider,
              ),

              SizedBox(height: 10),

              ElevatedButton.icon(
                icon: Icon(Icons.photo_library),
                label: Text('Pick Images'),
                onPressed: _pickImages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),

              SizedBox(height: 10),

              ElevatedButton.icon(
                icon: _isUploading
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Icon(Icons.upload),
                label: Text(_isUploading ? 'Uploading...' : 'Upload Photos'),
                onPressed: (_pickedImagesFiles.isNotEmpty || _pickedImagesBytes.isNotEmpty) &&
                    !_isUploading
                    ? _uploadMultiplePhotos
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),

              SizedBox(height: 20),

              // Display all photos horizontally with selection
              _photoUrls.isEmpty
                  ? Text('No photos uploaded yet')
                  : SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photoUrls.length,
                  itemBuilder: (context, index) {
                    final url = _photoUrls[index];
                    final isSelected = url == _selectedProfilePhotoUrl;

                    return GestureDetector(
                      onTap: () async {
                        setState(() {
                          _selectedProfilePhotoUrl = url;
                        });

                        await UserService().updateUserPhotos(
                          photoUrls: _photoUrls,
                          profileImageUrl: _selectedProfilePhotoUrl ?? '',
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 5),
                        padding: isSelected ? EdgeInsets.all(3) : EdgeInsets.all(0),
                        decoration: BoxDecoration(
                          border: isSelected
                              ? Border.all(color: Colors.red, width: 3)
                              : null,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(url),
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 20),

              // Other profile form fields
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Name is required' : null,
              ),
              SizedBox(height: 10),

              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final age = int.tryParse(value ?? '');
                  if (value == null || value.trim().isEmpty) return 'Age is required';
                  if (age == null || age <= 0 || age > 120) return 'Enter a valid age';
                  return null;
                },
              ),
              SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _gender,
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => _gender = val ?? 'Male'),
                decoration: InputDecoration(labelText: 'Gender'),
              ),
              SizedBox(height: 10),

              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Location is required' : null,
              ),
              SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saveProfile,
                child: Text('Save Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/match_suggestions');
                },
                child: Text('See Matches'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
