import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = MediaQuery.of(context).size.width;
    double iconSize = screenWidth * 0.06;

    return Scaffold(
      resizeToAvoidBottomInset: true, // To adjust the UI when keyboard is shown
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF017E8D),
              Color(0xFFEFF7F8),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
//               // Back button
//              InkWell(
//   onTap: () => Navigator.pop(context),
//   child: CircleAvatar(
//     radius: screenWidth * 0.05,
//     backgroundColor: Colors.white,
//     child: Icon(Icons.arrow_back, color: Colors.black, size: iconSize),
//   ),
// ),
              // Main content
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                  child: const UploadForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadForm extends StatefulWidget {
  const UploadForm({super.key});

  @override
  _UploadFormState createState() => _UploadFormState();
}

class _UploadFormState extends State<UploadForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for each input field
  final TextEditingController _campaignNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _slotController = TextEditingController();
  final TextEditingController _timingsController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final size = MediaQuery.of(context).size;

    // Responsive form layout
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: viewInsets.bottom + 20),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 50, bottom: 20),
        padding: EdgeInsets.all(size.width * 0.05),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Upload",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please fill the details and upload",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              _buildInput(_campaignNameController, "Campaign Name"),
              _buildInput(_locationController, "Location"),
              _buildInput(_priceController, "Price"),
              _buildInput(_slotController, "Slot"),
              _buildInput(_timingsController, "Timings"),
              _buildInput(_detailsController, "Details"),
              const SizedBox(height: 20),
              _uploadButton(),
              const SizedBox(height: 20),
              // Submit button with responsive height
              SizedBox(
                width: double.infinity,
                height: size.height * 0.08, // Adjust button height based on screen size
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 21, 7, 92),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFF0F0F0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$hint is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _uploadButton() {
    return GestureDetector(
      onTap: () {
        if (_formKey.currentState?.validate() ?? false) {
          // Handle upload logic here
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF017E8D),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            IconButton(onPressed: () async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.media, // Picks both image and video
    );

    if (result != null) {
      List<String> selectedPaths = result.paths.whereType<String>().toList();
      print("Selected files: $selectedPaths");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Selected ${selectedPaths.length} files")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No file selected")),
      );
    }
  } catch (e) {
    print("File picking error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: ${e.toString()}")),
    );
  }
},
             icon: const Icon(Icons.upload, color: Colors.white, size: 50,)),
            const SizedBox(height: 8),
            const Text(
              "Upload",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
