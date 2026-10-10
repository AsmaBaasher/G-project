import 'package:flutter/material.dart';
import 'package:g_project/chats/select_user_page.dart';
import 'package:g_project/screens/driver_screens/personal_info_screen.dart';

import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'payment_pdf.dart';


// Modern navy color palette
const Color kPrimaryColor = Color(0xFF1E3A8A);    // Deep navy
const Color kSecondaryColor = Color(0xFF334155);  // Slate navy
const Color kBackgroundColor = Color(0xFFF1F5F9); // Cool gray
const Color kTextColor = Color(0xFF0F172A);       // Dark navy
const Color kAccentColor = Color(0xFF3B82F6);     // Bright blue

class DriverScreen extends StatefulWidget {
  @override
  _DriverScreenState createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 1; // Start with home selected

  // إضافة متغيرات لتخزين البيانات
  List<Map<String, dynamic>> approvedOrders = [];
  List<Map<String, dynamic>> currentOrders = [];
  List<Map<String, dynamic>> completedOrders = [];
  bool isLoading = true;

  // دالة مساعدة لتنسيق السعر
  String _formatPrice(dynamic price) {
    if (price == null) {
      return '0 ريال';
    }
    
    // تحويل السعر إلى رقم صحيح
    int? numericPrice;
    if (price is num) {
      numericPrice = price.round();
    } else if (price is String) {
      numericPrice = double.tryParse(price)?.round();
    }
    
    // إذا كان السعر غير صالح، نرجع القيمة الافتراضية
    if (numericPrice == null) {
      return '0 ريال';
    }
    
    // تنسيق السعر مع إضافة "ريال"
    return '$numericPrice ريال';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // استدعاء دالة جلب البيانات
    _fetchOrders();
  }

  // دالة لجلب البيانات من Firebase
  Future<void> _fetchOrders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      setState(() => isLoading = true);

