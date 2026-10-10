import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ignore: unused_import
import 'rate_driver_screen.dart';
import 'pay_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  final String driverId;
  final String? orderId;
  final String? driverName;
  final double distance;

  const DriverProfileScreen({
    Key? key,
    required this.driverId,
    this.orderId,
    this.driverName,
    required this.distance,
  }) : super(key: key);

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen>
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
 
  String _selectedPaymentMethod = 'cash';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // إضافة متغيرات لتخزين بيانات السائق
  Map<String, dynamic> driverData = {};
   bool _isLoading = true;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? vehicleData;
  Map<String, dynamic>? driverStats;
    List<Map<String, dynamic>> bankAccounts = [];

  
  // Add variables for order data and calculated fare
  Map<String, dynamic>? orderData;
  double _calculatedFare = 0.0; // Variable to store the calculated fare

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
    
    // استدعاء دالة جلب بيانات السائق
    _loadUserData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

 
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      
      elevation: 0,
      backgroundColor: kPrimaryColor,
      
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: const Text(
        'ملف السائق',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: kBackgroundColor,
          fontFamily: 'Tajawal',
        ),
      ),
      actions: [
        IconButton(
          icon:const Icon(Icons.arrow_forward, color: kBackgroundColor),
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

  // Future<void> _fetchDriverData() async {
  //   try {
  //     final DocumentSnapshot driverDoc = await FirebaseFirestore.instance
  //         .collection('driverUsers')
  //         .doc(widget.driverId)
  //         .get();

  //     if (driverDoc.exists) {
  //       setState(() {
  //         driverData = driverDoc.data() as Map<String, dynamic>;
  //         isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       isLoading = false;
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('حدث خطأ في جلب بيانات السائق')),
  //     );
  //   }
  // }

 Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Starting to load user data for driverId: ${widget.driverId}');
        
        // Load user data
        final userDoc = await FirebaseFirestore.instance
            .collection('driverUsers')
            .doc(widget.driverId)
            .get();
        
        if (userDoc.exists && userDoc.data() != null) {
          setState(() {
            userData = userDoc.data();
          });
          print('User data loaded successfully: ${userData.toString()}');
        } else {
          print('No user data found for driverId: ${widget.driverId}');
        }

        // Load vehicle data
        final vehicleDoc = await FirebaseFirestore.instance
            .collection('vehicle_info')
            .doc(widget.driverId)
            .get();
        
        if (vehicleDoc.exists && vehicleDoc.data() != null) {
          setState(() {
            vehicleData = vehicleDoc.data();
            // Calculate fare after loading vehicle data and getting distance from widget
            double pricePerKm = 0.0;
            if (vehicleData!['pricePerKm'] != null) {
              if (vehicleData!['pricePerKm'] is String) {
                pricePerKm = double.parse(vehicleData!['pricePerKm']);
              } else if (vehicleData!['pricePerKm'] is num) {
                pricePerKm = (vehicleData!['pricePerKm'] as num).toDouble();
              }
            }
            _calculatedFare = widget.distance * pricePerKm;
          });
          print('Vehicle data loaded successfully: ${vehicleData.toString()}');
        } else {
          print('No vehicle data found for driverId: ${widget.driverId}');
        }

        // Load bank accounts data with more detailed logging
        print('Attempting to fetch bank accounts for driverId: ${widget.driverId}');
        try {
          final bankAccountsSnapshot = await FirebaseFirestore.instance
              .collection('bank_accounts')
              .where('driverId', isEqualTo: widget.driverId)
              .where('isActive', isEqualTo: true)  // Add this condition if you want only active accounts
              .get();

          print('Bank accounts query completed. Number of accounts found: ${bankAccountsSnapshot.docs.length}');
          
          // Log each document's data
          bankAccountsSnapshot.docs.forEach((doc) {
            print('Bank account document ID: ${doc.id}');
            print('Bank account data: ${doc.data()}');
          });

          if (mounted) {
            setState(() {
              bankAccounts = bankAccountsSnapshot.docs
                  .map((doc) => {
                        'id': doc.id,
                        ...doc.data(),
                      })
                  .toList();
            });
            print('Bank accounts state updated. Current accounts: ${bankAccounts.toString()}');
          }
        } catch (e) {
          print('Error fetching bank accounts: $e');
        }

        // Load order data if orderId is provided
        if (widget.orderId != null && widget.orderId!.isNotEmpty) {
          print('Loading order data for orderId: ${widget.orderId}');
          final orderDoc = await FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.orderId)
              .get();
          
          if (orderDoc.exists && orderDoc.data() != null) {
            if (mounted) {
              setState(() {
                orderData = orderDoc.data();
              });
              print('Order data loaded successfully: ${orderData.toString()}');
            }
          } else {
            print('No order data found for orderId: ${widget.orderId}');
          }
        }
      } else {
        print('No current user found');
      }
    } catch (e) {
      print('Error in _loadUserData: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('Finished loading user data. Loading state set to false');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      print(driverData["id"]);
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                      _buildDriverHeader(),
                       _buildDriverStats(),
                        _buildVehicleInfoSection(),
                         _buildBankAccountsSection(),
                      _buildFareDetails(),
                      _buildPaymentOptions(),
                      _buildBookButton(),
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

 Widget _buildDriverHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        image: vehicleData?['carImage'] != null
            ? DecorationImage(
                image: MemoryImage(base64Decode(vehicleData!['carImage'])),
                fit: BoxFit.cover,
                opacity: 0.1,
              )
            : null,
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
           'سائق',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${bankAccounts.length} حساب',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryColor,
                    fontFamily: 'Tajawal',
                  ),
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
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 40,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد حسابات بنكية مضافة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kSecondaryColor,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'يمكنك التواصل مع السائق للحصول على معلومات الدفع',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: kSecondaryColor,
                      fontFamily: 'Tajawal',
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              size: 24,
                              color: kPrimaryColor,
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: kTextColor,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'رقم الحساب: ${account['accountNumber'] ?? 'غير معروف'}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: kSecondaryColor,
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 20),
                                      onPressed: () {
                                        if (account['accountNumber'] != null) {
                                          Clipboard.setData(
                                            ClipboardData(text: account['accountNumber']),
                                          ).then((_) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'تم نسخ رقم الحساب بنجاح',
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                    fontFamily: 'Tajawal',
                                                  ),
                                                ),
                                                backgroundColor: kPrimaryColor,
                                                duration: Duration(seconds: 2),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          });
                                        }
                                      },
                                      color: kPrimaryColor,
                                      tooltip: 'نسخ رقم الحساب',
                                    ),
                                  ],
                                ),
                                if (account['accountHolderName'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'اسم صاحب الحساب: ${account['accountHolderName']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: kSecondaryColor,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (account['iban'] != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.credit_card,
                                size: 20,
                                color: kPrimaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'IBAN: ${account['iban']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Tajawal',
                                    color: kTextColor,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20),
                                onPressed: () {
                                  if (account['iban'] != null) {
                                    Clipboard.setData(
                                      ClipboardData(text: account['iban']),
                                    ).then((_) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'تم نسخ رقم IBAN بنجاح',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              fontFamily: 'Tajawal',
                                            ),
                                          ),
                                          backgroundColor: kPrimaryColor,
                                          duration: Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    });
                                  }
                                },
                                color: kPrimaryColor,
                                tooltip: 'نسخ رقم IBAN',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                )).toList(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions() {
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
         const  Row(
            children: [
              Icon(Icons.payment, color: kPrimaryColor, size: 24),
               SizedBox(width: 8),
              Text(
                'طريقة الدفع',
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
          _buildModernPaymentOption(
            'cash',
            'الدفع نقداً',
            Icons.money,
            'ادفع عند الوصول',
          ),
          const SizedBox(height: 12),
          _buildModernPaymentOption(
            'bank',
            'تحويل بنكي',
            Icons.account_balance,
            'ادفع عبر التطبيق',
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          onTap: _confirmRide,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              
                color: const Color(0xFF1E3A8A),
                
              
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Icon(Icons.directions_car, color: Colors.white),
                 SizedBox(width: 8),
                Text(
                  'احجز الآن',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
                style:const TextStyle(
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

  Widget _buildModernPaymentOption(
    String value,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? kPrimaryColor : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : kTextColor,
                size: 24,
              ),
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
                      color: isSelected ? kPrimaryColor : kTextColor,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? kPrimaryColor : kSecondaryColor,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration:const BoxDecoration(
                  color: kPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
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
            style:const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kTextColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style:const TextStyle(
              fontSize: 12,
              color: kSecondaryColor,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRide() async {
    try {
      // تحويل السعر إلى عدد صحيح
      final int totalPriceInt = _calculatedFare.round();

      // تحديث بيانات الطلب في Firestore
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'paymentMethod': _selectedPaymentMethod,  // تحديث طريقة الدفع
        'driverId': widget.driverId,             // تحديث معرف السائق
        'totalPrice': totalPriceInt,             // تحديث السعر الإجمالي كعدد صحيح
        'status': 'قيد الانتظار',                // تحديث حالة الطلب
        'updatedAt': FieldValue.serverTimestamp(), // تحديث وقت التعديل
      });

      print('Order updated successfully with totalPrice: $totalPriceInt');

      // التحقق من طريقة الدفع وتوجيه المستخدم
      if (_selectedPaymentMethod == 'bank') {
        // إذا كان الدفع بنكي، انتقل إلى صفحة الدفع
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => PayScreen(
              riderId: widget.driverName!,
              driverId: widget.driverId,
              isBankPayment: true,
              distance: widget.distance,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutQuart;
              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          ),
        );
      } else {
        // إذا كان الدفع نقداً، اعرض رسالة تأكيد أولاً
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'تأكيد الحجز',
                textAlign: TextAlign.right,
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'سيتم الدفع نقداً عند وصول السائق. هل تريد المتابعة؟',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'السعر الإجمالي:',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$totalPriceInt ريال',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w700,
                            color: kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(
                      color: kSecondaryColor,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // إغلاق مربع الحوار
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => RateDriverScreen(
                          driverId: widget.driverId,
                          driverName: widget.driverName!,
                          driverImage: userData?['profileImage'] ?? '',
                          distance: widget.distance,
                        ),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOutQuart;
                          var tween = Tween(begin: begin, end: end).chain(
                            CurveTween(curve: curve),
                          );
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: const Text(
                    'تأكيد',
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error updating order: $e');
      // إظهار رسالة خطأ في حالة فشل تحديث البيانات
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء تحديث البيانات: $e',
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildFareDetails() {
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
              Icon(Icons.map, color: kPrimaryColor, size: 24),
              SizedBox(width: 8),
              Text(
                'تفاصيل الرحلة والسعر ', // Updated title
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
          _buildFareDetailRow('المسافة المقدرة', '${widget.distance.toStringAsFixed(2)} كم', Icons.assistant_photo_outlined),
          _buildFareDetailRow('السعر المقدر', '${_calculatedFare.toStringAsFixed(2)} ريال', Icons.payments_outlined), // Added estimated price row
        ],
      ),
    );
  }

  Widget _buildFareDetailRow(String label, String value, IconData icon) {
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
                style:const TextStyle(
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
}
