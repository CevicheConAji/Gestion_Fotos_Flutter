import 'package:flutter/material.dart';
import 'dart:io';

class FullSizeImageScreen extends StatelessWidget {
  final File image;
  final Function onDelete;

  const FullSizeImageScreen({
    Key? key,
    required this.image,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Full Size Image'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              onDelete();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Center(
        child: Image.file(image),
      ),
    );
  }
}
