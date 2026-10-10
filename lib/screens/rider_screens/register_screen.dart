import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:g_project/screens/driver_screens/login_register/login_screen.dart';
import 'package:g_project/theme/app_colors.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'verify_code_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();


  final _formKey = GlobalKey<FormState>();
 
  Future<void> sendSeendEmail(String verificationCode , String email_name) async {
    if (!mounted) return;  // Add this check at the start
    
    try {
      final smtpServer = gmail('mariamjaber.kar@gmail.com', 'plcg otvz trbg kgzf');
      
      final message = Message()
        ..from = Address('mariamjaber.kar@gmail.com', 'تطبيق مشوار')
        ..recipients.add(email_name)
        ..subject = 'إرسال رمز التحقق'
        ..text = 'رمز التحقق الخاص بك هو: $verificationCode';  // Added verification code to the message

      await send(message, smtpServer);
      
      if (!mounted) return;  // Add this check before showing SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.kPrimaryColor,
          content: Text('تم إرسال البريد بنجاح!',style: TextStyle(
            color: AppColors.kBackgroundColor,
          ),)),
      );
    } catch (e) {
      if (!mounted) return;  // Add this check before showing error SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.kPrimaryColor,
          content: Text('فشل في إرسال البريد: $e',style: const TextStyle(
            color: AppColors.kBackgroundColor,
          ),),),
      );
    }
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      try {
       // إنشاء حساب المستخدم
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // إنشاء رمز تحقق من 5 أرقام
      String verificationCode = '';
      for (int i = 0; i < 5; i++) {
        verificationCode += Random().nextInt(10).toString();
      }

      // حفظ معلومات المستخدم في Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // حفظ الرمز في Firestore
      await FirebaseFirestore.instance.collection('verification_codes').doc(userCredential.user!.uid).set({
        'code': verificationCode,
        'email': emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': false
      });
        sendSeendEmail(verificationCode , emailController.text);
        // الانتقال إلى صفحة التحقق
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => VerifyCodeScreen(userId: userCredential.user!.uid)),
        );
        
        _showSnackBar(" تم إرسال رابط التحقق إلى بريدك الإلكتروني");
      } catch (e) {
        _showSnackBar(" حدث خطأ: ${e.toString()}");
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إنشاء حساب"),
        backgroundColor: const Color(0xFF6A0DAD),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "إنشاء حساب",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A0DAD)
                        ),
                      ),
                      const SizedBox(height: 20),

                    // 🟢 الاسم
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "الاسم",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "يرجى إدخال الاسم";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),

                    // 🟢 رقم الهاتف
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "رقم الهاتف",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "يرجى إدخال رقم الهاتف";
                        }
                        if (value.length < 9) {
                          return "رقم الهاتف غير صحيح";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),

                    // 🟢 البريد الإلكتروني
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "البريد الإلكتروني",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "يرجى إدخال البريد الإلكتروني";
                        }
                        if (!value.contains("@")) {
                          return "البريد الإلكتروني غير صحيح";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),

                    // 🟢 كلمة السر
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "كلمة السر",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return "كلمة السر يجب أن تكون على الأقل 6 أحرف";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // 🟢 زر إنشاء الحساب
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6A0DAD),
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text("إنشاء حساب", style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
