import 'package:flutter/material.dart';
import 'package:staymitra/services/auth_service.dart';
import 'package:staymitra/services/user_service.dart';
import 'package:staymitra/services/storage_service.dart';
import 'package:staymitra/models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _newAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final userProfile = await _userService.getUserById(currentUser.id);
        if (userProfile != null && mounted) {
          setState(() {
            _currentUser = userProfile;
            _usernameController.text = userProfile.username;
            _emailController.text = userProfile.email;
            _fullNameController.text = userProfile.fullName ?? '';
            _locationController.text = userProfile.location ?? '';
            _bioController.text = userProfile.bio ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isUploadingPhoto = true);

        // Upload to storage
        final avatarUrl = await _storageService.uploadImage(
          File(image.path),
          'avatars',
          folder: 'users',
        );

        if (avatarUrl != null) {
          setState(() {
            _newAvatarUrl = avatarUrl;
            _isUploadingPhoto = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() => _isUploadingPhoto = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload photo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _userService.updateUserProfile(
          userId: currentUser.id,
          username: _usernameController.text.trim(),
          fullName: _fullNameController.text.trim(),
          bio: _bioController.text.trim(),
          location: _locationController.text.trim(),
          avatarUrl: _newAvatarUrl, // Include new avatar URL if uploaded
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _getInitials() {
    if (_currentUser?.fullName != null && _currentUser!.fullName!.isNotEmpty) {
      final names = _currentUser!.fullName!.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else {
        return names[0][0].toUpperCase();
      }
    } else if (_currentUser?.username != null &&
        _currentUser!.username.isNotEmpty) {
      return _currentUser!.username[0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Adjusting padding and margins to be responsive
    double horizontalPadding = screenWidth * 0.05;
    double verticalPadding = screenHeight * 0.02;
    double avatarSize = screenWidth * 0.18;
    double textFieldHeight = screenHeight * 0.06;
    double iconSize = screenWidth * 0.06;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient container
          Container(
            height: screenHeight * 0.35,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF007F99), Colors.white],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header Row
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: verticalPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: CircleAvatar(
                            radius: screenWidth * 0.05,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.arrow_back,
                                color: Colors.black, size: iconSize),
                          ),
                        ),

                        // Edit profile text
                        Text(
                          "Edit Profile",
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        // Save button
                        InkWell(
                          onTap: _isSaving ? null : _saveProfile,
                          child: CircleAvatar(
                            radius: screenWidth * 0.05,
                            backgroundColor:
                                _isSaving ? Colors.grey : Colors.white,
                            child: _isSaving
                                ? SizedBox(
                                    width: iconSize * 0.7,
                                    height: iconSize * 0.7,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF007F99),
                                    ),
                                  )
                                : Icon(Icons.check,
                                    color: Colors.black, size: iconSize),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: verticalPadding),
                  // Profile photo with upload option
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: avatarSize,
                        backgroundColor: const Color(0xFF007F8C),
                        backgroundImage: _newAvatarUrl != null
                            ? NetworkImage(_newAvatarUrl!)
                            : _currentUser?.avatarUrl != null
                                ? NetworkImage(_currentUser!.avatarUrl!)
                                : null,
                        child: (_newAvatarUrl == null &&
                                _currentUser?.avatarUrl == null)
                            ? Text(
                                _getInitials(),
                                style: TextStyle(
                                  fontSize: avatarSize * 0.4,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),

                      // Camera icon for photo upload
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                          child: Container(
                            padding: EdgeInsets.all(avatarSize * 0.1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007F8C),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: _isUploadingPhoto
                                ? SizedBox(
                                    width: avatarSize * 0.2,
                                    height: avatarSize * 0.2,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: avatarSize * 0.2,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: verticalPadding),
                  // Change profile photo text
                  Text(
                    "Change profile photo",
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: const Color(0xFF007F99),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: verticalPadding),
                  // Input fields
                  _buildTextField("Username", screenWidth, textFieldHeight,
                      _usernameController),
                  _buildDivider(),
                  _buildTextField("Full Name", screenWidth, textFieldHeight,
                      _fullNameController),
                  _buildDivider(),
                  _buildTextField(
                      "Email", screenWidth, textFieldHeight, _emailController,
                      enabled: false),
                  _buildDivider(),
                  _buildTextField("Location", screenWidth, textFieldHeight,
                      _locationController),
                  _buildDivider(),
                  _buildTextField(
                      "Bio", screenWidth, textFieldHeight, _bioController,
                      maxLines: 3),
                  _buildDivider(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget to create the text fields
  Widget _buildTextField(
    String hintText,
    double screenWidth,
    double textFieldHeight,
    TextEditingController controller, {
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05, vertical: screenWidth * 0.03),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          color: enabled ? Colors.black : Colors.grey,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(vertical: textFieldHeight * 0.35),
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: screenWidth * 0.04,
          ),
        ),
      ),
    );
  }

  // Divider widget
  Widget _buildDivider() {
    return const Divider(height: 1, color: Colors.grey);
  }
}
