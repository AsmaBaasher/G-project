import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../driver_orders_screen.dart';
import 'register_screen.dart';
import '../bank_info_screen.dart';


// Modern navy color palette
const Color kPrimaryColor = Color(0xFF1E3A8A);    // Deep navy
const Color kSecondaryColor = Color(0xFF334155);  // Slate navy
const Color kBackgroundColor = Color(0xFFF1F5F9); // Cool gray
const Color kTextColor = Color(0xFF0F172A);       // Dark navy
const Color kAccentColor = Color(0xFF3B82F6);     // Bright blue

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _validateAndLogin() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains("@")) {
      _showErrorDialog("يرجى إدخال بريد إلكتروني صحيح");
      return;
    }
    if (_passwordController.text.length < 6) {
      _showErrorDialog("كلمة المرور يجب أن تكون على الأقل 6 أحرف");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // التحقق من وجود المستخدم في جدول driverUsers
      final userDoc = await FirebaseFirestore.instance
          .collection('driverUsers')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      if (userDoc.docs.isEmpty) {
        _showErrorDialog("هذا البريد الإلكتروني غير مسجل كسائق");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // تسجيل الدخول
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        // التحقق من حالة hasBankInfo
        final userData = userDoc.docs.first.data();
        final hasBankInfo = userData['hasBankInfo'] ?? false;

        if (!hasBankInfo) {
          // إذا لم يكن لديه معلومات بنكية، انتقل إلى شاشة إدخال المعلومات البنكية
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => BankInfoScreen()),
          );
        } else {
          // إذا كان لديه معلومات بنكية، انتقل مباشرة إلى شاشة السائق
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DriverScreen()),
          );
        }
      }
    } catch (e) {
      _showErrorDialog("فشل تسجيل الدخول: ${e.toString()}");
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
        title: Text("خطأ", style: TextStyle(color: kPrimaryColor)),
        content: Text(message, textDirection: TextDirection.rtl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("حسناً", 
                style: TextStyle(color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  void _navigateToSignUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterScreen()),
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "تسجيل الدخول",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: _navigateToSignUp,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "إنشاء حساب",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Email field
                  Container(
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
                      controller: _emailController,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        labelText: "البريد الإلكتروني",
                        labelStyle: const TextStyle(color: kSecondaryColor),
                        prefixIcon: Icon(Icons.email_outlined, color: kPrimaryColor),
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
                  ),
                  const SizedBox(height: 16),
                  
                  // Password field
                  Container(
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
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        labelText: "كلمة المرور",
                        labelStyle: const TextStyle(color: kSecondaryColor),
                        prefixIcon: Icon(Icons.lock_outlined, color: kPrimaryColor),
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
                  ),
                  const SizedBox(height: 32),
                  
                  // Login button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryColor.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _validateAndLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              "تسجيل الدخول",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
}