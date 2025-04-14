// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trueway_ecommerce/providers/theme_provider.dart';
import 'package:trueway_ecommerce/widgets/Theme_Extensions.dart';
import 'package:trueway_ecommerce/widgets/common_widgets.dart';

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
              CommonWidgets.buildHeaderText(context, 'Select Language'),
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
      backgroundColor: context.adaptiveCardColor,
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: CommonWidgets.buildHeaderText(context, "Settings"),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Toggle
            _buildSettingsCard(
              title: "Dark Mode",
              icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
              trailing: Switch(
                value: isDarkMode,
                activeColor: primaryColor,
                onChanged: (_) {
                  themeProvider.toggleTheme();
                },
              ),
            ),
            const SizedBox(height: 10),

            // Notifications Toggle
            _buildSettingsCard(
              title: "Get Notifications",
              icon: Icons.notifications,
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
            const SizedBox(height: 10),

            // Notification Messages
            _buildSettingsCard(
              title: "Notification Messages",
              icon: Icons.message,
              onTap: () {
                // Handle navigation to notification messages
              },
            ),
            const SizedBox(height: 10),

            // Languages
            _buildSettingsCard(
              title: "Languages",
              icon: Icons.language,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedLanguage, style: textTheme.bodyMedium),
                  const SizedBox(width: 20),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              onTap: _selectLanguage,
            ),
            const SizedBox(height: 10),

            // Privacy and Terms
            _buildSettingsCard(
              title: "Privacy and Term",
              icon: Icons.lock,
              onTap: () {
                // Handle navigation to privacy and terms
              },
            ),
            const SizedBox(height: 10),

            // About Us
            _buildSettingsCard(
              title: "About Us",
              icon: Icons.info,
              onTap: () {
                // Handle navigation to about us
              },
            ),
            const SizedBox(height: 10),

            // Rate the app
            _buildSettingsCard(
              title: "Rate the app",
              icon: Icons.star,
              onTap: () {
                // Handle rate the app action
              },
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

  // Helper method to create consistent setting cards
  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      shape: Theme.of(context).cardTheme.shape,
      elevation: Theme.of(context).cardTheme.elevation,
      color: context.adaptiveCardColor,
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        title: Text(
          title,
          style: context.titleTextStyle.copyWith(fontSize: 16),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
