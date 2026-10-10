import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:g_project/chats/select_user_page.dart';
import 'dart:convert';
import 'driver_orders_screen.dart';
import 'driver_settings/bank_screen.dart';
import 'driver_settings/settings_screen.dart';
import 'bank_info_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  @override
  _PersonalInfoScreenState createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> 
    with SingleTickerProviderStateMixin {
  // Modern navy color palette
  static const Color kPrimaryColor = Color(0xFF1E3A8A);    // Deep navy
  static const Color kSecondaryColor = Color(0xFF334155);  // Slate navy
  static const Color kBackgroundColor = Color(0xFFF1F5F9); // Cool gray
  static const Color kTextColor = Color(0xFF0F172A);       // Dark navy
  // ignore: unused_field
  static const Color kSuccessColor = Color(0xFF0D9488);    // Teal
  // ignore: unused_field
  static const Color kWarningColor = Color(0xFF0369A1);    // Light navy

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // ignore: unused_field
  bool _isLoading = true;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? vehicleData;
  Map<String, dynamic>? driverStats;
    int _selectedIndex = 1; // Start with home selected

  // Add bank accounts list
  List<Map<String, dynamic>> bankAccounts = [];

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

    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load user data
        final userDoc = await FirebaseFirestore.instance
            .collection('driverUsers')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists && userDoc.data() != null) {
          setState(() {
            userData = userDoc.data();
          });
        }

        // Load vehicle data
        final vehicleDoc = await FirebaseFirestore.instance
            .collection('vehicle_info')
            .doc(user.uid)
            .get();
        
        if (vehicleDoc.exists && vehicleDoc.data() != null) {
          setState(() {
            vehicleData = vehicleDoc.data();
          });
        }

        // Load bank accounts
        final bankAccountsSnapshot = await FirebaseFirestore.instance
            .collection('bank_accounts')
            .where('driverId', isEqualTo: user.uid)
            .get();

        setState(() {
          bankAccounts = bankAccountsSnapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();

              print(bankAccounts);
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      _buildDriverHeader(),
                      _buildDriverStats(),
                      _buildPersonalInfoSection(),
                      _buildVehicleInfoSection(),
                      _buildBankAccountsSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.directions_car),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble),
                label: '',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: kPrimaryColor,
            unselectedItemColor: kSecondaryColor,
            backgroundColor: Colors.white,
            elevation: 0,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      
        
      ),
    );
  }

 void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SelectUserPage(currentUserId: currentUser!.uid),),
            );
          }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: kPrimaryColor,
      iconTheme: const IconThemeData(
        color: kBackgroundColor,
      ),
      centerTitle: true,
      title: const Text(
        'المعلومات الشخصية',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          fontFamily: 'Tajawal',
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingsScreen()),
          ),
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

  Widget _buildDriverHeader() {
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
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kPrimaryColor.withOpacity(0.2),
                  kPrimaryColor.withOpacity(0.6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: userData?['profileImage'] != null
              ? ClipOval(
                  child: Image.memory(
                    base64Decode(userData!['profileImage']),
                    fit: BoxFit.cover,
                  ),
                )
              : ClipOval(
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
          ),
          const SizedBox(height: 16),
          Text(
            userData?['name'] ?? 'مستخدم',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kTextColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userData?['email'] ?? 'البريد الإلكتروني',
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

  Widget _buildDriverStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('عدد الرحلات', userData?['tripCount']?.toString() ?? '0', Icons.directions_car_filled),
          _buildStatDivider(),
          _buildStatItem('سعر الكيلو متر', vehicleData?['pricePerKm']?.toString() ?? '0', Icons.space_dashboard_outlined),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: kPrimaryColor.withOpacity(0.1),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Flexible(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: kPrimaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kTextColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: kSecondaryColor,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
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
          const Row(
            children: [
              Icon(Icons.person_outline, color: kPrimaryColor, size: 24),
              SizedBox(width: 8),
              Text(
                'المعلومات الشخصية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kTextColor,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('الاسم الكامل', userData?['name'] ?? 'غير متوفر', Icons.person),
          _buildInfoRow('رقم الهاتف', userData?['phone'] ?? 'غير متوفر', Icons.phone),
          _buildInfoRow('البريد الإلكتروني', userData?['email'] ?? 'غير متوفر', Icons.email),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoSection() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_car, color: kPrimaryColor, size: 24),
              SizedBox(width: 8),
              Text(
                'معلومات المركبة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kTextColor,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildVehicleInfoRow('نوع المركبة', vehicleData?['vehicleType'] ?? 'غير متوفر', Icons.directions_car),
          _buildVehicleInfoRow('المكان الدائم ', vehicleData?['permanentLocation'] ?? 'غير متوفر', Icons.location_on),
          _buildVehicleInfoRow('آخر نقطة', vehicleData?['accessArea'] ?? 'غير متوفر', Icons.location_off),
          // _buildVehicleInfoRow('لون المركبة', vehicleData?['color'] ?? 'غير متوفر', Icons.color_lens),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: kPrimaryColor),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: kSecondaryColor,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: kPrimaryColor),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: kSecondaryColor,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kTextColor,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
     Widget _buildDriverInfo() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person, color: kPrimaryColor, size: 24),
               SizedBox(width: 8),
              Text(
                'المعلومات الشخصية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kTextColor,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildVehicleInfoRow('الاسم',userData?['name'] ?? 'مستخدم', Icons.person),
          _buildVehicleInfoRow('رفم الهاتف ', userData?['phone'] ?? 'لايوجد', Icons.confirmation_number),
          _buildVehicleInfoRow('الإيميل', userData?['email'] ?? 'لا يوجد', Icons.color_lens),
        ],
      ),
    );
  }

    Widget _buildVehicleInfo() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_car, color: kPrimaryColor, size: 24),
               SizedBox(width: 8),
              Text(
                'معلومات المركبة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kTextColor,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildVehicleInfoRow('نوع المركبة',"ghk", Icons.car_rental),
          _buildVehicleInfoRow('المكان الدائم', 'ABC 123', Icons.confirmation_number),
          _buildVehicleInfoRow('آخر نقطة', ' أصفر', Icons.color_lens),
        ],
      ),
    );
  }

  Widget _buildBankAccountsSection() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance, color: kPrimaryColor, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'الحسابات البنكية',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kTextColor,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
              Text(
                'عدد الحسابات: ${bankAccounts.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: kSecondaryColor,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (bankAccounts.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 48,
                    color: kSecondaryColor,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'لا توجد حسابات بنكية مضافة',
                    style: TextStyle(
                      fontSize: 14,
                      color: kSecondaryColor,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BankScreen()),
                      ).then((_) => _loadUserData());
                    },
                    icon: const Icon(Icons.add_circle_outline, color: kPrimaryColor),
                    label: const Text(
                      'إضافة حساب بنكي',
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                ...bankAccounts.map((account) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.account_balance_wallet, 
                              size: 20, 
                              color: kPrimaryColor
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account['bankName'] ?? 'غير معروف',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: kTextColor,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'رقم الحساب: ${account['accountNumber'] ?? 'غير معروف'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: kSecondaryColor,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                               
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )).toList(),
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BankInfoScreen()),
                      ).then((_) => _loadUserData());
                    },
                    icon: const Icon(Icons.add_circle_outline, color: kPrimaryColor),
                    label: const Text(
                      'إضافة حساب بنكي',
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
   
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'غير معروف';
    
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.year}/${date.month}/${date.day}';
    } catch (e) {
      return 'غير معروف';
    }
  }
}