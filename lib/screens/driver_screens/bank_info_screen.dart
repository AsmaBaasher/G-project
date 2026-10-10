import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'driver_orders_screen.dart';

class BankInfoScreen extends StatefulWidget {
  @override
  _BankInfoScreenState createState() => _BankInfoScreenState();
}

class _BankInfoScreenState extends State<BankInfoScreen> {
  // Modern navy color palette
  static const Color kPrimaryColor = Color(0xFF1E3A8A);    // Deep navy
  static const Color kSecondaryColor = Color(0xFF334155);  // Slate navy
  static const Color kBackgroundColor = Color(0xFFF1F5F9); // Cool gray
  static const Color kTextColor = Color(0xFF0F172A);       // Dark navy

  String? _selectedBank;
  final _accountNumberController = TextEditingController();
  bool _isLoading = false;

  final List<String> _banks = [
    'العمقي',
    'الكريمي',
    'القطيبي',
    'البسيري',
    'بن دول'
  ];

  @override
  void dispose() {
    _accountNumberController.dispose();
    super.dispose();
  }

  bool get _isFormValid => _selectedBank != null && _accountNumberController.text.isNotEmpty;

  Future<void> _saveBankInfo() async {
    if (!_isFormValid) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // حفظ الحساب البنكي في مجموعة bank_accounts
        await FirebaseFirestore.instance
            .collection('bank_accounts')
            .add({
              'driverId': user.uid,
              'bankName': _selectedBank,
              'accountNumber': _accountNumberController.text,
              'createdAt': FieldValue.serverTimestamp(),
              'isActive': true,
            });

        // تحديث حالة hasBankInfo في جدول driverUsers
        await FirebaseFirestore.instance
            .collection('driverUsers')
            .doc(user.uid)
            .update({
              'hasBankInfo': true,
            });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DriverScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ في حفظ المعلومات: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _skipToDriverScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DriverScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'المعلومات البنكية',
            style: TextStyle(
              color: kTextColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward, color: kTextColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'أدخل معلومات حسابك البنكي',
                  style: TextStyle(
                    fontSize: 18,
                    color: kTextColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'هذه المعلومات ضرورية لتلقي المدفوعات',
                  style: TextStyle(
                    fontSize: 14,
                    color: kSecondaryColor,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBank,
                      hint: const Text(
                        'اختر البنك',
                        style: TextStyle(
                          color: kSecondaryColor,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: kPrimaryColor),
                      items: _banks.map((String bank) {
                        return DropdownMenuItem<String>(
                          value: bank,
                          child: Text(
                            bank,
                            style: const TextStyle(
                              color: kTextColor,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() => _selectedBank = newValue);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                  ),
                  child: TextField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'رقم الحساب',
                      hintStyle: TextStyle(
                        color: kSecondaryColor,
                        fontFamily: 'Tajawal',
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 32),
                if (_isFormValid)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveBankInfo,
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
                            'موافق',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _skipToDriverScreen,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'تخطي',
                    style: TextStyle(
                      fontSize: 16,
                      color: kSecondaryColor,
                      fontFamily: 'Tajawal',
                    ),
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