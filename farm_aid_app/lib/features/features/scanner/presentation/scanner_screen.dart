import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import this
import 'package:path_provider/path_provider.dart'; // Import this
import 'package:path/path.dart' as path; // Import this

import '../data/scanner_service.dart'; // Your service with upload logic

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ScannerService _scannerService = ScannerService();
  File? _selectedImage;
  bool _isProcessing = false;
  String? _errorMessage;

  // --- 1. Pick Image from Gallery ---
  Future<void> _pickImage() async {
    setState(() {
      _errorMessage = null;
      _selectedImage = null;
    });
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // --- 2. Take Image with Camera ---
  Future<void> _takePhoto() async {
    setState(() {
      _errorMessage = null;
      _selectedImage = null;
    });
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // --- 3. Process Image (Upload & AI Analysis) ---
  Future<void> _processImage() async {
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = "Please select an image first.";
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // This will perform the Supabase upload with validation
      final String? imageUrl = await _scannerService.uploadCropImage(_selectedImage!);
      
      if (imageUrl != null) {
        // TODO: Here, you would send imageUrl and other data to your Django backend
        // for AI analysis (using your AIModel and Diagnosis from the Class Diagram)
        // For now, let's just confirm the upload.
        print("Image uploaded successfully: $imageUrl");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Image uploaded! URL: $imageUrl")),
          );
          // Navigate to a results screen or back to dashboard
          Navigator.pop(context, true); 
        }
      } else {
        setState(() {
          _errorMessage = "Upload failed. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', ''); // Clean error message
      });
      print('Processing Error: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF5),
      appBar: AppBar(
        title: const Text("Crop Scanner", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Identify Plant Diseases",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
            ),
            const SizedBox(height: 8),
            const Text(
              "Take a clear photo of the affected plant part.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),

            // Image Preview Area
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text("No image selected", style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
            ),
            const SizedBox(height: 20),

            // Error Message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text("Take Photo", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A844),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library, color: Color(0xFF00A844)),
                    label: const Text("From Gallery", style: TextStyle(color: Color(0xFF00A844))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFF00A844))
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isProcessing ? null : _processImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20), // Darker green for primary action
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Analyze Image", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}


// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import '../data/scanner_service.dart';
// import 'scanner_result_screen.dart'; 
// import '../../onboarding/presentation/crop_type_page.dart'; 

// class ScannerScreen extends StatefulWidget {
//   const ScannerScreen({super.key});

//   @override
//   State<ScannerScreen> createState() => _ScannerScreenState();
// }

// class _ScannerScreenState extends State<ScannerScreen> {
//   final ScannerService _scannerService = ScannerService();
//   File? _selectedImage;
//   bool _isProcessing = false;
//   String? _errorMessage;

//   // --- Image Pickers ---
//   Future<void> _pickImage() async {
//     setState(() { _errorMessage = null; _selectedImage = null; });
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path));
//   }

//   Future<void> _takePhoto() async {
//     setState(() { _errorMessage = null; _selectedImage = null; });
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.camera);
//     if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path));
//   }

//   // --- Choice Dialog ---
//   Future<String?> _askForPersonalization() async {
//     return await showDialog<String>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Analysis Type"),
//         content: const Text("Would you like general tips or personalized advice for your specific crop?"),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, 'general'), child: const Text("GENERAL")),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, 'personalized'),
//             style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
//             child: const Text("PERSONALIZED"),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- THE UPDATED PROCESS ---
//   Future<void> _processImage() async {
//     if (_selectedImage == null) {
//       setState(() => _errorMessage = "Please select an image first.");
//       return;
//     }

//     final choice = await _askForPersonalization();
//     if (choice == null) return; 

//     String? profileId;

//     if (choice == 'personalized') {
//       // 1. Wait for CropTypeScreen to finish
//       final result = await Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => CropTypeScreen(
//             pendingImage: _selectedImage!.readAsBytesSync(),
//           ),
//         ),
//       );

//       // 2. THIS IS HOW YOU SEE IT ON YOUR PHONE
//       if (result != null) {
//         profileId = result.toString();
//         // Displays a green bar at the bottom of your phone screen
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("✅ SUCCESS: Profile ID $profileId received!"),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("❌ Profile creation cancelled."), backgroundColor: Colors.red),
//         );
//         return; 
//       }
//     }

//     setState(() { _isProcessing = true; _errorMessage = null; });

//     try {
//       final String? imageUrl = await _scannerService.uploadCropImage(_selectedImage!);
      
//       if (imageUrl != null) {
//         // MOCK AI RESULT (Replace with your TFLite logic later)
//         String detectedLabel = "Cabbage Black Rot"; 
//         double confidence = 0.92;

//         final backendResult = await _scannerService.saveScanToBackend(
//           imageUrl: imageUrl,
//           diseaseName: detectedLabel,
//           confidence: confidence,
//           profileId: profileId, 
//         );

//         if (backendResult != null && mounted) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => ScannerResultScreen(result: backendResult)),
//           );
//         } else {
//           setState(() => _errorMessage = "Backend failed to process ID $profileId");
//         }
//       }
//     } catch (e) {
//       setState(() => _errorMessage = e.toString());
//     } finally {
//       if (mounted) setState(() => _isProcessing = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF1FAF5),
//       appBar: AppBar(
//         title: const Text("Crop Scanner", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         centerTitle: true,
//         backgroundColor: const Color(0xFF2E7D32),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const Text("Identify Plant Diseases", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
//             const SizedBox(height: 30),
            
//             // Image Preview Area
//             Container(
//               height: 250,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15),
//                 border: Border.all(color: Colors.grey.shade300),
//               ),
//               child: _selectedImage != null
//                   ? ClipRRect(
//                       borderRadius: BorderRadius.circular(14),
//                       child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
//                     )
//                   : const Center(child: Text("No image selected")),
//             ),
//             const SizedBox(height: 20),

//             if (_errorMessage != null)
//               Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),

//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: _isProcessing ? null : _takePhoto,
//                     icon: const Icon(Icons.camera_alt, color: Colors.white),
//                     label: const Text("Photo", style: TextStyle(color: Colors.white)),
//                     style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A844)),
//                   ),
//                 ),
//                 const SizedBox(width: 15),
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: _isProcessing ? null : _pickImage,
//                     icon: const Icon(Icons.photo_library, color: Color(0xFF00A844)),
//                     label: const Text("Gallery", style: TextStyle(color: Color(0xFF00A844))),
//                     style: ElevatedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Color(0xFF00A844))),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),

//             ElevatedButton(
//               onPressed: (_isProcessing || _selectedImage == null) ? null : _processImage,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF1B5E20),
//                 padding: const EdgeInsets.symmetric(vertical: 18),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//               child: _isProcessing
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : const Text("Analyze Image", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }