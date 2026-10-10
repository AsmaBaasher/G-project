import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String userId;
  
  const VerifyCodeScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _VerifyCodeScreenState createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  TextEditingController codeController = TextEditingController();
  bool isResending = false;

  // Modern navy color palette
  static const Color kPrimaryColor = Color(0xFF1E3A8A);    // Deep navy
  static const Color kSecondaryColor = Color(0xFF334155);  // Slate navy
  static const Color kBackgroundColor = Color(0xFFF1F5F9); // Cool gray
  static const Color kTextColor = Color(0xFF0F172A);       // Dark navy

  void _verifyCode() async {
    if (codeController.text.isEmpty) {
      _showSnackBar(" يرجى إدخال رمز التحقق");
      return;
    }

    try {
      // التحقق من الرمز
      final doc = await FirebaseFirestore.instance
          .collection('verification_codes')
          .doc(widget.userId)
          .get();

      if (!doc.exists) {
        _showSnackBar(" حدث خطأ في التحقق");
        return;
      }

      final savedCode = doc.data()?['code'];
      final isVerified = doc.data()?['isVerified'] ?? false;

      if (isVerified) {
        _showSnackBar(" تم التحقق من هذا الحساب مسبقاً");
        return;
      }

      if (savedCode == codeController.text.trim()) {
        // تحديث حالة التحقق
        await FirebaseFirestore.instance
            .collection('verification_codes')
            .doc(widget.userId)
            .update({'isVerified': true});

             await FirebaseFirestore.instance
            .collection('verification_codes')
            .doc(widget.userId)
            .delete();

        // الانتقال إلى الصفحة التالية
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        
        _showSnackBar(" تم التحقق بنجاح!");
      } else {
        _showSnackBar(" الرمز غير صحيح، يرجى المحاولة مرة أخرى");
      }
    } catch (e) {
      _showSnackBar(" حدث خطأ أثناء التحقق");
    }
  }

  void _resendCode() async {
    setState(() {
      isResending = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        _showSnackBar(" تم إعادة إرسال رمز التحقق");
      }
    } catch (e) {
      _showSnackBar(" حدث خطأ أثناء إعادة إرسال الرمز");
    } finally {
      setState(() {
        isResending = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "تحقق من الرمز",
          style: TextStyle(fontFamily: 'Tajawal' ,color: Colors.white,),
        ),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView( // Added this wrapper
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_user,
                            size: 50,
                            color: kPrimaryColor,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "تحقق من الرمز",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "يرجى إدخال رمز التحقق المرسل عبر البريد الإلكتروني",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: kSecondaryColor,
                              fontSize: 16,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: codeController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 5,
                            style: TextStyle(
                              fontSize: 20,
                              color: kTextColor,
                              letterSpacing: 8,
                              fontFamily: 'Tajawal',
                            ),
                            decoration: InputDecoration(
                              hintText: "•••••",
                              filled: true,
                              fillColor: kBackgroundColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: kPrimaryColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: kPrimaryColor, width: 2),
                              ),
                              counterText: "",
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _verifyCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "تحقق",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: isResending ? null : _resendCode,
                            child: Text(
                              isResending ? "جارٍ إعادة الإرسال..." : "إعادة إرسال الرمز",
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ),
                        ],
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

