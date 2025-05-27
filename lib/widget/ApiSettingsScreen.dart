import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ApiSettingsScreen widget allows the user to configure API key and endpoint
class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

// The state class for ApiSettingsScreen
class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController(); // Controller to handle API Key input
  final TextEditingController _endpointController = TextEditingController(); // Controller to handle API Endpoint input

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load saved settings when the widget is initialized
  }

  // Loads API settings from SharedPreferences
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // Set the text field values from the saved SharedPreferences data
    _apiKeyController.text = prefs.getString('apiKey') ?? ''; // Default to empty if no data exists
    _endpointController.text = prefs.getString('apiEndpoint') ?? ''; // Default to empty if no data exists
  }

  // Saves the API settings into SharedPreferences
  Future<void> _saveSettings() async {
    // Get instance of SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Save API Key and Endpoint to SharedPreferences
    await prefs.setString('apiKey', _apiKeyController.text.trim());
    await prefs.setString('apiEndpoint', _endpointController.text.trim());

    // After saving, go back to the previous screen (home)
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajustes API'), // Title of the settings screen
      ),
      body: Padding(
        padding: const EdgeInsets.all(16), // Padding around the form
        child: Column(
          children: [
            // Text field for entering API Key
            TextField(
              controller: _apiKeyController, // Bind the controller
              decoration: InputDecoration(labelText: 'API Key'), // Label for the text field
            ),
            SizedBox(height: 16), // Spacer between text fields
            // Text field for entering API Endpoint
            TextField(
              controller: _endpointController, // Bind the controller
              decoration: InputDecoration(labelText: 'API Endpoint'), // Label for the text field
            ),
            SizedBox(height: 24), // Spacer before the button
            // Save button to save the settings
            ElevatedButton(
              onPressed: _saveSettings, // Call _saveSettings when pressed
              child: Text('Guardar'), // Text on the button
            ),
          ],
        ),
      ),
    );
  }
}
