import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class CarInfoScreen extends StatefulWidget {
  @override
  _CarInfoScreenState createState() => _CarInfoScreenState();
}

class _CarInfoScreenState extends State<CarInfoScreen> {
  static const Color kPrimaryColor = Color(0xFF1E3A8A);
  static const Color kSecondaryColor = Color(0xFF334155);
  static const Color kBackgroundColor = Color(0xFFF1F5F9);
  static const Color kTextColor = Color(0xFF0F172A);

  String? _selectedVehicleType;
  final TextEditingController permanentLocationController = TextEditingController();
  final TextEditingController accessAreaController = TextEditingController();
  final TextEditingController pricePerKmController = TextEditingController();
  bool _isLoading = false;
  File? _vehicleImage;
  String? _vehicleImageBase64;
  final ImagePicker _picker = ImagePicker();

  final List<String> _vehicleTypes = [
    'تاكسي',
    'توك توك',
  ];

  @override
  void initState() {
    super.initState();
    _loadVehicleInfo();
  }

  @override
  void dispose() {
    permanentLocationController.dispose();
    accessAreaController.dispose();
    pricePerKmController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (image != null) {
        try {
          final bytes = await image.readAsBytes();
          if (bytes.isEmpty) {
            throw Exception('الصورة فارغة');
          }
          
          // التحقق من حجم الصورة (أقل من 1MB)
          if (bytes.length > 1024 * 1024) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('حجم الصورة كبير جداً. يرجى اختيار صورة أصغر')),
            );
            return;
          }

          final base64String = base64Encode(bytes);
          
          setState(() {
            _vehicleImage = File(image.path);
            _vehicleImageBase64 = base64String;
          });
        } catch (e) {
          print('Error processing image: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('حدث خطأ في معالجة الصورة')),
          );
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ في اختيار الصورة')),
      );
    }
  }

  Future<void> _loadVehicleInfo() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('vehicle_info')
            .doc(user.uid)
            .get();
        
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          setState(() {
            _selectedVehicleType = data['vehicleType'] ?? '';
            permanentLocationController.text = data['permanentLocation'] ?? '';
            accessAreaController.text = data['accessArea'] ?? '';
            pricePerKmController.text = data['pricePerKm']?.toString() ?? '';
            
            // تحميل الصورة بشكل آمن
            try {
              final base64Image = data['carImage'];
              if (base64Image != null && base64Image.isNotEmpty) {
                _vehicleImageBase64 = base64Image;
                final bytes = base64Decode(base64Image);
                if (bytes.isNotEmpty) {
                  _vehicleImage = File.fromRawPath(bytes);
                }
              }
            } catch (e) {
              print('Error loading image: $e');
              _vehicleImageBase64 = null;
              _vehicleImage = null;
            }
          });
        }
      }
    } catch (e) {
      print('Error loading vehicle info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في تحميل معلومات المركبة: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveVehicleInfo() async {
    if (_selectedVehicleType == null ||
        permanentLocationController.text.isEmpty ||
        accessAreaController.text.isEmpty ||
        pricePerKmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('vehicle_info')
            .doc(user.uid)
            .set({
          'vehicleType': _selectedVehicleType,
          'permanentLocation': permanentLocationController.text.trim(),
          'accessArea': accessAreaController.text.trim(),
          'pricePerKm': double.tryParse(pricePerKmController.text) ?? 0.0,
          'carImage': _vehicleImageBase64,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await FirebaseFirestore.instance
            .collection('driverUsers')
            .doc(user.uid)
            .update({
          'vehicleType': _selectedVehicleType,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ معلومات المركبة بنجاح')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Error saving vehicle info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في حفظ معلومات المركبة: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImageSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'صورة المركبة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kTextColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_vehicleImage != null)
                    Image.file(
                      _vehicleImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error displaying image: $error');
                        return Container(
                          color: kBackgroundColor,
                          child: const Center(
                            child: Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: kBackgroundColor,
                      child: const Center(
                        child: Icon(
                          Icons.directions_car,
                          size: 64,
                          color: kSecondaryColor,
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'معلومات المركبة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
              color: Colors.white,
            ),
          ),
          backgroundColor: kPrimaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'أدخل معلومات مركبتك',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'هذه المعلومات ضرورية لتحديد نوع الخدمة التي يمكنك تقديمها',
                      style: TextStyle(
                        fontSize: 14,
                        color: kSecondaryColor,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildImageSection(),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedVehicleType,
                          hint: const Text(
                            'اختر نوع المركبة',
                            style: TextStyle(
                              color: kSecondaryColor,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: kPrimaryColor),
                          items: _vehicleTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(
                                type,
                                style: const TextStyle(
                                  color: kTextColor,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() => _selectedVehicleType = newValue);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: permanentLocationController,
                      label: 'المكان الدائم',
                      hint: 'أدخل المكان الدائم للمركبة',
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: accessAreaController,
                      label: 'آخر نقطة',
                      hint: 'أدخل آخر نقطة يمكن الوصول إليها',
                      icon: Icons.location_off,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: pricePerKmController,
                      label: 'سعر الكيلو متر',
                      hint: 'أدخل السعر بالريال',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveVehicleInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
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
                              'حفظ المعلومات',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
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
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: kSecondaryColor, fontFamily: 'Tajawal'),
          hintStyle: TextStyle(color: kSecondaryColor.withOpacity(0.5), fontFamily: 'Tajawal'),
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
}
