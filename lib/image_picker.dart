import 'package:app_final/widget/full_size_image_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _folderController = TextEditingController();
  Dio dio = Dio();

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _images.add(File(photo.path));
      });
    }
  }

  void _viewFullSizeImage(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => FullSizeImageScreen(
              image: _images[index],
              onDelete: () {
                setState(() {
                  _images.removeAt(index);
                });
              },
            ),
      ),
    );
  }

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
      await uploadImagesWithDio(_images, folderName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All images uploaded successfully')),
      );
    }
  }

  Future<void> uploadImagesWithDio(List<File> images, String folderName) async {
    List<MultipartFile> imageFiles = [];
    List<String> filenames = [];

    // Step 1: Get next file indexes from backend
    List<int> nextIndexes = [];

    try {
      Response response = await dio.post(
        'http://192.168.68.110:8069/api/file_explorer/test',
        data: {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {'folder_name': folderName, 'num_of_files': images.length},
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer dc92b110993c04c779581fe56b1a97667b6a3fb8',
          },
        ),
      );

      // Print full response for debugging
      print('Full API response: ${response.data}');

      // Check for the nested result structure
      if (response.data != null &&
          response.data['result'] != null &&
          response.data['result']['result'] != null &&
          response.data['result']['result']['next_file_indexes'] != null) {
        nextIndexes = List<int>.from(
          response.data['result']['result']['next_file_indexes'],
        );
        print('Using file indexes from API: $nextIndexes');
      } else {
        // Handle missing data - use default values
        print('Missing expected data structure in response');
        nextIndexes = List<int>.generate(images.length, (index) => index + 1);
        print('Using default file indexes: $nextIndexes');
      }
    } catch (e) {
      print('Failed to fetch indexes: $e');
      // Default to sequential numbers if API fails
      nextIndexes = List<int>.generate(images.length, (index) => index + 1);
      print('Using default file indexes after error: $nextIndexes');
    }

    // Step 2: Build filenames using backend-provided indexes
    final now = DateTime.now();
    final date = '${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}';
    final time =
        '${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}';

    final baseFilename = '${folderName}_${date}_${time}';

    for (int i = 0; i < images.length; i++) {
      MultipartFile multipartFile = await MultipartFile.fromFile(
        images[i].path,
      );
      imageFiles.add(multipartFile);
      filenames.add('${nextIndexes[i]}_${baseFilename}.jpg');
    }

    FormData formData = FormData.fromMap({
      'folder_name': folderName,
      'photos': imageFiles,
      'filenames': filenames,
    });

    try {
      Response response = await dio.post(
        'http://192.168.68.110:8069/api/file_explorer/upload_photos',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer dc92b110993c04c779581fe56b1a97667b6a3fb8',
          },
        ),
      );
      print('Images uploaded successfully: ${response.data}');
    } catch (e) {
      print('Error uploading images: $e');
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Send Images to Odoo'), centerTitle: true),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _folderController,
              decoration: InputDecoration(
                labelText: 'Package ID',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child:
                _images.isEmpty
                    ? Center(child: Text('No images selected'))
                    : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                      ),
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _viewFullSizeImage(index),
                          child: Image.file(_images[index], fit: BoxFit.cover),
                        );
                      },
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _pickImages,
                  child: Text('Pick Images'),
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: _takePhoto,
                  tooltip: 'Take Photos',
                ),
                ElevatedButton(
                  onPressed: _uploadImagesToOdoo,
                  child: Text('Upload to Odoo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
