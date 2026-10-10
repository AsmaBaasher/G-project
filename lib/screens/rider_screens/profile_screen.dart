import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:g_project/screens/choice_screen.dart';
import '../../models/user_model.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> 
    with SingleTickerProviderStateMixin {
  // Modern navy color palette
  static const Color kPrimaryColor = Color(0xFF1E3A8A);    // Deep navy
  static const Color kSecondaryColor = Color(0xFF334155);  // Slate navy
  static const Color kBackgroundColor = Color(0xFFF1F5F9); // Cool gray
  static const Color kTextColor = Color(0xFF0F172A);       // Dark navy
  static const Color kDangerColor = Color(0xFF1E3A8A);     // Bright red

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = UserModel.currentUser;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildAppBar(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      _buildProfileHeader(user),
                      _buildProfileDetails(user),
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
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: kPrimaryColor,
      
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: const Text(
        'الملف الشخصي',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: kBackgroundColor,
          fontFamily: 'Tajawal',
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_forward, color: kBackgroundColor),
          onPressed: () => Navigator.pop(context),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel? user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimaryColor.withOpacity(0.2),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const ClipOval(
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'مستخدم',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kTextColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? 'البريد الإلكتروني',
            style: const TextStyle(
              fontSize: 16,
              color: kSecondaryColor,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails(UserModel? user) {
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
          _buildProfileDetailItem(
            Icons.person_outline,
            'الاسم الكامل',
            user?.name ?? 'غير محدد',
          ),
          Divider(
            height: 24,
            thickness: 1,
            color: kPrimaryColor.withOpacity(0.1),
          ),
          _buildProfileDetailItem(
            Icons.phone_outlined,
            'رقم الهاتف',
            user?.phone ?? 'غير محدد',
          ),
          Divider(
            height: 24,
            thickness: 1,
            color: kPrimaryColor.withOpacity(0.1),
          ),
          _buildProfileDetailItem(
            Icons.email_outlined,
            'البريد الإلكتروني',
            user?.email ?? 'غير محدد',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
            Icons.settings_outlined,
            'الإعدادات',
            'إعدادات الحساب والتطبيق',
          ),
          Divider(
            height: 24,
            thickness: 1,
            color: kPrimaryColor.withOpacity(0.1),
          ),
          _buildSettingsItem(
            Icons.help_outline,
            'المساعدة والدعم',
            'الأسئلة الشائعة وخدمة العملاء',
          ),
          Divider(
            height: 24,
            thickness: 1,
            color: kPrimaryColor.withOpacity(0.1),
          ),
          // _buildSettingsItem(
          //   Icons.payment_outlined,
          //   'طرق الدفع',
          //   'إدارة طرق الدفع المفضلة',
          // ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailItem(IconData icon, String title, String value) {
    return Row(
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
                style: const TextStyle(
                  fontSize: 14,
                  color: kSecondaryColor,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style:const  TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String subtitle) {
    return InkWell(
      onTap: () {
        if (title == 'الإعدادات') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
          ).then((_) {
            setState(() {});
          });
        } else if (title == 'المساعدة والدعم') {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text(
                  'قيد التطوير',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                content: const Text(
                  'هذه الميزة قيد التطوير حالياً',
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
      },
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kTextColor,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: kSecondaryColor,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
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
            await FirebaseAuth.instance.signOut();
            UserModel.currentUser = null;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) =>  ChoiceScreen()),
              (Route<dynamic> route) => false,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: kDangerColor.withOpacity(0.1),
              border: Border.all(color: kDangerColor.withOpacity(0.3)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Icon(Icons.logout, color: kDangerColor),
                 SizedBox(width: 8),
                Text(
                  'تسجيل الخروج',
                  style:  TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kDangerColor,
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