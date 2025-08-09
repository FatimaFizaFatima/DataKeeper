import 'package:data_keeper/database/database_helper.dart';
import 'package:data_keeper/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UserFormScreen extends StatefulWidget {
  final User? user;
  final bool isEditMode;

  const UserFormScreen({super.key, this.user, this.isEditMode = false});

  @override
  _UserFormScreenState createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;
  late TextEditingController _streetController;

  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _cityController = TextEditingController(text: widget.user?.city ?? '');
    _postalCodeController =
        TextEditingController(text: widget.user?.postalCode ?? '');
    _streetController = TextEditingController(text: widget.user?.street ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  void _launchPhone() async {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      _showErrorSnackbar('Phone number is empty');
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showErrorSnackbar('Could not launch phone dialer');
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final url = Uri.parse('https://wa.me/$phoneNumber');
    try {
      await launchUrl(url);
    } catch (e) {
      _showErrorSnackbar('Could not launch WhatsApp');
    }
  }

  Future<void> _launchMap(String address) async {
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$address');
    try {
      await launchUrl(url);
    } catch (e) {
      _showErrorSnackbar('Could not launch Maps');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = User(
          id: widget.user?.id,
          name: _nameController.text,
          phone: _phoneController.text,
          city: _cityController.text,
          postalCode: _postalCodeController.text,
          street: _streetController.text,
        );

        if (user.id == null) {
          await dbHelper.insertUser(user);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User added successfully')),
          );
        } else {
          await dbHelper.updateUser(user);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User updated successfully')),
          );
        }

        if (!mounted) return;
        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving user: $e')),
        );
      }
    }
  }

  bool get _isValidPhone {
    final phone = _phoneController.text.replaceAll(RegExp(r'[^0-9+]'), '');
    return phone.length >= 8;
  }

  bool get _hasLocationInfo {
    return _cityController.text.isNotEmpty ||
        _streetController.text.isNotEmpty ||
        _postalCodeController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? 'Add User' : 'Edit User',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildField(
                'Name',
                _nameController,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildPhoneField(),
              const SizedBox(height: 16),
              _buildLocationFields(),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'SAVE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (widget.isEditMode && widget.user != null) ...[
                const SizedBox(height: 16),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationFields() {
    return Column(
      children: [
        _buildField(
          'Street',
          _streetController,
          icon: Icons.home_outlined,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildField(
                'City',
                _cityController,
                icon: Icons.location_city_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildField(
                'Postal Code',
                _postalCodeController,
                icon: Icons.local_post_office_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          cursorColor: Colors.black,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black)),
            hintText: 'Enter $label',
            prefixIcon: icon != null ? Icon(icon) : null,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    Widget icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: SizedBox(
          width: 24,
          height: 24,
          child: Center(child: icon),
        ),
        label: Text(
          text,
          style: TextStyle(color: color),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          cursorColor: Colors.black,
          keyboardType: TextInputType.phone,
          onChanged: (value) {
            if (widget.isEditMode) {
              setState(() {});
            }
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            hintText: 'Enter phone number',
            prefixIcon: const Icon(Icons.phone),
            suffixIcon: widget.isEditMode && _isValidPhone
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.phone,
                            size: 20, color: Colors.blue),
                        onPressed: _launchPhone,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat,
                            size: 20, color: Colors.green),
                        onPressed: () => _launchWhatsApp(
                          _phoneController.text
                              .replaceAll(RegExp(r'[^0-9+]'), ''),
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter phone number';
            }
            final phone = value.replaceAll(RegExp(r'[^0-9+]'), '');
            if (phone.length < 8) {
              return 'Please enter a valid phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final address =
        '${_streetController.text}, ${_cityController.text}, ${_postalCodeController.text}';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            if (_isValidPhone) ...[
              _buildActionButton(
                'Call User',
                const Icon(
                  Icons.phone,
                  size: 20,
                  color: Colors.blue,
                ),
                Colors.blue,
                _launchPhone,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                'Message on WhatsApp',
                const Icon(
                  Icons.chat,
                  size: 20,
                  color: Colors.green,
                ),
                Colors.green,
                () => _launchWhatsApp(
                  _phoneController.text.replaceAll(RegExp(r'[^0-9+]'), ''),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (_hasLocationInfo)
              _buildActionButton(
                'View on Map',
                const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: Colors.red,
                ),
                Colors.red,
                () => _launchMap(address),
              ),
          ],
        ),
      ),
    );
  }
}
