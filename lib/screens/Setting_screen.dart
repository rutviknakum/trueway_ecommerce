// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNotificationsEnabled = true; // For Notifications Toggle
  String _selectedLanguage = 'English'; // Default language

  // List of available languages
  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
  ];

  // Function to open the language selection bottom sheet
  void _selectLanguage() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          height: 250,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color:
                      Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[800]
                          : Colors.grey[200],
                ),
              ),
              const SizedBox(height: 20),
              // List of languages
              Expanded(
                child: ListView.builder(
                  itemCount: _languages.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_languages[index]),
                      trailing:
                          _selectedLanguage == _languages[index]
                              ? Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.primary,
                              )
                              : null,
                      onTap: () {
                        setState(() {
                          _selectedLanguage =
                              _languages[index]; // Set selected language
                        });
                        Navigator.pop(context); // Close bottom sheet
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final primaryColor = Theme.of(context).colorScheme.primary;
    // Removed unused variable 'cardBackgroundColor'
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Toggle
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: SwitchListTile(
                secondary: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: primaryColor,
                ),
                title: Text("Dark Mode"),
                value: isDarkMode,
                onChanged: (_) {
                  themeProvider.toggleTheme();
                },
              ),
            ),
            const SizedBox(height: 10),

            // Notifications Toggle
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.notifications, color: primaryColor),
                title: const Text("Get Notifications"),
                trailing: Switch(
                  value: _isNotificationsEnabled,
                  activeColor: primaryColor,
                  onChanged: (bool value) {
                    setState(() {
                      _isNotificationsEnabled = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Notification Messages
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.message, color: primaryColor),
                title: const Text("Notification Messages"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Handle navigation to notification messages
                },
              ),
            ),
            const SizedBox(height: 10),

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.language, color: primaryColor),
                title: const Text("Languages"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedLanguage,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 20),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
                onTap: _selectLanguage, // Open language selection
              ),
            ),
            const SizedBox(height: 10),

            // Privacy and Terms
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.lock, color: primaryColor),
                title: const Text("Privacy and Term"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Handle navigation to privacy and terms
                },
              ),
            ),
            const SizedBox(height: 10),

            // About Us
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.info, color: primaryColor),
                title: const Text("About Us"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Handle navigation to about us
                },
              ),
            ),
            const SizedBox(height: 10),

            // Rate the app
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.star, color: primaryColor),
                title: const Text("Rate the app"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Handle rate the app action
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add custom action for FAB
        },
        child: const Icon(Icons.message),
        backgroundColor: primaryColor,
        elevation: 5,
      ),
    );
  }
}
