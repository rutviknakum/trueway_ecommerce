import 'package:flutter/material.dart';
import 'package:trueway_ecommerce/screens/Checkout_Screens/ShippingScreen.dart';
import 'package:trueway_ecommerce/utils/Theme_Config.dart';
import 'package:trueway_ecommerce/widgets/Theme_Extensions.dart';
import 'package:trueway_ecommerce/widgets/common_widgets.dart';

class AddressScreen extends StatefulWidget {
  @override
  _AddressScreenState createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Form validation
  final _addressFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.secondarySurfaceColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text("Checkout", style: context.titleTextStyle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCheckoutProgress(),
          Expanded(child: _buildAddressForm()),
        ],
      ),
      bottomSheet: _buildBottomButtons(context),
    );
  }

  Widget _buildCheckoutProgress() {
    return Container(
      padding: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.adaptiveCardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerTheme.color ?? Colors.transparent,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStepCircle("1", "ADDRESS", isActive: true),
                _buildStepConnector(isActive: false),
                _buildStepCircle("2", "SHIPPING", isActive: false),
                _buildStepConnector(isActive: false),
                _buildStepCircle("3", "PREVIEW", isActive: false),
                _buildStepConnector(isActive: false),
                _buildStepCircle("4", "PAYMENT", isActive: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(
    String number,
    String title, {
    bool isActive = false,
  }) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: isActive ? context.primaryButtonTextColor : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color:
                isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({bool isActive = false}) {
    return Container(
      width: 30,
      height: 2,
      color:
          isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
    );
  }

  Widget _buildAddressForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _addressFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommonWidgets.buildHeaderText(context, "Shipping Address"),
            SizedBox(height: 8),
            CommonWidgets.buildSubtitleText(
              context,
              "Please enter your shipping details",
            ),
            SizedBox(height: 24),

            // Full Name
            _buildTextField(
              controller: _nameController,
              label: "Full Name",
              hint: "John Doe",
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Address
            _buildTextField(
              controller: _addressController,
              label: "Street Address",
              hint: "123 Main Street",
              prefixIcon: Icons.home_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // City
            _buildTextField(
              controller: _cityController,
              label: "City",
              hint: "Mumbai",
              prefixIcon: Icons.location_city_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your city';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Row for State and ZIP
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _stateController,
                    label: "State",
                    hint: "Maharashtra",
                    prefixIcon: Icons.map_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _zipController,
                    label: "PIN Code",
                    hint: "400001",
                    prefixIcon: Icons.pin_drop_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (value.length != 6) {
                        return 'Invalid PIN';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Phone
            _buildTextField(
              controller: _phoneController,
              label: "Phone Number",
              hint: "9876543210",
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (value.length < 10) {
                  return 'Invalid phone number';
                }
                return null;
              },
            ),
            SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          prefixIcon,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).dividerTheme.color ?? Colors.transparent,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).dividerTheme.color ?? Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.dangerColor, width: 2),
        ),
        filled: true,
        fillColor:
            context.isDarkMode
                ? Theme.of(context).inputDecorationTheme.fillColor
                : Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: TextStyle(fontSize: 16),
      validator: validator,
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.adaptiveCardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      height: 80,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (_addressFormKey.currentState!.validate()) {
              // Pass shipping details to the next screen
              final shippingAddress = {
                'name': _nameController.text,
                'address': _addressController.text,
                'city': _cityController.text,
                'state': _stateController.text,
                'zip': _zipController.text,
                'phone': _phoneController.text,
              };

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ShippingScreen(shippingAddress: shippingAddress),
                ),
              );
            }
          },
          child: Text(
            "CONTINUE TO SHIPPING",
            style: TextStyle(
              color: context.primaryButtonTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          style: ThemeConfig.getPrimaryButtonStyle(),
        ),
      ),
    );
  }
}
