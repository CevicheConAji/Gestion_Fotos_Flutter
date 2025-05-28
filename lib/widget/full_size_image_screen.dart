import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';

class FullSizeImageScreen extends StatefulWidget {
  final File image;
  final Function onDelete;

  const FullSizeImageScreen({
    super.key,
    required this.image,
    required this.onDelete,
  });

  @override
  State<FullSizeImageScreen> createState() => _FullSizeImageScreenState();
}

class _FullSizeImageScreenState extends State<FullSizeImageScreen> {
  late File _imageFile;

  @override
  void initState() {
    super.initState();
    _imageFile = widget.image;
  }

  Future<void> _cropImage() async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Image'),
      ],
    );
    
    if (croppedFile != null) {
      setState(() {
        _imageFile = File(croppedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _imageFile);
        return false; // prevent default pop
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Full Size Image'),
          actions: [
            IconButton(
              icon: Icon(Icons.crop), 
              onPressed: _cropImage
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                widget.onDelete(); // This already handles the navigation
                // Removed the redundant Navigator.pop() call
              },
            ),
          ],
        ),
        body: Center(
          child: Image.file(_imageFile)
        ),
      ),
    );
  }
}