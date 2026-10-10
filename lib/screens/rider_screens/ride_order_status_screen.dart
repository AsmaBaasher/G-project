import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:g_project/chats/select_user_page.dart';
import 'chat.dart';
import 'pay_screen.dart';
import 'profile_screen.dart';
import 'rate_driver_screen.dart';


// Modern navy color palette
const Color kPrimaryColor = Color(0xFF1E3A8A);    // Deep navy
const Color kSecondaryColor = Color(0xFF334155);  // Slate navy
const Color kBackgroundColor = Color(0xFFF1F5F9); // Cool gray
const Color kTextColor = Color(0xFF0F172A);       // Dark navy
const Color kAccentColor = Color(0xFF3B82F6);     // Bright blue

class RiderOrderScreen extends StatefulWidget {
  @override
  // ignore: override_on_non_overriding_member
  final String driverId;
  final String riderId;
  final bool isBankPayment;
  final  double distance;

  const RiderOrderScreen({
    Key? key,
    required this.driverId,
    required this.riderId,
    required this.distance,
    this.isBankPayment = false,
  }) : super(key: key);
  _RiderOrderScreenState createState() => _RiderOrderScreenState();
}

class _RiderOrderScreenState extends State<RiderOrderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0; // تغيير القيمة الافتراضية إلى 0

  // إضافة متغيرات لتخزين البيانات
  List<Map<String, dynamic>> approvedOrders = [];
  List<Map<String, dynamic>> currentOrders = [];
  List<Map<String, dynamic>> completedOrders = [];
  List<Map<String, dynamic>> cancelledOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          // لا نقوم بتحديث _selectedIndex هنا لأنه خاص بالتبويبات العلوية
        });
      }
    });
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
          .where('riderId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'معتمد')
          .get();

      // جلب الطلبات الحالية
      final currentSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('riderId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'قيد الانتظار')
          .get();

      // جلب الطلبات المكتملة
      final completedSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('riderId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'مكتمل')
          .get();

      // جلب الطلبات الملغية
      final cancelledSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('riderId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'مرفوض')
          .get();

      // تحويل الطلبات وجلب معلومات السائق لكل طلب
      approvedOrders = await Future.wait(approvedSnapshot.docs.map((doc) async {
        final data = doc.data();
        final driverId = data['driverId'] as String?;
        String driverName = 'غير معروف';
        
        if (driverId != null) {
          final driverDoc = await FirebaseFirestore.instance
              .collection('driverUsers')
              .doc(driverId)
              .get();
          if (driverDoc.exists) {
            driverName = driverDoc.data()?['name'] ?? 'غير معروف';
          }
        }
        
        return {
          ...data,
          'id': doc.id,
          'customerName': driverName,
        };
      }));

      currentOrders = await Future.wait(currentSnapshot.docs.map((doc) async {
        final data = doc.data();
        final driverId = data['driverId'] as String?;
        String driverName = 'غير معروف';
        
        if (driverId != null) {
          final driverDoc = await FirebaseFirestore.instance
              .collection('driverUsers')
              .doc(driverId)
              .get();
          if (driverDoc.exists) {
            driverName = driverDoc.data()?['name'] ?? 'غير معروف';
          }
        }
        
        return {
          ...data,
          'id': doc.id,
          'customerName': driverName,
        };
      }));

      completedOrders = await Future.wait(completedSnapshot.docs.map((doc) async {
        final data = doc.data();
        final driverId = data['driverId'] as String?;
        String driverName = 'غير معروف';
        
        if (driverId != null) {
          final driverDoc = await FirebaseFirestore.instance
              .collection('driverUsers')
              .doc(driverId)
              .get();
          if (driverDoc.exists) {
            driverName = driverDoc.data()?['name'] ?? 'غير معروف';
          }
        }
        
        return {
          ...data,
          'id': doc.id,
          'customerName': driverName,
        };
      }));

      cancelledOrders = await Future.wait(cancelledSnapshot.docs.map((doc) async {
        final data = doc.data();
        final driverId = data['driverId'] as String?;
        String driverName = 'غير معروف';
        
        if (driverId != null) {
          final driverDoc = await FirebaseFirestore.instance
              .collection('driverUsers')
              .doc(driverId)
              .get();
          if (driverDoc.exists) {
            driverName = driverDoc.data()?['name'] ?? 'غير معروف';
          }
        }
        
        return {
          ...data,
          'id': doc.id,
          'customerName': driverName,
        };
      }));

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء جلب البيانات: ${e.toString()}'),
          backgroundColor: kPrimaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        SnackBar(content: Text('تم اكتمال الطلب بنجاح',style: TextStyle(color: kBackgroundColor),),backgroundColor: kPrimaryColor,),
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
          .delete();

      // تحديث القائمة بعد تحديث حالة الطلب
      _fetchOrders();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف الطلب ',style: TextStyle(color: kBackgroundColor),),backgroundColor: kPrimaryColor,),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء حذف الطلب: ${e.toString()}',style: TextStyle(color: kBackgroundColor),),backgroundColor: kPrimaryColor,),
      );
    }
  }

  Future<void> _deleteAllOrders(String status) async {
    try {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'تأكيد الحذف',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: const Text(
              'هل أنت متأكد من حذف جميع الطلبات؟',
              style: TextStyle(
                fontFamily: 'Tajawal',
              ),
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.grey,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  setState(() => isLoading = true);
                  
                  final ordersSnapshot = await FirebaseFirestore.instance
                      .collection('orders')
                      .where('riderId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .where('status', isEqualTo: status)
                      .get();

                  final batch = FirebaseFirestore.instance.batch();
                  for (var doc in ordersSnapshot.docs) {
                    batch.delete(doc.reference);
                  }
                  await batch.commit();

                  await _fetchOrders();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'تم حذف جميع الطلبات بنجاح',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: kPrimaryColor,
                      ),
                    );
                  }
                },
                child: const Text(
                  'حذف',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء حذف الطلبات: ${e.toString()}',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.white,
              ),
            ),
            backgroundColor: kPrimaryColor,
          ),
        );
      }
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final String isApproved = order['status'];
    // final bool isCompleted = order['completed'] ?? false;
    
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
                       order['destination'],
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
                          'المجموع: ${order['totalPrice']}  ريال ',
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
                  if (isApproved=="مكتمل")
                    ElevatedButton.icon(
                      onPressed: () {
                        if (order['paymentMethod'] == 'bank') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PayScreen(
                              riderId: order['id'],
                              driverId: widget.driverId,
                              isBankPayment: true,
                              distance: widget.distance,
                            )),
                          );
                        } else if (order['paymentMethod'] == 'cash') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RateDriverScreen(
                              driverName: order['customerName'] ?? 'سائق',
                              driverImage: '',
                              distance: widget.distance,
                              driverId: widget.driverId,
                            )),
                          );
                        }
                      },
                      label: Text(order['paymentMethod'] == 'bank' ? 'تسديد' : 'تقييم'),
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
                  else if (isApproved== "قيد الانتظار")
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: ()=>_cancelOrder(order['id']),
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

                   if (isApproved== "مرفوض")
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: ()=>_cancelOrder(order['id']),
                          label: const Text('حذف'),
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
   
               
                if (isApproved == "معتمد")
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: ()=>_cancelOrder(order['id']),
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
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: () {
                String status = 'قيد الانتظار';
                switch (_tabController.index) {
                  case 0:
                    status = 'معتمد';
                    break;
                  case 1:
                    status = 'قيد الانتظار';
                    break;
                  case 2:
                    status = 'مكتمل';
                    break;
                  case 3:
                    status = 'ملغي';
                    break;
                }
                _deleteAllOrders(status);
              },
              tooltip: 'حذف جميع الطلبات',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
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
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Tajawal',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  fontFamily: 'Tajawal',
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: const [
                  Tab(text: 'المعتمدة'),
                  Tab(text: 'الحالية'),
                  Tab(text: 'المكتملة'),
                  Tab(text: 'الملغية'),
                ],
              ),
            ),
          ),
        ),
       
       
        body: isLoading 
          ? const Center(
              child: CircularProgressIndicator(
                color: kPrimaryColor,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(approvedOrders),
                _buildOrdersList(currentOrders),
                _buildOrdersList(completedOrders),
                _buildOrdersList(cancelledOrders),
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
          child: _buildBottomNavigationBar(),     
     
        ),
      ),
      
    );
  }
    Widget _buildBottomNavigationBar() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex.clamp(0, 2), // ضمان أن القيمة ضمن النطاق الصحيح
          onTap: (index) {
            if (index >= 0 && index < 3) { // التحقق من صحة المؤشر
              setState(() {
                _selectedIndex = index;
              });
              switch (index) {
                case 0:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SelectUserPage(currentUserId: widget.riderId)),
                  );
                  break;
                case 1:
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                  break;
                case 2:
                  Navigator.pop(context); // العودة إلى الشاشة الرئيسية
                  break;
              }
            }
          },
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: kSecondaryColor.withOpacity(0.5),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontFamily: 'Tajawal'),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Tajawal'),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'محادثة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'حسابي',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'الرئيسية',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16),
      itemCount: orders.length,
      itemBuilder: (context, index) => _buildOrderCard(orders[index]),
    );
  }
}