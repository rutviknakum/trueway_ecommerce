import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trueway_ecommerce/providers/auth_provider.dart';
import 'package:trueway_ecommerce/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  EditProfileScreen({required this.userData});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressFormKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  File? _imageFile;
  bool _showAddressForm = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  // Address controllers
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data
    _nameController = TextEditingController(
      text: widget.userData['name'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.userData['email'] ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.userData['phone'] ?? '',
    );

    // Initialize address controllers
    Map<String, String> addressParts = _parseAddress(
      widget.userData['address'] ?? '',
    );
    _streetController = TextEditingController(
      text: addressParts['street'] ?? '',
    );
    _cityController = TextEditingController(text: addressParts['city'] ?? '');
    _stateController = TextEditingController(text: addressParts['state'] ?? '');
    _postalCodeController = TextEditingController(
      text: addressParts['postalCode'] ?? '',
    );
    _countryController = TextEditingController(
      text: addressParts['country'] ?? '',
    );

    // Check if address exists to determine whether to show address form
    _showAddressForm =
        (widget.userData['address'] != null &&
            widget.userData['address'].toString().isNotEmpty);

    // Load profile image if exists
    _loadProfileImage();

    // Debug print to check available user IDs
    print("Available user IDs in EditProfileScreen:");
    print("id: ${widget.userData['id']}");
    print("user_id: ${widget.userData['user_id']}");
    print("customer_id: ${widget.userData['customer_id']}");
  }

  // Helper method to parse address string into components
  Map<String, String> _parseAddress(String address) {
    Map<String, String> result = {
      'street': '',
      'city': '',
      'state': '',
      'postalCode': '',
      'country': '',
    };

    if (address.isEmpty) return result;

    List<String> parts = address.split(', ');

    if (parts.length >= 1) result['street'] = parts[0];
    if (parts.length >= 2) result['city'] = parts[1];
    if (parts.length >= 3) result['state'] = parts[2];
    if (parts.length >= 4) result['postalCode'] = parts[3];
    if (parts.length >= 5) result['country'] = parts[4];

    return result;
  }

  // Load profile image from storage
  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Ensure userId is a string before using it
      final userId =
          widget.userData['id']?.toString() ??
          widget.userData['user_id']?.toString() ??
          widget.userData['customer_id']?.toString();

      if (userId != null) {
        final imagePath = prefs.getString('user_${userId}_profile_image');
        if (imagePath != null) {
          final file = File(imagePath);
          if (await file.exists()) {
            setState(() {
              _imageFile = file;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading profile image: $e');
    }
  }

  // Save profile image to storage
  Future<void> _saveProfileImage(String userId, String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_${userId}_profile_image', imagePath);
    } catch (e) {
      print('Error saving profile image path: $e');
    }
  }

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
    }
  }

  // Show image source selection dialog
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.photo_camera, color: Colors.green),
                  title: Text('Take a photo', style: GoogleFonts.poppins()),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: Colors.green),
                  title: Text(
                    'Choose from gallery',
                    style: GoogleFonts.poppins(),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_imageFile != null)
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Remove photo', style: GoogleFonts.poppins()),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _imageFile = null;
                      });
                    },
                  ),
                SizedBox(height: 10),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  // Format address components into a single string
  String _formatAddress() {
    List<String> parts = [
      _streetController.text.trim(),
      _cityController.text.trim(),
      _stateController.text.trim(),
      _postalCodeController.text.trim(),
      _countryController.text.trim(),
    ];

    // Filter out empty parts
    parts = parts.where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) return '';
    return parts.join(', ');
  }

  // Ensure user ID is available in updated data
  void _ensureUserIdAvailable(Map<String, dynamic> updatedData) {
    // Check if we have any ID fields
    bool hasUserID =
        updatedData.containsKey('user_id') && updatedData['user_id'] != null;
    bool hasCustomerID =
        updatedData.containsKey('customer_id') &&
        updatedData['customer_id'] != null;
    bool hasID = updatedData.containsKey('id') && updatedData['id'] != null;

    // If we don't have any IDs, try to get them from widget.userData
    if (!hasUserID && !hasCustomerID && !hasID) {
      print('No IDs found in updatedData, retrieving from userData...');

      // Copy IDs from widget.userData if available
      if (widget.userData.containsKey('user_id') &&
          widget.userData['user_id'] != null) {
        updatedData['user_id'] = widget.userData['user_id'].toString();
        print('Retrieved user_id: ${updatedData['user_id']}');
      }

      if (widget.userData.containsKey('customer_id') &&
          widget.userData['customer_id'] != null) {
        updatedData['customer_id'] = widget.userData['customer_id'].toString();
        print('Retrieved customer_id: ${updatedData['customer_id']}');
      }

      if (widget.userData.containsKey('id') && widget.userData['id'] != null) {
        updatedData['id'] = widget.userData['id'].toString();
        print('Retrieved id: ${updatedData['id']}');
      }

      // If we still don't have any IDs, log a warning
      if (!updatedData.containsKey('user_id') &&
          !updatedData.containsKey('customer_id') &&
          !updatedData.containsKey('id')) {
        print('Warning: Cannot find any user IDs in the user data');
      }
    }
  }

  Future<void> _saveProfile() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate address form if visible
    if (_showAddressForm && !_addressFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Create updated user data map
      final updatedData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      // Add address if form is visible
      if (_showAddressForm) {
        final formattedAddress = _formatAddress();
        if (formattedAddress.isNotEmpty) {
          updatedData['address'] = formattedAddress;
        }
      }

      // Keep existing IDs - Convert to String to avoid type mismatches
      if (widget.userData.containsKey('id')) {
        updatedData['id'] = widget.userData['id'].toString();
      }
      if (widget.userData.containsKey('user_id')) {
        updatedData['user_id'] = widget.userData['user_id'].toString();
      }
      if (widget.userData.containsKey('customer_id')) {
        updatedData['customer_id'] = widget.userData['customer_id'].toString();
      }

      // Ensure at least one user ID is available (fallback mechanism)
      _ensureUserIdAvailable(updatedData);

      // Debug - print user IDs
      print('User IDs for profile update:');
      print('id: ${updatedData['id']}');
      print('user_id: ${updatedData['user_id']}');
      print('customer_id: ${updatedData['customer_id']}');

      // Save profile image if changed
      if (_imageFile != null) {
        final userId =
            updatedData['id'] ??
            updatedData['user_id'] ??
            updatedData['customer_id'];
        if (userId != null) {
          await _saveProfileImage(userId, _imageFile!.path);
        } else {
          print('Warning: Cannot save profile image - no user ID available');
        }
      }

      // Call API to update profile
      final response = await _updateUserProfile(authProvider, updatedData);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response['success']) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Profile updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Go back to profile screen
        Navigator.pop(context, true); // Pass true to indicate refresh needed
      } else {
        setState(() {
          _errorMessage = response['error'] ?? 'Failed to update profile';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred: $e';
      });
      print('Error updating profile: $e');
    }
  }

  Future<Map<String, dynamic>> _updateUserProfile(
    AuthProvider authProvider,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      // Check if we have any user identifier
      final hasUserId =
          updatedData.containsKey('user_id') && updatedData['user_id'] != null;
      final hasCustomerId =
          updatedData.containsKey('customer_id') &&
          updatedData['customer_id'] != null;
      final hasId = updatedData.containsKey('id') && updatedData['id'] != null;

      if (!hasUserId && !hasCustomerId && !hasId) {
        // Try to get current user info from auth provider
        // Use the property instead of method
        final currentUser = authProvider.currentUser;

        if (currentUser.containsKey('logged_in') &&
                currentUser['logged_in'] == true ||
            (currentUser.isNotEmpty && currentUser.containsKey('email'))) {
          // Add the user IDs from the current user data
          if (currentUser.containsKey('user_id') &&
              currentUser['user_id'] != null) {
            updatedData['user_id'] = currentUser['user_id'].toString();
            print('Added user_id from authProvider: ${updatedData['user_id']}');
          }

          if (currentUser.containsKey('customer_id') &&
              currentUser['customer_id'] != null) {
            updatedData['customer_id'] = currentUser['customer_id'].toString();
            print(
              'Added customer_id from authProvider: ${updatedData['customer_id']}',
            );
          }

          if (currentUser.containsKey('id') && currentUser['id'] != null) {
            updatedData['id'] = currentUser['id'].toString();
            print('Added id from authProvider: ${updatedData['id']}');
          }
        }

        // If we still don't have any IDs
        if (!updatedData.containsKey('user_id') &&
            !updatedData.containsKey('customer_id') &&
            !updatedData.containsKey('id')) {
          print('Warning: Cannot save user data - no user ID');
          return {
            'success': false,
            'error':
                'Cannot update profile - user ID not found. Please try logging in again.',
          };
        }
      }

      // Create a new API service instance
      final apiService = ApiService();

      // First, update the profile on the server via the API
      final apiResponse = await apiService.updateUserProfile(updatedData);

      if (apiResponse['success']) {
        // If API update is successful, update local state
        await authProvider.updateCurrentUser(updatedData);

        return {
          'success': true,
          'message': apiResponse['message'] ?? 'Profile updated successfully',
        };
      } else {
        return {
          'success': false,
          'error': apiResponse['error'] ?? 'Failed to update profile on server',
        };
      }
    } catch (e) {
      print('Error in _updateUserProfile: $e');
      return {'success': false, 'error': 'Failed to update profile: $e'};
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
              image:
                  _imageFile != null
                      ? DecorationImage(
                        image: FileImage(_imageFile!),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            child:
                _imageFile == null
                    ? Icon(Icons.person, size: 70, color: Colors.grey[800])
                    : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile picture
                      _buildProfileImage(),
                      SizedBox(height: 30),

                      // Error message
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Personal Information Section
                      _buildSectionTitle('Personal Information'),
                      SizedBox(height: 4),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Full name
                              Text(
                                'Full Name',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  hintText: 'Enter your full name',
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),

                              // Email
                              Text(
                                'Email',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                readOnly: true, // Email can't be changed
                                enabled: false,
                                decoration: InputDecoration(
                                  hintText: 'Your email address',
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),

                              // Phone
                              Text(
                                'Phone Number',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: 'Enter your phone number',
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Address Section Header with Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Address Information'),
                          Switch(
                            value: _showAddressForm,
                            onChanged: (value) {
                              setState(() {
                                _showAddressForm = value;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                      SizedBox(height: 4),

                      // Address Form (conditionally visible)
                      if (_showAddressForm)
                        Form(
                          key: _addressFormKey,
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Street Address
                                  Text(
                                    'Street Address',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  TextFormField(
                                    controller: _streetController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter your street address',
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                    validator: (value) {
                                      // Street is required if address form is shown
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Street address is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 16),

                                  // City
                                  Text(
                                    'City',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  TextFormField(
                                    controller: _cityController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter your city',
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'City is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 16),

                                  // Two-column layout for State and Postal Code
                                  Row(
                                    children: [
                                      // State/Province
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'State/Province',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            TextFormField(
                                              controller: _stateController,
                                              decoration: InputDecoration(
                                                hintText: 'State',
                                                filled: true,
                                                fillColor: Colors.grey[100],
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: BorderSide.none,
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 14,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      // Postal Code
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Postal Code',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            TextFormField(
                                              controller: _postalCodeController,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: InputDecoration(
                                                hintText: 'Postal Code',
                                                filled: true,
                                                fillColor: Colors.grey[100],
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: BorderSide.none,
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 14,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),

                                  // Country
                                  Text(
                                    'Country',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  TextFormField(
                                    controller: _countryController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter your country',
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Toggle switch to add address information',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                      SizedBox(height: 24),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Save Changes',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Cancel button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
    );
  }
}
