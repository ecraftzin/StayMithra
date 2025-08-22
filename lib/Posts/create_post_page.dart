import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:staymitra/services/post_service.dart';
import 'package:staymitra/services/auth_service.dart';
import 'package:staymitra/services/storage_service.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  List<XFile> _selectedImages = [];
  List<XFile> _selectedVideos = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
          // Limit to 5 images total
          if (_selectedImages.length > 5) {
            _selectedImages = _selectedImages.take(5).toList();
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickVideos() async {
    try {
      final XFile? video =
          await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedVideos.add(video);
          // Limit to 3 videos total
          if (_selectedVideos.length > 3) {
            _selectedVideos = _selectedVideos.take(3).toList();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeVideo(int index) {
    setState(() {
      _selectedVideos.removeAt(index);
    });
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some content for your post'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to create a post'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload images to Supabase Storage
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        print('Uploading ${_selectedImages.length} images...');
        for (final xFile in _selectedImages) {
          final imageUrl = await _storageService
              .uploadImageFromXFile(xFile, 'posts', folder: 'user_posts');
          if (imageUrl != null) {
            imageUrls.add(imageUrl);
          }
        }
        print('Upload completed. URLs: $imageUrls');
      }

      // Upload videos to Supabase Storage
      List<String> videoUrls = [];
      if (_selectedVideos.isNotEmpty) {
        print('Uploading ${_selectedVideos.length} videos...');
        for (final xFile in _selectedVideos) {
          final videoUrl = await _storageService
              .uploadVideoFromXFile(xFile, 'posts', folder: 'user_posts');
          if (videoUrl != null) {
            videoUrls.add(videoUrl);
          }
        }
        print('Video upload completed. URLs: $videoUrls');
      }

      final post = await _postService.createPost(
        userId: currentUser.id,
        content: _contentController.text.trim(),
        imageUrls: imageUrls,
        videoUrls: videoUrls,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
      );

      if (post != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        throw Exception('Failed to create post');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Create Post',
          style: TextStyle(
            color: const Color(0xFF007F8C),
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Post',
                    style: TextStyle(
                      color: const Color(0xFF007F8C),
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content input
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: "What's on your mind?",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
            ),

            SizedBox(height: screenHeight * 0.02),

            // Location input
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: "Add location (optional)",
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.location_on, color: Colors.grey),
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
            ),

            SizedBox(height: screenHeight * 0.02),

            // Image selection
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.photo, color: Colors.grey),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Add Photos',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _pickImages,
                        child: Text(
                          'Select',
                          style: TextStyle(
                            color: const Color(0xFF007F8C),
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedImages.isNotEmpty) ...[
                    SizedBox(height: screenHeight * 0.01),
                    SizedBox(
                      height: screenWidth * 0.2,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.only(right: screenWidth * 0.02),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(screenWidth * 0.02),
                                  child: FutureBuilder<Uint8List>(
                                    future:
                                        _selectedImages[index].readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          width: screenWidth * 0.2,
                                          height: screenWidth * 0.2,
                                          fit: BoxFit.cover,
                                        );
                                      } else if (snapshot.hasError) {
                                        return Container(
                                          width: screenWidth * 0.2,
                                          height: screenWidth * 0.2,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.error),
                                        );
                                      } else {
                                        return Container(
                                          width: screenWidth * 0.2,
                                          height: screenWidth * 0.2,
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Video Picker Section
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.videocam, color: Colors.grey),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Add Videos',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.grey[700],
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _pickVideos,
                        child: Text(
                          'Select',
                          style: TextStyle(
                            color: const Color(0xFF007F8C),
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedVideos.isNotEmpty) ...[
                    SizedBox(height: screenHeight * 0.01),
                    SizedBox(
                      height: screenWidth * 0.2,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedVideos.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.only(right: screenWidth * 0.02),
                            width: screenWidth * 0.2,
                            height: screenWidth * 0.2,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              children: [
                                const Center(
                                  child: Icon(
                                    Icons.play_circle_filled,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeVideo(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
