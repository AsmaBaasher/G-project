import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'vehicle_info_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';
import 'login_screen.dart';

// Modern navy color palette
const Color kPrimaryColor = Color(0xFF1E3A8A);    // Deep navy
const Color kSecondaryColor = Color(0xFF334155);  // Slate navy
const Color kBackgroundColor = Color(0xFFF1F5F9); // Cool gray
const Color kTextColor = Color(0xFF0F172A);       // Dark navy
const Color kAccentColor = Color(0xFF3B82F6);     // Bright blue

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  File? _imageFile;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
    String? selectedVehicleType;

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) { // 5MB limit
          _showErrorDialog("حجم الصورة كبير جداً. الحد الأقصى هو 5 ميجابايت");
          return;
        }

        setState(() {
          _imageFile = File(pickedFile.path);
          _base64Image = base64Encode(bytes);
        });
      }
    } catch (e) {
      _showErrorDialog("خطأ في اختيار الصورة: ${e.toString()}");
    }
  }

  Future<void> _validateAndRegister() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      _showErrorDialog("الرجاء إدخال الاسم");
      return;
    }
    if (phone.isEmpty) {
      _showErrorDialog("الرجاء إدخال رقم الهاتف");
      return;
    }
    if (email.isEmpty || !email.contains("@")) {
      _showErrorDialog("الرجاء إدخال بريد إلكتروني صحيح");
      return;
    }
    if (password.length < 6) {
      _showErrorDialog("كلمة المرور يجب أن تكون 6 أحرف على الأقل");
      return;
    }

    setState(() {
      _isLoading = true;
    });
if (!name.isEmpty && !phone.isEmpty && !email.isEmpty && !password.isEmpty)
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance.collection('driverUsers').doc(userCredential.user!.uid).set({
        'name': name,
        'phone': phone,
        'email': email,
        'profileImage': _base64Image,
        'createdAt': FieldValue.serverTimestamp(),
        'vehicleType': 'no',
        'hasBankInfo': false,
        'isAvailable':true,
        'rating':0.0,
        'totalRatings':0,
        'tripCount':0,
        
      });

      if (mounted) {
        Navigator.push(context,
          MaterialPageRoute(builder: (context) => VehicleInfoScreen(userId: userCredential.user!.uid)),
          
         
         );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "فشل إنشاء الحساب";
      if (e.code == 'weak-password') {
        errorMessage = "كلمة المرور ضعيفة جداً";
      } else if (e.code == 'email-already-in-use') {
        errorMessage = "البريد الإلكتروني مستخدم بالفعل";
      } else if (e.code == 'invalid-email') {
        errorMessage = "البريد الإلكتروني غير صالح";
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog("حدث خطأ غير متوقع: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      
      builder: (context) => AlertDialog(
        title: const Text("خطأ", style: TextStyle(color: kPrimaryColor)),
        content: Text(message, textDirection: TextDirection.rtl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("حسناً", style: TextStyle(color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.05),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Image.asset(
                      "assets/images/logo.png",
                      height: 200,
                      width: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Login/Signup tabs
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryColor.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _navigateToLogin,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "تسجيل الدخول",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "إنشاء حساب",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Profile Image Picker
                  Center(
                    child: GestureDetector(
                      onTap: _isLoading ? null : _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kPrimaryColor.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          image: _imageFile != null
                              ? DecorationImage(
                                  image: FileImage(_imageFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _imageFile == null
                            ? Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: kPrimaryColor,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Name field
                  _buildTextField(
                    controller: _nameController,
                    label: "الاسم",
                    icon: Icons.person_outline,
                    validator: (value) => value?.isEmpty ?? true ? 'الرجاء إدخال الاسم' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone field
                  _buildTextField(
                    controller: _phoneController,
                    label: "رقم الهاتف",
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) => value?.isEmpty ?? true ? 'الرجاء إدخال رقم الهاتف' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Email field
                  _buildTextField(
                    controller: _emailController,
                    label: "البريد الإلكتروني",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال البريد الإلكتروني';
                      }
                      if (!value.contains("@")) {
                        return 'الرجاء إدخال بريد إلكتروني صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Password field
                  _buildTextField(
                    controller: _passwordController,
                    label: "كلمة المرور",
                    icon: Icons.lock_outlined,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال كلمة المرور';
                      }
                      if (value.length < 6) {
                        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),       
                  // Register button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: kPrimaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _validateAndRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'إنشاء حساب',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
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
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        enabled: !_isLoading,
        validator: validator,
        style: const TextStyle(color: kTextColor),
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: kSecondaryColor),
          prefixIcon: Icon(icon, color: kPrimaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kSecondaryColor.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: kSecondaryColor.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryColor),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
 InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF1E3A8A)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: const Color(0xFF1E3A8A).withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

}