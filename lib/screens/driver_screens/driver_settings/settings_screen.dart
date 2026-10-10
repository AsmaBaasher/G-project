import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:g_project/chats/select_user_page.dart';
import 'package:g_project/screens/choice_screen.dart';
import 'package:g_project/screens/driver_screens/driver_settings/car_info_screen.dart';
import '../../../chats/chat_screen.dart';
import '../../rider_screens/rate_driver_screen.dart';
import '../driver_orders_screen.dart';
import '../login_register/login_screen.dart';
import '../chat_screen.dart';
import '../payment_pdf.dart';

import 'bank_screen.dart';
import 'personal_screen.dart';
import '../personal_info_screen.dart';


class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  // Modern navy color palette
  static const Color kPrimaryColor = Color(0xFF1E3A8A);    // Deep navy
  static const Color kSecondaryColor = Color(0xFF334155);  // Slate navy
  static const Color kBackgroundColor = Color(0xFFF1F5F9); // Cool gray
  static const Color kTextColor = Color(0xFF0F172A);       // Dark navy
  static const Color kDangerColor = Color(0xFFDC2626);     // Changed to red color

  bool _isWorkTimeActive = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1, curve: Curves.easeOutBack),
      ),
    );

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });

    _loadUserSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('driverUsers')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          setState(() {
            _isWorkTimeActive = doc.data()?['isAvailable'] ?? false;
          });
        }
      }
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleWorkTime(bool value) async {
    setState(() {
      _isWorkTimeActive = value;
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('driverUsers')
            .doc(user.uid)
            .set({
          'isAvailable': value,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Rollback on error
      setState(() {
        _isWorkTimeActive = !value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحديث الإعدادات')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: _buildAppBar(),
        body: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: kPrimaryColor))
                    : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      _buildWorkTimeSection(),
                      _buildSettingsSection(),
                      _buildLogoutButton(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: kPrimaryColor,
      automaticallyImplyLeading: true,
      iconTheme: IconThemeData(
          color: kBackgroundColor
      ),
      centerTitle: true,
      title: const Text(
        'الإعدادات',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontFamily: 'Tajawal',
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _buildWorkTimeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حالة السائق',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextColor,
              fontFamily: 'Tajawal',
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isWorkTimeActive ? 'حالة السائق: متاح' : 'حالة السائق: غير متاح',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isWorkTimeActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'عند تفعيل حالة السائق يمكن للآخرين معرفة موقعك الحالي',
                      style: TextStyle(
                        fontSize: 14,
                        color: kSecondaryColor,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isWorkTimeActive,
                onChanged: _toggleWorkTime,
                activeColor: kPrimaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            Icons.person_outline,
            'المعلومات الشخصية',
            'تعديل البيانات الشخصية',
            onTap: () => _navigateToPersonalInfo(context),
          ),
          Divider(
            height: 24,
            thickness: 1,
            color: kPrimaryColor.withOpacity(0.1),
          ),
          _buildSettingsItem(
            Icons.car_rental,
            'معلومات المركبة',
            'تعديل بيانات المركبة',
            onTap: () => _navigateToCarInfo(context),
          ),
          Divider(
            height: 24,
            thickness: 1,
            color: kPrimaryColor.withOpacity(0.1),
          ),
          _buildSettingsItem(
            Icons.account_balance_outlined,
            'المعلومات البنكية',
            'تعديل بيانات الحساب البنكي',
            onTap: () {
              _navigateToBankInfo(context);
            },
          ),
          Divider(
            height: 24,
            thickness: 1,
            color: kPrimaryColor.withOpacity(0.1),
          ),
          _buildSettingsItem(
            Icons.receipt,
            'الرسوم المسددة',
            'عرض كشف الرسوم المسددة',
            onTap: () => _navigateToPaymentPDF(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: kPrimaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kTextColor,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: kSecondaryColor,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: kSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          onTap: () async {
            try {
              await FirebaseAuth.instance.signOut();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChoiceScreen()),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('حدث خطأ أثناء تسجيل الخروج')),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: kPrimaryColor.withOpacity(0.1),
              border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: kPrimaryColor),
                SizedBox(width: 8),
                Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryColor,
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

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'المعلومات الشخصية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'الطلبات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'المحادثات',
          ),
        ],
        currentIndex: 1,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.transparent,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => PersonalInfoScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DriverScreen()),
            );
          } else if (index == 2) {
              final currentUser = FirebaseAuth.instance.currentUser;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SelectUserPage(currentUserId: currentUser!.uid)),
            );
          }
        },
      ),
    );
  }

  void _navigateToPersonalInfo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PersonalScreen()),
    );
  }
   void _navigateToCarInfo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CarInfoScreen()),
    );
  }
   void _navigateToBankInfo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BankScreen()),
    );
  }

  void _navigateToPaymentPDF(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentPDFScreen()),
    );
  }
}