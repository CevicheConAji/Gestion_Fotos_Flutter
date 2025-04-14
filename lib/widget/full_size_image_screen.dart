import 'package:flutter/material.dart';
import 'dart:io';

// FullSizeImageScreen widget displays a full-size image with an option to delete it
class FullSizeImageScreen extends StatelessWidget {
  final File image; // The image to be displayed
  final Function onDelete; // Function to be called when the image is deleted

  // Constructor to receive the image and the delete function
  const FullSizeImageScreen({
    super.key,
    required this.image, // The image to display
    required this.onDelete, // The delete function to be executed on delete
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar contains the title and a delete button
      appBar: AppBar(
        title: Text('Full Size Image'), // The title of the screen
        actions: [
          // Delete button in the app bar
          IconButton(
            icon: Icon(Icons.delete), // Icon to indicate deletion
            onPressed: () {
              onDelete(); // Call the onDelete function passed from the parent widget
              Navigator.of(context).pop(); // Close the full-size image screen
            },
          ),
        ],
      ),
      // Body of the screen displays the full-size image
      body: Center(
        child: Image.file(image), // Display the image passed to this screen
      ),
    );
  }
}
