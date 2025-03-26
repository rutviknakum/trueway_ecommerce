// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
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
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Language',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 20),
              // List of languages
              Expanded(
                child: ListView.builder(
                  itemCount: _languages.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_languages[index]),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notifications Toggle
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.notifications, color: Colors.green),
                title: Text("Get Notifications"),
                trailing: Switch(
                  value: _isNotificationsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _isNotificationsEnabled = value;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 10),

            // Notification Messages
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.message, color: Colors.green),
                title: Text("Notification Messages"),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.language, color: Colors.green),
                title: Text(
                  "Languages",
                  // style: TextStyle( fontSize: 18),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedLanguage, style: TextStyle(fontSize: 16)),
                    SizedBox(width: 20),
                    Icon(
                      Icons.arrow_forward_ios,
                      //  size: 16,
                      // color: Colors.black,
                    ),
                  ],
                ),
                onTap: _selectLanguage, // Open language selection
              ),
            ),

            // Languages - Prominent Look
            // Container(
            //   width: double.infinity,
            //   padding: EdgeInsets.all(16.0),
            //   decoration: BoxDecoration(
            //     color: Colors.greenAccent.withOpacity(0.1),
            //     borderRadius: BorderRadius.circular(12),
            //     border: Border.all(color: Colors.greenAccent, width: 2),
            //   ),
            //   child: ListTile(
            //     leading: Icon(Icons.language, color: Colors.green),
            //     title: Text(
            //       "Languages",
            //       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            //     ),
            //     trailing: Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         Text(_selectedLanguage, style: TextStyle(fontSize: 16)),
            //         Icon(
            //           Icons.arrow_forward_ios,
            //           size: 16,
            //           color: Colors.black,
            //         ),
            //       ],
            //     ),
            //     onTap: _selectLanguage, // Open language selection
            //   ),
            // ),
            SizedBox(height: 10),

            // Privacy and Terms
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.lock, color: Colors.green),
                title: Text("Privacy and Term"),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            SizedBox(height: 10),

            // About Us
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.info, color: Colors.green),
                title: Text("About Us"),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            SizedBox(height: 10),

            // Rate the app
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.star, color: Colors.green),
                title: Text("Rate the app"),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add custom action for FAB
        },
        child: Icon(Icons.message),
        backgroundColor: Colors.green,
        elevation: 5,
      ),
    );
  }
}
