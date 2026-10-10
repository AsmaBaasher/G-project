import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:g_project/screens/driver_screens/driver_orders_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class PersonalScreen extends StatefulWidget {
  @override
  _PersonalScreenState createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  static const Color kPrimaryColor = Color(0xFF1E3A8A);
  static const Color kSecondaryColor = Color(0xFF334155);
  static const Color kTextColor = Color(0xFF0F172A);
  static const Color kErrorColor = Color(0xFFDC2626);
  static const Color kSuccessColor = Color(0xFF059669);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  File? _imageFile;
  String? _base64Image;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('driverUsers')
            .doc(user.uid)
            .get();
        final data = doc.data();
        if (data != null) {
          nameController.text = data['name'] ?? '';
          phoneController.text = data['phone'] ?? '';
          emailController.text = data['email'] ?? '';
          if (data['profileImage'] != null) {
            _base64Image = data['profileImage'];
            final bytes = base64Decode(_base64Image!);
            _imageFile = File.fromRawPath(bytes);
          }
        }
      }
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

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

  Future<void> _saveInfo() async {
    if (nameController.text.trim().isEmpty || 
        phoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'يرجى ملء جميع الحقول المطلوبة';
      });
      return;
    }

    if (!emailController.text.contains("@")) {
      setState(() {
        _errorMessage = 'يرجى إدخال بريد إلكتروني صحيح';
      });
      return;
    }

    if (passwordController.text.isNotEmpty && passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // تحديث البيانات في Firestore
        await FirebaseFirestore.instance
            .collection('driverUsers')
            .doc(user.uid)
            .set({
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
          'profileImage': _base64Image,
        }, SetOptions(merge: true));

        // تحديث كلمة المرور إذا تم تغييرها
        if (passwordController.text.isNotEmpty) {
          await user.updatePassword(passwordController.text);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ المعلومات بنجاح'),
            backgroundColor: kSuccessColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } on FirebaseException catch (e) {
      String errorMessage = 'حدث خطأ في الاتصال. يرجى المحاولة مرة أخرى';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'البريد الإلكتروني مستخدم بالفعل';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = 'يرجى تسجيل الخروج وإعادة تسجيل الدخول لتغيير كلمة المرور';
      }
      setState(() {
        _errorMessage = errorMessage;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع';
      });
    } finally {
      setState(() => _isSaving = false);
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
            child: const Text("حسناً", style: TextStyle(color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          iconTheme: IconThemeData(
            color: kBackgroundColor,
          ),
          title: const Text(
            'المعلومات الشخصية',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kBackgroundColor,
            ),
          ),
          backgroundColor: kPrimaryColor,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color.fromARGB(255, 148, 166, 212).withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
        
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: kPrimaryColor,
                    strokeWidth: 3,
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kErrorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kErrorColor),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: kErrorColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: kErrorColor,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // صورة الملف الشخصي
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
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'تحديث المعلومات الشخصية',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: kTextColor,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildTextField(
                                  controller: nameController,
                                  label: 'الاسم',
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: phoneController,
                                  label: 'رقم الجوال',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: emailController,
                                  label: 'البريد الإلكتروني',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: passwordController,
                                  label: 'كلمة المرور (اختياري)',
                                  icon: Icons.lock_outlined,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: kPrimaryColor,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSaveButton(),
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
    Widget? suffixIcon,
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
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        enabled: !_isLoading,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 16,
          color: kTextColor,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: kSecondaryColor,
            fontFamily: 'Tajawal',
            fontSize: 16,
          ),
          prefixIcon: Icon(icon, color: kPrimaryColor),
          suffixIcon: suffixIcon,
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
            borderSide: const BorderSide(color: kPrimaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveInfo,
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: _isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'حفظ التعديلات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
