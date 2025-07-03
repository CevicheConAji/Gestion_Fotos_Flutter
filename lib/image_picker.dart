import 'dart:io'; // Used to handle File objects from the device
import 'package:dio/dio.dart'; // HTTP client for making network requests
import 'package:flutter/material.dart'; // Flutter UI framework
import 'package:image_picker/image_picker.dart'; // For picking images from gallery/camera
import 'package:app_final/widget/full_size_image_screen.dart'; // Screen to preview full-size image
import 'package:app_final/widget/ApiSettingsScreen.dart'; // Settings screen for API input
import 'package:shared_preferences/shared_preferences.dart'; // For storing/retrieving settings locally
import 'widget/reorderable_grid_view.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// Main screen widget
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

// State class for main screen
class MyHomePageState extends State<MyHomePage> {
  String? _apiKey; // Holds the API key
  String? _apiEndpoint; // Holds the API endpoint URL
  final List<File> _images = []; // List of selected or taken image files
  final ImagePicker _picker = ImagePicker(); // Image picker instance
  final TextEditingController _folderController =
      TextEditingController(); // Controller for folder input
  Dio dio = Dio(); // Dio instance for HTTP requests

  bool _isUploading = false;

  // Picks multiple images from the gallery
  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  // Called when widget is initialized
  @override
  void initState() {
    super.initState();
    _loadApiSettings(); // Load saved API settings
  }

  // Loads API key and endpoint from SharedPreferences
  Future<void> _loadApiSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('apiKey');
      _apiEndpoint = prefs.getString('apiEndpoint');
    });
  }
  // Takes a photo using the camera
  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (photo != null) {
      setState(() {
        _images.add(File(photo.path));
      });
    }
  }

  // Opens full screen preview of selected image
  void _viewFullSizeImage(int index) async {
    final File? updatedImage = await Navigator.of(context).push<File>(
      MaterialPageRoute(
        builder:
            (context) => FullSizeImageScreen(
              image: _images[index],
              onDelete: () {
                setState(() {
                  _images.removeAt(index);
                });
                Navigator.pop(context); // also close screen after delete
              },
            ),
      ),
    );

    // If user cropped image and returned new file, update it
    if (updatedImage != null) {
      setState(() {
        _images[index] = updatedImage;
      });
    }
  }

  // Validates and starts image upload process
  Future<void> _uploadImagesToOdoo() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No images selected')));
      return;
    }

    String folderName = _folderController.text.trim();
    if (folderName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a folder name')));
      return;
    }

    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Upload'),
          content: Text(
            'Do you want to upload ${_images.length} image(s) to Odoo in folder "$folderName"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Upload'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isUploading = true;
      });

      bool success = await uploadImagesWithDio(_images, folderName);

      setState(() {
        _isUploading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All images uploaded successfully')),
        );
        setState(() {
          _images.clear();
          _folderController.clear();
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload images')));
      }
    }
  }

  // Uploads the selected images using Dio with compression
  Future<bool> uploadImagesWithDio(List<File> images, String folderName) async {
    if (_apiKey == null || _apiEndpoint == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('API settings not configured')));
      return false;
    }

    List<MultipartFile> imageFiles = [];

    for (var image in images) {
      // Compress the image before upload
      File? compressedImage = await _compressImage(image);
      File imageToUpload = compressedImage ?? image; // Use original if compression fails
      
      MultipartFile multipartFile = await MultipartFile.fromFile(imageToUpload.path);
      imageFiles.add(multipartFile);
    }

    FormData formData = FormData.fromMap({
      'folder_name': folderName,
      'photos': imageFiles,
    });

    try {
      await dio.post(
        _apiEndpoint!,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $_apiKey'}),
      );
      return true; // Upload succeeded
    } catch (e) {
      String errorMessage = 'Upload failed: ${e.toString()}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      return false; // Upload failed
    }
  }

  // Compresses an image to reduce file size before upload
  Future<File?> _compressImage(File imageFile) async {
    try {
      // Get file size before compression
      int originalSize = await imageFile.length();
      
      // Only compress if file is larger than 1MB
      if (originalSize <= 1024 * 1024) {
        return imageFile; // Return original if already small enough
      }

      // Generate a compressed file path
      String targetPath = imageFile.path.replaceAll('.jpg', '_compressed.jpg');
      if (!targetPath.contains('_compressed')) {
        // Handle other extensions
        String extension = imageFile.path.split('.').last;
        targetPath = imageFile.path.replaceAll('.$extension', '_compressed.jpg');
      }

      // Compress the image
      XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 70, // Adjust quality (0-100, lower = more compression)
        minWidth: 1920, // Maximum width
        minHeight: 1080, // Maximum height
        format: CompressFormat.jpeg,
      );

      if (compressedXFile != null) {
        File compressedFile = File(compressedXFile.path);
        int compressedSize = await compressedFile.length();
        
        // Log compression results for debugging
        print('Original size: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');
        print('Compressed size: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
        print('Compression ratio: ${((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)}%');
        
        return compressedFile;
      }
    } catch (e) {
      print('Error compressing image: $e');
    }
    
    return null; // Return null if compression failed
  }

  // Handle reordering of images when drag ends
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        // Removing the item at oldIndex will shorten the list by 1
        newIndex -= 1;
      }
      final File item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
    });
  }

  // Builds the UI
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text('Subir fotos a Odoo'),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.settings),
              onPressed:
                  _isUploading
                      ? null
                      : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ApiSettingsScreen(),
                          ),
                        );
                        await _loadApiSettings();
                      },
            ),
          ),
          body: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _folderController,
                  enabled: !_isUploading,
                  decoration: InputDecoration(
                    labelText: 'Código del pedido',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child:
                    _images.isEmpty
                        ? Center(child: Text('Ninguna imagen seleccionada'))
                        : ReorderableGridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 5,
                                mainAxisSpacing: 5,
                              ),
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              key: ValueKey(_images[index].path),
                              onTap:
                                  _isUploading
                                      ? null
                                      : () => _viewFullSizeImage(index),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(_images[index], fit: BoxFit.cover),
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      color: Colors.black54,
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          onReorder: _isUploading ? (_, __) {} : _onReorder,
                        ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _isUploading ? null : _pickImages,
                      child: Text('Seleccionar Imagen'),
                    ),
                    IconButton(
                      icon: Icon(Icons.camera_alt),
                      onPressed: _isUploading ? null : _takePhoto,
                      tooltip: 'Hacer Fotos',
                    ),
                    ElevatedButton(
                      onPressed: _isUploading ? null : _uploadImagesToOdoo,
                      child: Text('Subir a odoo'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isUploading) ...[
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withOpacity(0.5),
          ),
          Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}
