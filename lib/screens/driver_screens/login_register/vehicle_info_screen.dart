import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'verify_code_screen.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

const Color kPrimaryColor = Color(0xFF1E3A8A); // Deep navy
const Color kSecondaryColor = Color(0xFF334155); // Slate navy
const Color kBackgroundColor = Color(0xFFF1F5F9); // Cool gray
const Color kTextColor = Color(0xFF0F172A); // Dark navy
const Color kAccentColor = Color(0xFF3B82F6);

class VehicleInfoScreen extends StatefulWidget {
  final String userId;

  const VehicleInfoScreen({
    Key? key,
    required this.userId,
  });
  @override
  _VehicleInfoScreenState createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  String? selectedVehicleType;
  final TextEditingController ownershipNumberController =
      TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController permanentLocationController =
      TextEditingController();
  final TextEditingController accessAreaController = TextEditingController();
  final TextEditingController pricePerKmController = TextEditingController();
  PlatformFile? selectedPdf;
  File? _carImageFile;
  String? _carImageBase64;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickCarImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          // 5MB limit
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text("حجم الصورة كبير جداً. الحد الأقصى هو 5 ميجابايت")),
          );
          return;
        }

        setState(() {
          _carImageFile = File(pickedFile.path);
          _carImageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في اختيار الصورة: ${e.toString()}")),
      );
    }
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      selectedPdf = result.files.first;
      setState(() {});
    }
  }

  void _navigateToVerifyCode() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => VerifyCodeScreen(
                userId: widget.userId,
              )),
    );
  }

  Future<void> sendSeendEmail(
      String verificationCode, String email_name) async {
    if (!mounted) return; // Add this check at the start

    try {
      final smtpServer =
          gmail('mariamjaber.kar@gmail.com', 'plcg otvz trbg kgzf');

      final message = Message()
        ..from = Address('mariamjaber.kar@gmail.com', 'تطبيق مشوار')
        ..recipients.add(email_name)
        ..subject = 'إرسال رمز التحقق'
        ..text =
            'رمز التحقق الخاص بك هو: $verificationCode'; // Added verification code to the message

      await send(message, smtpServer);

      if (!mounted) return; // Add this check before showing SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تأكد من رمز التحقق')),
      );
    } catch (e) {
      if (!mounted) return; // Add this check before showing error SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في إرسال البريد: $e')),
      );
    }
  }

  void saveVehicleInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(" لا يوجد مستخدم مسجل دخول")),
      );
      return;
    }

    final String ownershipNumber = ownershipNumberController.text.trim();
    final String vehicleNumber = vehicleNumberController.text.trim();
    final String permanentLocation = permanentLocationController.text.trim();
    final String accessArea = accessAreaController.text.trim();
    final String pricePerKm = pricePerKmController.text.trim();

    // Validate all fields
    if (selectedVehicleType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: kPrimaryColor,
            content: Text(
              " يرجى اختيار نوع المركبة",
              style: TextStyle(
                color: kBackgroundColor,
              ),
            )),
      );
      return;
    }
    if (ownershipNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: kPrimaryColor,
            content: Text(
              " يرجى إدخال رقم الملكية",
              style: TextStyle(
                color: kBackgroundColor,
              ),
            )),
      );
      return;
    }
    if (vehicleNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: kPrimaryColor,
            content: Text(
              " يرجى إدخال رقم المركبة",
              style: TextStyle(
                color: kBackgroundColor,
              ),
            )),
      );
      return;
    }
    if (permanentLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: kPrimaryColor,
            content: Text(
              " يرجى إدخال الموقع الدائم",
              style: TextStyle(
                color: kBackgroundColor,
              ),
            )),
      );
      return;
    }
    if (accessArea.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: kPrimaryColor,
            content: Text(
              " يرجى إدخال منطقة الوصول",
              style: TextStyle(
                color: kBackgroundColor,
              ),
            )),
      );
      return;
    }
    if (pricePerKm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: kPrimaryColor,
            content: Text(
              " يرجى إدخال سعر الكيلو",
              style: TextStyle(
                color: kBackgroundColor,
              ),
            )),
      );
      return;
    }
    if (selectedPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: kPrimaryColor,
            content: Text(
              " يرجى اختيار ملف PDF",
              style: TextStyle(
                color: kBackgroundColor,
              ),
            )),
      );
      return;
    }
    if (_carImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: kPrimaryColor,
            content: Text(
              " يرجى اختيار صورة المركبة",
              style: TextStyle(
                color: kBackgroundColor,
              ),
            )),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // حفظ معلومات المركبة
      await FirebaseFirestore.instance
          .collection("vehicle_info")
          .doc(user.uid)
          .set({
        'vehicleType': selectedVehicleType,
        'ownershipNumber': ownershipNumber,
        'vehicleNumber': vehicleNumber,
        'permanentLocation': permanentLocation,
        'accessArea': accessArea,
        'pricePerKm': pricePerKm,
        'pdfName': selectedPdf!.name,
        'carImage': _carImageBase64,
        'userId': user.uid,
        'userEmail': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // تحديث نوع المركبة في جدول driverUsers
      await FirebaseFirestore.instance
          .collection('driverUsers')
          .doc(user.uid)
          .update({
        'vehicleType': selectedVehicleType,
      });

      // إنشاء رمز تحقق من 5 أرقام
      String verificationCode = '';
      for (int i = 0; i < 5; i++) {
        verificationCode += Random().nextInt(10).toString();
      }

      // حفظ الرمز في Firestore
      await FirebaseFirestore.instance
          .collection('verification_codes')
          .doc(widget.userId)
          .set({
        'code': verificationCode,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': false
      });
      sendSeendEmail(verificationCode, user.email!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: kPrimaryColor,
              content: Text(
                "تم إرسال رمز التحقق بنجاح",
                style: TextStyle(
                  color: kBackgroundColor,
                ),
              )),
        );
        _navigateToVerifyCode();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: kPrimaryColor,
            content: Text(
              " حدث خطأ أثناء الحفظ: ${e.toString()}",
              style: const TextStyle(
                color: kBackgroundColor,
              ),
            )),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // عنوان الصفحة
                    const Text(
                      "معلومات المركبة",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                        fontFamily: 'Tajawal',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // صورة المركبة
                    GestureDetector(
                      onTap: _isLoading ? null : _pickCarImage,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E3A8A).withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          image: _carImageFile != null
                              ? DecorationImage(
                                  image: FileImage(_carImageFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _carImageFile == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.directions_car,
                                    size: 50,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "اضغط لإضافة صورة المركبة",
                                    style: TextStyle(
                                      color: Color(0xFF1E3A8A),
                                      fontSize: 16,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // حقول الإدخال
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E3A8A).withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: selectedVehicleType,
                            items: ["توك توك", "تاكسي"]
                                .map((e) =>
                                    DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: _isLoading
                                ? null
                                : (val) {
                                    setState(() {
                                      selectedVehicleType = val;
                                    });
                                  },
                            decoration: _buildInputDecoration("نوع المركبة"),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: ownershipNumberController,
                            enabled: !_isLoading,
                            decoration: _buildInputDecoration("رقم الملكية"),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: vehicleNumberController,
                            enabled: !_isLoading,
                            decoration: _buildInputDecoration("رقم المركبة"),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: permanentLocationController,
                            enabled: !_isLoading,
                            decoration: _buildInputDecoration("الموقع الدائم"),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: accessAreaController,
                            enabled: !_isLoading,
                            decoration: _buildInputDecoration("منطقة الوصول"),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: pricePerKmController,
                            enabled: !_isLoading,
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration("سعر الكيلو"),
                          ),
                          const SizedBox(height: 15),
                          GestureDetector(
                            onTap: _isLoading ? null : _pickPdf,
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFF1E3A8A)
                                        .withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.upload_file,
                                      color: Color(0xFF1E3A8A)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      selectedPdf?.name ??
                                          "اختر ملف الرخصة (PDF)",
                                      style: TextStyle(
                                        color: selectedPdf != null
                                            ? Color(0xFF1E3A8A)
                                            : Colors.grey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // أزرار التحكم
                    const SizedBox(width: 15),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : saveVehicleInfo,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: const Color(0xFF1E3A8A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "حفظ المعلومات",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
            ],
          ),
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
