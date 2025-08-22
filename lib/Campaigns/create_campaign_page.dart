import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:staymitra/services/campaign_service.dart';
import 'package:staymitra/services/auth_service.dart';
import 'package:staymitra/services/storage_service.dart';
import 'dart:typed_data';

class CreateCampaignPage extends StatefulWidget {
  const CreateCampaignPage({super.key});

  @override
  State<CreateCampaignPage> createState() => _CreateCampaignPageState();
}

class _CreateCampaignPageState extends State<CreateCampaignPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _maxParticipantsController =
      TextEditingController();

  final CampaignService _campaignService = CampaignService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  List<XFile> _selectedImages = [];
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  final List<String> _categories = [
    'Adventure',
    'Camping',
    'Hiking',
    'Travel',
    'Food',
    'Music',
    'Sports',
    'Photography',
    'Workshop',
    'Social',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
          if (_selectedImages.length > 5) {
            _selectedImages = _selectedImages.take(5).toList();
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final DateTime selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isStartDate) {
            _startDate = selectedDateTime;
          } else {
            _endDate = selectedDateTime;
          }
        });
      }
    }
  }

  Future<void> _createCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to create a campaign')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload images to Supabase Storage
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        print('Uploading ${_selectedImages.length} campaign images...');
        for (final xFile in _selectedImages) {
          final imageUrl = await _storageService.uploadImageFromXFile(
            xFile,
            'campaigns',
            folder: 'campaign_images',
          );
          if (imageUrl != null) {
            imageUrls.add(imageUrl);
          }
        }
        print('Campaign upload completed. URLs: $imageUrls');
      } else {
        print('No images selected for campaign');
      }

      final price = _priceController.text.trim().isEmpty
          ? null
          : double.tryParse(_priceController.text.trim());
      final maxParticipants = _maxParticipantsController.text.trim().isEmpty
          ? null
          : int.tryParse(_maxParticipantsController.text.trim());

      final campaign = await _campaignService.createCampaign(
        userId: currentUser.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrls: imageUrls,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        maxParticipants: maxParticipants,
        price: price,
        category: _selectedCategory,
      );

      if (campaign != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campaign created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to create campaign');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating campaign: $e')),
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
          'Create Campaign',
          style: TextStyle(
            color: const Color(0xFF007F8C),
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createCampaign,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Create',
                    style: TextStyle(
                      color: const Color(0xFF007F8C),
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              _buildInputField(
                controller: _titleController,
                label: 'Campaign Title',
                hint: 'Enter campaign title',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),

              SizedBox(height: screenHeight * 0.02),

              // Description
              _buildInputField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe your campaign...',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),

              SizedBox(height: screenHeight * 0.02),

              // Category
              _buildDropdownField(),

              SizedBox(height: screenHeight * 0.02),

              // Location
              _buildInputField(
                controller: _locationController,
                label: 'Location',
                hint: 'Enter location (optional)',
                prefixIcon: Icons.location_on,
              ),

              SizedBox(height: screenHeight * 0.02),

              // Date Selection
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'Start Date',
                      date: _startDate,
                      onTap: () => _selectDate(true),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: _buildDateField(
                      label: 'End Date',
                      date: _endDate,
                      onTap: () => _selectDate(false),
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.02),

              // Price and Max Participants
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      controller: _priceController,
                      label: 'Price (₹)',
                      hint: 'Enter price (optional)',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.currency_rupee,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: _buildInputField(
                      controller: _maxParticipantsController,
                      label: 'Max Participants',
                      hint: 'Enter limit (optional)',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.people,
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.02),

              // Image Selection
              _buildImageSection(screenWidth, screenHeight),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF007F8C),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF007F8C),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            hintText: 'Select category',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF007F8C),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'
                        : 'Select date',
                    style: TextStyle(
                      color: date != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSection(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Images',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF007F8C),
              ),
            ),
            TextButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: screenWidth * 0.25,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FutureBuilder<Uint8List>(
                          future: _selectedImages[index].readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                width: screenWidth * 0.25,
                                height: screenWidth * 0.25,
                                fit: BoxFit.cover,
                              );
                            } else {
                              return Container(
                                width: screenWidth * 0.25,
                                height: screenWidth * 0.25,
                                color: Colors.grey[300],
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
    );
  }
}