      // جلب الطلبات المعتمدة
      final approvedSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('driverId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'معتمد')
          .get();

      // جلب الطلبات الحالية
      final currentSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('driverId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'قيد الانتظار')
          .get();

      // جلب الطلبات المكتملة
      final completedSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('driverId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'مكتمل')
          .get();

      // تحويل الطلبات وجلب معلومات الراكب لكل طلب
      approvedOrders = await Future.wait(approvedSnapshot.docs.map((doc) async {
        final data = doc.data();
        final riderId = data['riderId'] as String?;
        String riderName = 'غير معروف';
        
        if (riderId != null) {
          final riderDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(riderId)
              .get();
          if (riderDoc.exists) {
            riderName = riderDoc.data()?['name'] ?? 'غير معروف';
            print(riderName);
          }
        }
        
        return {
          ...data,
          'id': doc.id,
          'name': riderName,
        };
      }));

      currentOrders = await Future.wait(currentSnapshot.docs.map((doc) async {
        final data = doc.data();
        final riderId = data['riderId'] as String?;
        String riderName = 'غير معروف';
        
        if (riderId != null) {
          final riderDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(riderId)
              .get();
          if (riderDoc.exists) {
            riderName = riderDoc.data()?['name'] ?? 'غير معروف';
          }
        }
        
        return {
          ...data,
          'id': doc.id,
          'name': riderName,
        };
      }));

      completedOrders = await Future.wait(completedSnapshot.docs.map((doc) async {
        final data = doc.data();
        final riderId = data['riderId'] as String?;
        String riderName = 'غير معروف';
        
        if (riderId != null) {
          final riderDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(riderId)
              .get();
          if (riderDoc.exists) {
            riderName = riderDoc.data()?['name'] ?? 'غير معروف';
          }
        }
        
        return {
          ...data,
          'id': doc.id,
          'name': riderName,
        };
      }));

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // Navigate to settings
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PersonalInfoScreen()),
      ).then((_) => setState(() => _selectedIndex = 1));
    } else if (index == 2) {
      // Navigate to chat
      final currentUser = FirebaseAuth.instance.currentUser;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SelectUserPage(currentUserId: currentUser!.uid),),
            );
    }
  }

  Future<void> _approveOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'مكتمل',
      });

      // تحديث القائمة بعد تحديث حالة الطلب
      _fetchOrders();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم قبول الطلب بنجاح',style: TextStyle(color: kBackgroundColor),),backgroundColor: kPrimaryColor,),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء قبول الطلب: ${e.toString()}',style: TextStyle(color: kBackgroundColor),),backgroundColor: kPrimaryColor,),
      );
    }
  }

  Future<void> _confirmeOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'معتمد',
      });

      // تحديث القائمة بعد تحديث حالة الطلب
      _fetchOrders();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم اعتماد الطلب بنجاح',style: TextStyle(color: kBackgroundColor),),backgroundColor: kPrimaryColor,),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء اكمال الطلب: ${e.toString()}',style: TextStyle(color: kBackgroundColor),),backgroundColor: kPrimaryColor,),
      );
    }
  }

  Future<void> _cancelOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': 'مرفوض',
      });

      // تحديث القائمة بعد تحديث حالة الطلب
      _fetchOrders();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم رفض الطلب ',style: TextStyle(color: kBackgroundColor),),backgroundColor: kPrimaryColor,),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء رفض الطلب: ${e.toString()}',style: TextStyle(color: kBackgroundColor),),backgroundColor: kPrimaryColor,),
      );
    }
  }

  // إضافة دالة جديدة لتحديث حالة الطلب إلى مكتمل
  Future<void> _completeOrder(String orderId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Create a batch write to update both documents atomically
      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      // Update order status
      DocumentReference orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
      batch.update(orderRef, {'status': 'مكتمل'});
      
      // Get and update driver's tripCount
      DocumentReference driverRef = FirebaseFirestore.instance.collection('driverUsers').doc(user.uid);
      DocumentSnapshot driverDoc = await driverRef.get();
      
      if (!driverDoc.exists) {
        throw Exception('Driver document not found');
      }
      
      int currentTripCount = (driverDoc.data() as Map<String, dynamic>)['tripCount'] ?? 0;
      batch.update(driverRef, {'tripCount': currentTripCount + 1});
      
      // Commit the batch
      await batch.commit();
  
      // تحديث القائمة بعد تحديث حالة الطلب
      _fetchOrders();
  
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث حالة الطلب إلى مكتمل', style: TextStyle(color: kBackgroundColor)),
          backgroundColor: kPrimaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تحديث حالة الطلب: ${e.toString()}', style: TextStyle(color: kBackgroundColor)),
          backgroundColor: kPrimaryColor,
        ),
      );
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    // تحويل حالة الطلب إلى نص بشكل آمن
    final String orderStatus = (order['status'] as String?) ?? 'غير معروف';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shadowColor: kPrimaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              kBackgroundColor.withOpacity(0.3),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: kPrimaryColor.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.person, color: kPrimaryColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['name'] ?? 'غير معروف',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kTextColor,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // 'رقم الطلب: #${order['id']}'
                        ''
                        ,
                        style: TextStyle(
                          fontSize: 12,
                          color: kSecondaryColor.withOpacity(0.8),
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kBackgroundColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: kPrimaryColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: kPrimaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "من "+(order['currentLocation']?? 'غير معروف' )+ " إلى "+
                        order['destination'] ?? 'غير معروف',
                        style: TextStyle(
                          fontSize: 14,
                          color: kSecondaryColor,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        Text(
                          'المجموع: ${_formatPrice(order['totalPrice'])} ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (orderStatus == 'مكتمل')
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => PaymentPDFScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('معاينة السند'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else if (orderStatus == 'قيد الانتظار')
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _cancelOrder(order['id']),
                          label: const Text('رفض'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.red, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _confirmeOrder(order['id']),
                          label: const Text('قبول'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (orderStatus == 'معتمد')
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _completeOrder(order['id']),
                          label: const Text('تم التوصيل'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _cancelOrder(order['id']),
                          label: const Text('إلغاء'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.red, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                ],
              ),
              
            ],
          ),
        ),
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
          elevation: 0,
          backgroundColor: kPrimaryColor,
          automaticallyImplyLeading: false,
          title: const Text(
            'الطلبات',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kBackgroundColor,
              fontFamily: 'Tajawal',
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(60),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: kPrimaryColor,
                unselectedLabelColor: kSecondaryColor.withOpacity(0.7),
                indicatorColor: kPrimaryColor,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Tajawal',
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  fontFamily: 'Tajawal',
                ),
                padding: EdgeInsets.symmetric(horizontal: 8),
                tabs: [
                  Tab(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(' المعتمدة'),
                    ),
                  ),
                  Tab(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(' الحالية'),
                    ),
                  ),
                  Tab(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(' المكتملة'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: isLoading 
          ? Center(
              child: CircularProgressIndicator(
                color: kPrimaryColor,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // الطلبات المعتمدة
                approvedOrders.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد طلبات معتمدة',
                          style: TextStyle(
                            fontSize: 16,
                            color: kSecondaryColor,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(top: 16),
                        itemCount: approvedOrders.length,
                        itemBuilder: (context, index) =>
                            _buildOrderCard(approvedOrders[index]),
                      ),
                // الطلبات الحالية
                currentOrders.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد طلبات حالية',
                          style: TextStyle(
                            fontSize: 16,
                            color: kSecondaryColor,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(top: 16),
                        itemCount: currentOrders.length,
                        itemBuilder: (context, index) =>
                            _buildOrderCard(currentOrders[index]),
                      ),
                // الطلبات المكتملة
                completedOrders.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد طلبات مكتملة',
                          style: TextStyle(
                            fontSize: 16,
                            color: kSecondaryColor,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(top: 16),
                        itemCount: completedOrders.length,
                        itemBuilder: (context, index) =>
                            _buildOrderCard(completedOrders[index]),
                      ),
              ],
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
}