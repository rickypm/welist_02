import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _storageService = StorageService();

  File? _selectedImage;
  String?  _currentAvatarUrl;
  String _selectedCity = AppConfig.defaultCity;
  bool _isLoading = false;
  bool _isUploading = false;

  final List<String> _cities = [
    'Shillong',
    'Guwahati',
    'Tura',
    'Jowai',
    'Nongstoin',
    'Williamnagar',
    'Baghmara',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone ??  '';
      _currentAvatarUrl = user.avatarUrl;
      _selectedCity = user.city;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _storageService.pickImage();
    if (file != null) {
      setState(() => _selectedImage = file);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    String?  avatarUrl = _currentAvatarUrl;

    // Upload new image if selected
    if (_selectedImage != null) {
      setState(() => _isUploading = true);

      avatarUrl = await _storageService.uploadAvatar(
        file: _selectedImage!,
        odId: authProvider.user! .id,
      );

      setState(() => _isUploading = false);
    }

    // Update profile
    final success = await authProvider.updateProfile({
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      'city': _selectedCity,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    });

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully! '),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:  Text(authProvider.error ?? 'Failed to update profile'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: AppTextStyles.h3),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    // Avatar Container
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppColors.inputBorderGradient,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: _selectedImage != null
                              ? Image.file(
                                  _selectedImage!,
                                  fit:  BoxFit.cover,
                                  width: 114,
                                  height: 114,
                                )
                              : _currentAvatarUrl != null
                                  ? Image.network(
                                      _currentAvatarUrl!,
                                      fit: BoxFit.cover,
                                      width: 114,
                                      height: 114,
                                      errorBuilder: (_, __, ___) =>
                                          _buildAvatarPlaceholder(),
                                    )
                                  : _buildAvatarPlaceholder(),
                        ),
                      ),
                    ),

                    // Edit Button
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.background,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Iconsax.camera,
                            color: AppColors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),

                    // Uploading Indicator
                    if (_isUploading)
                      Positioned. fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color:  AppColors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height:  32),

              // Name Field
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your name',
                icon: Iconsax.user,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height:  20),

              // Phone Field
              _buildTextField(
                controller:  _phoneController,
                label:  'Phone Number',
                hint: 'Enter your phone number',
                icon: Iconsax.call,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // City Dropdown
              _buildCityDropdown(),
              const SizedBox(height: 40),

              // Save Button
              AppButton(
                text: 'Save Changes',
                onPressed: _handleSave,
                isLoading: _isLoading,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    final authProvider = context.watch<AuthProvider>();
    final name = authProvider.user?.name ??  'U';

    return Container(
      width: 114,
      height: 114,
      color: AppColors.surfaceLight,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType?  keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize:  14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height:  8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color:  AppColors.textMuted),
              prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment. start,
      children: [
        const Text(
          'City',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize:  14,
            fontWeight:  FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCity,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              icon: const Icon(
                Iconsax.arrow_down_1,
                color: AppColors.textMuted,
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              items: _cities.map((city) {
                return DropdownMenuItem(
                  value: city,
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.location,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(city),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCity = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}