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

    final now = DateTime.now();
    final date = '${now.year}${_twoDigits(now.month)}${_twoDigits(now.day)}';
    final time =
        '${_twoDigits(now.hour)}${_twoDigits(now.minute)}${_twoDigits(now.second)}';
    final count = images.length.toString().padLeft(2, '0');

    final baseFilename = '${folderName}_${date}_${time}_$count';

    for (int i = 0; i < images.length; i++) {
      MultipartFile multipartFile = await MultipartFile.fromFile(
        images[i].path,
      );
      imageFiles.add(multipartFile);
      filenames.add(
        '${baseFilename}_${i + 1}.jpg',
      ); // Add index to avoid filename clash
    }

    FormData formData = FormData.fromMap({
      'folder_name': folderName,
      'photos': imageFiles,
      'filenames': filenames,
    });

    try {
      Response response = await dio.post(
        'http://localhost:8069/api/file_explorer/upload_photos',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer 32cbfb91f138b8e2dd4e0fa79c07192af8039641',
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
