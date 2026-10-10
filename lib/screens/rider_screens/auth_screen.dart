import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'home_screen.dart';
import 'verify_code_screen.dart';

// Modern navy color palette
const Color kPrimaryColor = Color(0xFF1E3A8A);    // Deep navy
const Color kSecondaryColor = Color(0xFF334155);  // Slate navy
const Color kBackgroundColor = Color(0xFFF1F5F9); // Cool gray
const Color kTextColor = Color(0xFF0F172A);       // Dark navy
const Color kAccentColor = Color(0xFF3B82F6);     // Bright blue

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> showCustomDialog(String message, {bool isError = false}) async {
    if (!mounted) return;
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: isError ? Colors.red : Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isError ? Colors.red : kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    'حسناً',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> sendVerificationEmail(String verificationCode, String email) async {
    if (!mounted) return;

    try {
      final smtpServer = gmail('mariamjaber.kar@gmail.com', 'plcg otvz trbg kgzf');
      
      final message = Message()
        ..from = Address('mariamjaber.kar@gmail.com', 'تطبيق مشوار')
        ..recipients.add(email)
        ..subject = 'إرسال رمز التحقق'
        ..text = 'رمز التحقق الخاص بك هو: $verificationCode';

      await send(message, smtpServer);
      
      if (!mounted) return;
      await showCustomDialog('تم إرسال رمز التحقق إلى بريدك الإلكتروني');
    } catch (e) {
      if (!mounted) return;
      await showCustomDialog('فشل في إرسال البريد: $e', isError: true);
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (isLogin) {
          // تسجيل الدخول
          final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

          // جلب بيانات المستخدم من Firestore
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          if (userDoc.exists) {
            UserModel.currentUser = UserModel(
              id: userCredential.user!.uid,
              name: userDoc['name'],
              email: userDoc['email'],
              phone: userDoc['phone'],
            );

            // الانتقال إلى HomeScreen بعد تسجيل الدخول
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    riderId: userCredential.user!.uid,
                  ),
                ),
              );
            }
          } else {
            // User found in auth but not in users collection
            await FirebaseAuth.instance.signOut(); // Sign out the user
            if (mounted) {
              await showCustomDialog('لم يتم العثور على حساب بهذا البريد الإلكتروني', isError: true);
            }
          }
        } else {
          // إنشاء حساب جديد
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

          // إنشاء رمز تحقق من 5 أرقام
          String verificationCode = '';
          for (int i = 0; i < 5; i++) {
            verificationCode += Random().nextInt(10).toString();
          }

          // حفظ بيانات المستخدم في Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

          // حفظ رمز التحقق في Firestore
          await FirebaseFirestore.instance
              .collection('verification_codes')
              .doc(userCredential.user!.uid)
              .set({
            'code': verificationCode,
            'email': _emailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
            'isVerified': false
          });

          // إرسال البريد الإلكتروني
          await sendVerificationEmail(verificationCode, _emailController.text.trim());
          
          // تسجيل خروج المستخدم مؤقتًا
          await FirebaseAuth.instance.signOut();

          // الانتقال إلى شاشة التحقق
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => VerifyCodeScreen(userId: userCredential.user!.uid),
              ),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'حدث خطأ ما';
        
        if (e.code == 'user-not-found') {
          errorMessage = 'لم يتم العثور على حساب بهذا البريد الإلكتروني';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'كلمة المرور غير صحيحة';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'هذا البريد الإلكتروني مستخدم بالفعل';
        } else if (e.code == 'weak-password') {
          errorMessage = 'كلمة المرور ضعيفة جداً';
        }

        await showCustomDialog(errorMessage, isError: true);
      } catch (e) {
        await showCustomDialog('حدث خطأ ما. الرجاء المحاولة مرة أخرى', isError: true);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'الرجاء إدخال بريد إلكتروني صحيح';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال رقم الهاتف';
    }

    if (value.length == 8) {
      if (!value.startsWith('054')) {
        return 'رقم الهاتف المكون من 8 أرقام يجب أن يبدأ بـ 054';
      }
    } else if (value.length == 9) {
      if (!RegExp(r'^(77|78|70|71|73)').hasMatch(value)) {
        return 'رقم الهاتف المكون من 9 أرقام يجب أن يبدأ بـ 77 أو 78 أو 70 أو 71 أو 73';
      }
    } else {
      return 'رقم الهاتف يجب أن يكون 8 أو 9 أرقام';
    }

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'رقم الهاتف يجب أن يحتوي على أرقام فقط';
    }

    return null;
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      // Logo
                    Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 200,  // زيادة من 120 إلى 150
                        width: 200,   // زيادة من 120 إلى 150
                        fit: BoxFit.contain,
                      ),
                    ),
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
                              onTap: () => setState(() => isLogin = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isLogin ? kPrimaryColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'تسجيل الدخول',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isLogin ? Colors.white : kPrimaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => isLogin = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !isLogin ? kPrimaryColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'إنشاء حساب',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: !isLogin ? Colors.white : kPrimaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!isLogin) ...[
                      _buildTextField(
                        controller: _nameController,
                        label: 'الاسم',
                        icon: Icons.person_outline,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'الرجاء إدخال الاسم' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'رقم الهاتف',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildTextField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'كلمة المرور',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 32),
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
                        onPressed: _isLoading ? null : _submitForm,
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
                            : Text(
                                isLogin ? 'تسجيل الدخول' : 'إنشاء حساب',
                                style: const TextStyle(
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
        obscureText: obscureText ? _obscurePassword : false,
        keyboardType: keyboardType,
        style: const TextStyle(color: kTextColor),
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: kSecondaryColor),
          prefixIcon: Icon(icon, color: kPrimaryColor),
          suffixIcon: obscureText ? IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: kPrimaryColor,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ) : null,
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
        validator: validator,
      ),
    );
  }
}