import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart'; // Assuming UserModel contains current user data or structure

// Modern navy color palette (adjust if your app uses a different set)
const Color kPrimaryColor = Color(0xFF1E3A8A);    // Deep navy
const Color kSecondaryColor = Color(0xFF334155);  // Slate navy
const Color kBackgroundColor = Color(0xFFF1F5F9); // Cool gray
const Color kTextColor = Color(0xFF0F172A);       // Dark navy
const Color kAccentColor = Color(0xFF3B82F6);     // Bright blue

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(); // Added name controller
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Fetch current user data and populate text fields
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _emailController.text = user.email ?? '';
        
        // Fetch name and phone from Firestore
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          _nameController.text = userDoc['name'] ?? '';
          _phoneController.text = userDoc['phone'] ?? '';
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء تحميل بيانات المستخدم')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose(); // Dispose name controller
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Update email in Firebase Authentication
          if (_emailController.text.trim() != user.email) {
            await user.updateEmail(_emailController.text.trim());
          }

          // Update password in Firebase Authentication (if provided)
          if (_passwordController.text.isNotEmpty) {
            await user.updatePassword(_passwordController.text);
          }

          // Update name and phone in Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح!')),
        );
         // Navigate back to profile screen after successful update
         Navigator.pop(context);

      } on FirebaseAuthException catch (e) {
        String errorMessage = 'حدث خطأ أثناء تحديث الملف الشخصي';
        if (e.code == 'requires-recent-login') {
          errorMessage = 'الرجاء تسجيل الدخول مرة أخرى لتحديث البريد الإلكتروني أو كلمة المرور';
        } else if (e.code == 'email-already-in-use') {
           errorMessage = 'هذا البريد الإلكتروني مستخدم بالفعل';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${errorMessage}: ${e.message}')),
        );

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تحديث الملف الشخصي: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality( // Add Directionality for Arabic
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: kPrimaryColor, // Apply primary color
          title: const Text(
            'تحديث المعلومات الشخصية', // Arabic title
            style: TextStyle(color: Colors.white), // White text color
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white), // Arabic back icon
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0), // Increased padding
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                 Text(
                  'تحديث المعلومات الشخصية', // Section title
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 24.0), // Spacing
                 _buildTextField(
                  controller: _nameController,
                  label: 'الاسم', // Arabic label
                  icon: Icons.person_outline,
                   validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال اسمك'; // Arabic validation
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                _buildTextField(
                  controller: _phoneController,
                  label: 'رقم الجوال', // Arabic label
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                   validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال رقم جوالك'; // Arabic validation
                    }
                     // Add phone number format validation if needed
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                _buildTextField(
                  controller: _emailController,
                  label: 'البريد الإلكتروني', // Arabic label
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال بريدك الإلكتروني'; // Arabic validation
                    }
                    // Add email format validation if needed
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                _buildTextField(
                  controller: _passwordController,
                  label: 'كلمة المرور (اختياري)', // Arabic label
                  icon: Icons.lock_outline,
                  obscureText: true,
                   validator: (value) {
                     // Password is optional for update, only validate if not empty
                    if (value != null && value.isNotEmpty && value.length < 6) {
                       return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'; // Arabic validation
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor, // Button color
                    padding: const EdgeInsets.symmetric(vertical: 16), // Button padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Button border radius
                    ),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) // White indicator
                    : const Text(
                        'حفظ التعديلات', // Arabic button text
                        style: TextStyle(fontSize: 18, color: Colors.white), // Button text style
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText ? _obscurePassword : false,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl, // Set text direction for input
      textAlign: TextAlign.right, // Align text to the right
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kSecondaryColor), // Label color
        prefixIcon: Icon(icon, color: kPrimaryColor), // Icon color
         suffixIcon: obscureText ? IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: kPrimaryColor, // Icon color
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // Border radius
          borderSide: BorderSide(color: kSecondaryColor.withOpacity(0.5)), // Border color
        ),
         enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kSecondaryColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryColor), // Focused border color
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), // Content padding
      ),
      validator: validator,
    );
  }
} 