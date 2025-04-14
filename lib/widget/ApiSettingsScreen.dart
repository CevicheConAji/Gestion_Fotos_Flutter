import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _endpointController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _apiKeyController.text = prefs.getString('apiKey') ?? '';
    _endpointController.text = prefs.getString('apiEndpoint') ?? '';
  }

  Future<void> _saveSettings() async {
    // Save settings
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiKey', _apiKeyController.text.trim());
    await prefs.setString('apiEndpoint', _endpointController.text.trim());

    // After saving, pop and go back to home
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('API Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(labelText: 'API Key'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _endpointController,
              decoration: InputDecoration(labelText: 'API Endpoint'),
            ),
            SizedBox(height: 24),
            ElevatedButton(onPressed: _saveSettings, child: Text('Save')),
          ],
        ),
      ),
    );
  }
}
