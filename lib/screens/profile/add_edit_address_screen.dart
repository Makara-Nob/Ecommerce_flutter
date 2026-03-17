import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/address_provider.dart';
import '../../models/address/address_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/toast_helper.dart';

class AddEditAddressScreen extends StatefulWidget {
  final AddressModel? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  
  bool _isDefault = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.address?.title ?? '');
    _nameController = TextEditingController(text: widget.address?.recipientName ?? '');
    _phoneController = TextEditingController(text: widget.address?.phoneNumber ?? '');
    _streetController = TextEditingController(text: widget.address?.streetAddress ?? '');
    _cityController = TextEditingController(text: widget.address?.city ?? '');
    _stateController = TextEditingController(text: widget.address?.state ?? '');
    _zipController = TextEditingController(text: widget.address?.zipCode ?? '');
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = Provider.of<AddressProvider>(context, listen: false);
    
    final newAddress = AddressModel(
      id: widget.address?.id ?? 0,
      title: _titleController.text.trim(),
      recipientName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      streetAddress: _streetController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
      zipCode: _zipController.text.trim().isEmpty ? null : _zipController.text.trim(),
      isDefault: _isDefault,
    );

    bool success;
    if (widget.address == null) {
      success = await provider.createAddress(newAddress);
    } else {
      success = await provider.updateAddress(widget.address!.id, newAddress);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ToastHelper.success(context, widget.address == null ? 'Address added' : 'Address updated');
      Navigator.pop(context);
    } else {
      ToastHelper.error(context, provider.error ?? 'Failed to save address');
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryStart),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryStart, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator ?? (value) {
        if (value == null || value.trim().isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add Address' : 'Edit Address',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryStart))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Recipient Name',
                      hint: 'John Doe',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: '+855 12 345 678',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(),
                    ),
                    
                    const Text(
                      'Address Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _titleController,
                      label: 'Address Title',
                      hint: 'Home, Office, Apartment...',
                      icon: Icons.label_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _streetController,
                      label: 'Street Address',
                      hint: 'House No, Street No, Village...',
                      icon: Icons.map_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _cityController,
                      label: 'City / Province',
                      hint: 'Phnom Penh',
                      icon: Icons.location_city_outlined,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _stateController,
                            label: 'State / District',
                            hint: 'Optional',
                            icon: Icons.map,
                            validator: (_) => null, // Optional
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _zipController,
                            label: 'Zip Code',
                            hint: '12000',
                            icon: Icons.markunread_mailbox_outlined,
                            keyboardType: TextInputType.number,
                            validator: (_) => null, // Optional
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: SwitchListTile(
                        value: _isDefault,
                        onChanged: (val) => setState(() => _isDefault = val),
                        title: const Text('Set as default address', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Use this address for automatically filling checkout', style: TextStyle(fontSize: 12)),
                        activeColor: AppColors.primaryStart,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _saveAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryStart,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Save Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
