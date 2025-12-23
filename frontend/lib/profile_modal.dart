import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class ProfileModal extends StatefulWidget {
  const ProfileModal({Key? key}) : super(key: key);

  @override
  State<ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<ProfileModal> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  
  bool _isEditing = false;
  bool _isChangingPassword = false;
  bool _isLoading = false;
  String? _error;

  // Color palette
  final Color color0 = const Color(0xFFC080D); // orange/pink
  final Color color1 = Colors.black; // black background
  final Color color2 = const Color(0xFF38263F); // dark purple
  final Color color3 = const Color(0xFF52425C); // medium purple
  final Color color4 = const Color(0xFF7A6284); // light purple

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _usernameController.text = user.username;
      _emailController.text = user.email;
      _fullNameController.text = user.fullName ?? '';
      _bioController.text = user.bio ?? '';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authProvider = context.read<AuthProvider>();

    bool success = await authProvider.updateUser(
      username: _usernameController.text,
      email: _emailController.text,
      fullName: _fullNameController.text,
      bio: _bioController.text,
      currentPassword: _isChangingPassword ? _currentPasswordController.text : null,
      newPassword: _isChangingPassword ? _newPasswordController.text : null,
    );

    if (mounted) {
      if (success) {
        setState(() {
          _isEditing = false;
          _isChangingPassword = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmNewPasswordController.clear();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _error = authProvider.error;
        });
      }
    }
  }

  Future<void> _logout() async {
    final authProvider = context.read<AuthProvider>();
    bool success = await authProvider.logout();
    
    if (mounted && success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: color2,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: color4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: color0, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_isEditing)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _isChangingPassword = false;
                            _error = null;
                            _loadUserData();
                          });
                        },
                        icon: Icon(Icons.close, color: color4),
                      ),
                  ],
                ),
              ),

              // Error message
              if (_error != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Profile Picture Placeholder
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: color3,
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: color4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Username Field
                      TextFormField(
                        controller: _usernameController,
                        enabled: _isEditing,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: TextStyle(color: _isEditing ? color4 : Colors.white70),
                          filled: true,
                          fillColor: _isEditing ? color3 : color2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _isEditing ? color4 : Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _isEditing ? color4 : Colors.white24),
                          ),
                          prefixIcon: Icon(Icons.person, color: _isEditing ? color0 : Colors.white70),
                        ),
                        validator: (value) {
                          if (_isEditing && (value == null || value.isEmpty)) {
                            return 'Username is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: _isEditing ? color4 : Colors.white70),
                          filled: true,
                          fillColor: _isEditing ? color3 : color2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _isEditing ? color4 : Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _isEditing ? color4 : Colors.white24),
                          ),
                          prefixIcon: Icon(Icons.email, color: _isEditing ? color0 : Colors.white70),
                        ),
                        validator: (value) {
                          if (_isEditing && (value == null || value.isEmpty)) {
                            return 'Email is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Full Name Field
                      TextFormField(
                        controller: _fullNameController,
                        enabled: _isEditing,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(color: _isEditing ? color4 : Colors.white70),
                          filled: true,
                          fillColor: _isEditing ? color3 : color2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _isEditing ? color4 : Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _isEditing ? color4 : Colors.white24),
                          ),
                          prefixIcon: Icon(Icons.badge, color: _isEditing ? color0 : Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bio Field
                      TextFormField(
                        controller: _bioController,
                        enabled: _isEditing,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Bio',
                          labelStyle: TextStyle(color: _isEditing ? color4 : Colors.white70),
                          filled: true,
                          fillColor: _isEditing ? color3 : color2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _isEditing ? color4 : Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _isEditing ? color4 : Colors.white24),
                          ),
                          prefixIcon: Icon(Icons.info_outline, color: _isEditing ? color0 : Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Password Change Section
                      if (_isEditing) ...[
                        Row(
                          children: [
                            Text(
                              'Change Password',
                              style: TextStyle(
                                color: color0,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: _isChangingPassword,
                              onChanged: (value) {
                                setState(() {
                                  _isChangingPassword = value;
                                  if (!value) {
                                    _currentPasswordController.clear();
                                    _newPasswordController.clear();
                                    _confirmNewPasswordController.clear();
                                  }
                                });
                              },
                              activeColor: color0,
                            ),
                          ],
                        ),
                        if (_isChangingPassword) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _currentPasswordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Current Password',
                              labelStyle: TextStyle(color: color4),
                              filled: true,
                              fillColor: color3,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: color4),
                              ),
                              prefixIcon: Icon(Icons.lock, color: color0),
                            ),
                            validator: (value) {
                              if (_isChangingPassword && (value == null || value.isEmpty)) {
                                return 'Current password is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              labelStyle: TextStyle(color: color4),
                              filled: true,
                              fillColor: color3,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: color4),
                              ),
                              prefixIcon: Icon(Icons.lock_outline, color: color0),
                            ),
                            validator: (value) {
                              if (_isChangingPassword && (value == null || value.isEmpty)) {
                                return 'New password is required';
                              }
                              if (_isChangingPassword && value != null && value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmNewPasswordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Confirm New Password',
                              labelStyle: TextStyle(color: color4),
                              filled: true,
                              fillColor: color3,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: color4),
                              ),
                              prefixIcon: Icon(Icons.lock_outline, color: color0),
                            ),
                            validator: (value) {
                              if (_isChangingPassword && value != _newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],

                      // Action Buttons
                      if (_isEditing)
                        ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      if (!_isEditing)
                        ElevatedButton(
                          onPressed: () => setState(() => _isEditing = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Logout Button
                      OutlinedButton(
                        onPressed: _logout,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: color4),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            color: color4,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
