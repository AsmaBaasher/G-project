import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'home_screen.dart';
import 'dart:typed_data';
import 'rate_driver_screen.dart';

// Modern navy color palette
const Color kPrimaryColor = Color(0xFF1E3A8A);    // Deep navy
const Color kSecondaryColor = Color(0xFF334155);  // Slate navy
const Color kBackgroundColor = Color(0xFFF1F5F9); // Cool gray
const Color kTextColor = Color(0xFF0F172A);       // Dark navy
const Color kAccentColor = Color(0xFF3B82F6);     // Bright blue
const Color kSuccessColor = Color(0xFF22C55E);    // Green for success messages

class PayScreen extends StatefulWidget {
  final String riderId;
  final String driverId;
  final bool isBankPayment;
  final double distance;

  const PayScreen({
    Key? key,
    required this.riderId,
    required this.driverId,
    required this.isBankPayment,
    required this.distance,
  }) : super(key: key);

  @override
  _PayScreenState createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  File? _image;
  File? _pdf;
  final picker = ImagePicker();

  // 📷 التقاط صورة بالكاميرا
  Future<void> _pickImage() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      setState(() {
        if (pickedFile != null) {
          _image = File(pickedFile.path);
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text(
                  'تنبيه',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                content: const Text(
                  'فشل في التقاط الصورة. حاول مرة أخرى.',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                  ),
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'حسناً',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
      });
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'تنبيه',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: const Text(
              'فشل في التقاط الصورة. حاول مرة أخرى.',
              style: TextStyle(
                fontFamily: 'Tajawal',
              ),
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'حسناً',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: kPrimaryColor,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  // 📄 اختيار PDF من الجهاز
  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _pdf = File(result.files.single.path!);
      });
    }
  }

  // 📦 ضغط وتحويل الصورة إلى Base64
  Future<String?> compressAndConvertImageToBase64(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      Uint8List imageBytesUint8List = Uint8List.fromList(imageBytes);
      img.Image? originalImage = img.decodeImage(imageBytesUint8List);
      if (originalImage == null) return null;

      // تغيير الأبعاد
      img.Image resizedImage = img.copyResize(originalImage, width: 800);

      // ضغط الصورة بنسبة جودة 70%
      List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 70);

      // تحويل إلى Base64
      String base64Image = base64Encode(compressedBytes);
      return base64Image;
    } catch (e) {
      print('خطأ في ضغط الصورة: $e');
      return null;
    }
  }

  // 📤 رفع البيانات إلى Firestore
  Future<void> _uploadPaymentData() async {
    try {
      // التحقق من صحة معرف السائق
      if (widget.driverId.isEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'خطأ',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: const Text(
                'معرف السائق غير صالح. يرجى المحاولة مرة أخرى.',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                ),
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(riderId: widget.riderId),
                      ),
                    );
                  },
                  child: const Text(
                    'حسناً',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: kPrimaryColor,
                    ),
                  ),
                ),
              ],
            );
          },
        );
        return;
      }

      String? imageBase64;
      if (_image != null) {
        imageBase64 = await compressAndConvertImageToBase64(_image!);
      }

      String? pdfBase64;
      if (_pdf != null) {
        List<int> pdfBytes = await _pdf!.readAsBytes();
        pdfBase64 = base64Encode(pdfBytes);
      }

      // التحقق من وجود إثبات الدفع
      if (imageBase64 == null && pdfBase64 == null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'تنبيه',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: const Text(
                'يرجى إرفاق إثبات الدفع (صورة أو سند) قبل المتابعة.',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                ),
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'حسناً',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: kPrimaryColor,
                    ),
                  ),
                ),
              ],
            );
          },
        );
        return;
      }

      await FirebaseFirestore.instance.collection('payments').add({
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'dateString': DateTime.now().toString(),
        'driverId': widget.driverId,
        'riderId': widget.riderId,
        'paymentType': widget.isBankPayment ? 'bank' : 'cash',
        'status': 'pending',
        'imageBase64': imageBase64,
        'pdfBase64': pdfBase64,
      });

      // Fetch driver data before navigation
      final driverDoc = await FirebaseFirestore.instance
          .collection('driverUsers')
          .doc(widget.driverId)
          .get();

      if (driverDoc.exists && driverDoc.data() != null) {
        final driverData = driverDoc.data()!;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RateDriverScreen(
              driverId: widget.driverId,
              driverName: driverData['name'] ?? 'سائق',
              driverImage: driverData['profileImage'] ?? '',
              distance: widget.distance,
            ),
          ),
        );
      } else {
        // If driver data not found, show error dialog and navigate to home
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'تنبيه',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: const Text(
                'حدث خطأ في جلب بيانات السائق',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                ),
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(riderId: widget.riderId),
                      ),
                    );
                  },
                  child: const Text(
                    'حسناً',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: kPrimaryColor,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('فشل في رفع البيانات: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'تنبيه',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: const Text(
              'فشل في رفع البيانات. يرجى التأكد من اتصال الإنترنت والمحاولة مرة أخرى.',
              style: TextStyle(
                fontFamily: 'Tajawal',
              ),
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'حسناً',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: kPrimaryColor,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackgroundColor, // Set background color
        appBar: AppBar(
          backgroundColor: Colors.white, // AppBar background color
          elevation: 0, // No shadow
          title: const Text(
            'التسديد',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kTextColor, // Title color
              fontFamily: 'Tajawal',
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward, color: kTextColor), // Back arrow color
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'إثبات الدفع البنكي',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor, // Use primary color for title
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'يرجى اختيار نوع إثبات الدفع',
                        style: TextStyle(
                          fontSize: 16,
                          color: kSecondaryColor, // Use secondary color for subtitle
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildOptionCard(
                            icon: Icons.camera_alt,
                            label: 'التقاط صورة',
                            onTap: _pickImage,
                          ),
                          _buildOptionCard(
                            icon: Icons.file_copy,
                            label: 'إرفاق سند',
                            onTap: _pickPDF,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_image != null || _pdf != null) // Show selected file indicator
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Text(
                            _image != null
                                ? 'تم اختيار صورة.'
                                : 'تم اختيار ملف PDF.',
                            style: TextStyle(
                              color: kSuccessColor, // Assuming kSuccessColor exists or define one
                              fontSize: 16,
                              fontFamily: 'Tajawal',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0), // Apply specific padding
                child: ElevatedButton(
                  onPressed: (_image != null || _pdf != null) ? _uploadPaymentData : null, // Enable button only when a file is selected
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor, // Button background color
                    minimumSize: const Size(double.infinity, 55), // Full width button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Rounded corners
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'تأكيد وإرسال', // Button text
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Button text color
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build the option cards
  Widget _buildOptionCard({required IconData icon, required String label, required VoidCallback onTap}) {
    return Expanded(
      child: Card(
        elevation: 2, // Card shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: kPrimaryColor, // Icon color
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kTextColor, // Text color
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
