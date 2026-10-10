import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:g_project/chats/chat_screen.dart';
import 'package:g_project/chats/select_user_page.dart';
import 'package:string_similarity/string_similarity.dart';
// import 'package:g_project/screens/rider_screens/chat_screen.dart';
import 'chat.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'driver_profile_screen.dart';
import 'ride_order_status_screen.dart';
import 'rate_driver_screen.dart';
import 'pay_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  final String riderId;
  final String? orderId;
  final String? driverId;
  final String? driverName;

  const HomeScreen({
    Key? key,
    required this.riderId,
    this.orderId,
    this.driverId,
    this.driverName,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // إضافة Map لتخزين الطلبات
  Map<String, dynamic> orders = {};
  int _selectedIndex = 0;
  final TextEditingController _currentLocationController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  String _selectedVehicle = 'الكل';
  bool _isRequesting = false;
  double _distanceInKm = 0.0;
  String _selectedPaymentMethod = 'cash';
  
  LatLng? _startCoordinates;
  LatLng? _endCoordinates;

  final List<String> _vehicleTypes = ['الكل', 'توك توك', 'تاكسي'];

  // Modern navy color palette matching DriverProfileScreen
  static const Color kPrimaryColor = Color(0xFF1E3A8A);    // Deep navy
  static const Color kSecondaryColor = Color(0xFF334155);  // Slate navy
  static const Color kBackgroundColor = Color(0xFFF1F5F9); // Cool gray
  
  // إضافة متغير لتخزين بيانات السائقين
  List<Map<String, dynamic>> drivers = [];
  bool isLoading = true;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    // Call the function to fetch and sort drivers by rating on initial load
    _fetchAndSortDriversByRating();
  }

  // Function to fetch and sort all drivers by rating
  Future<void> _fetchAndSortDriversByRating() async {
    setState(() {
      isLoading = true;
    });
    try {
      final QuerySnapshot driverSnapshot = await FirebaseFirestore.instance
          .collection('driverUsers')
          .where('isAvailable', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> allDrivers = [];

      for (var doc in driverSnapshot.docs) {
        final driverData = doc.data() as Map<String, dynamic>;
        final driverRating = (driverData['rating'] as num?)?.toDouble() ?? 0.0;
        allDrivers.add({
          'id': doc.id,
          'name': driverData['name'] ?? '',
          'phone': driverData['phone'] ?? '',
          'vehicleType': driverData['vehicleType'] ?? '',
          'isAvailable': driverData['isAvailable'] ?? false,
          'rating': driverRating,
          'totalRatings': driverData['totalRatings'] ?? 0,
          'profileImage': driverData['profileImage'],
        });
      }

      // Sort all drivers by rating (descending)
      allDrivers.sort((a, b) =>
          (b['rating'] as double).compareTo(a['rating'] as double));

      setState(() {
        drivers = allDrivers;
        isLoading = false;
      });
      
      if (allDrivers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('لا يوجد أي سائقين متاحين.')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('حدث خطأ أثناء جلب جميع السائقين: $e')),
      );
    }
  }

  // Rename the previous fetchDrivers to _fetchAndShuffleDrivers
  Future<void> _fetchAndShuffleDrivers() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch all documents from the 'driverUsers' collection in Firestore where isAvailable is true.
      final QuerySnapshot driverSnapshot = await FirebaseFirestore.instance
          .collection('driverUsers')
          .where('isAvailable', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> availableDrivers = [];
      
      for (var doc in driverSnapshot.docs) {
        final driverData = doc.data() as Map<String, dynamic>;

        availableDrivers.add({
          'id': doc.id,
          'name': driverData['name'] ?? '',
          'phone': driverData['phone'] ?? '',
          'vehicleType': driverData['vehicleType'] ?? '',
          'isAvailable': driverData['isAvailable'] ?? false,
          'rating': (driverData['rating'] as num?)?.toDouble() ?? 0.0,
          'totalRatings': driverData['totalRatings'] ?? 0,
          'profileImage': driverData['profileImage'],
        });
      }

      // Shuffle the list of available drivers randomly
      availableDrivers.shuffle();

      setState(() {
        drivers = availableDrivers;
        isLoading = false;
      });

      if (availableDrivers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد سائقين متاحين حالياً')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحميل السائقين: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: const Text("الصفحة الرئيسية", style: TextStyle(color: kBackgroundColor)),
              backgroundColor: kPrimaryColor,
              automaticallyImplyLeading: false,
            ),
            backgroundColor: kBackgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildSearchSection(),
                          _buildVehicleFilter(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: _buildVehicleList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomNavigationBar(),
          ),
          if (_isRequesting)
            Container(
              color: Colors.red.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'جاري معالجة طلبك...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
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

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 60),
          IconButton(
            icon: const Icon(Icons.map_outlined, color: kPrimaryColor),
            onPressed: () => _showMapSelectionDialog(),
          ),
          const Expanded(
            child: Text(
              'استخدم الخريطة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAppBar(),
          TextField(
            controller: _currentLocationController,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'المكان الحالي',
              hintStyle: const TextStyle(fontFamily: 'Tajawal'),
              filled: true,
              fillColor: kBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: const Icon(Icons.my_location, color: kPrimaryColor),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _destinationController,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: 'الوجهة',
              hintStyle: const TextStyle(fontFamily: 'Tajawal'),
              filled: true,
              fillColor: kBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: const Icon(Icons.location_on, color: kPrimaryColor),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _fetchAndShuffleDrivers();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'ابحث الآن',
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
    );
  }

  Widget _buildVehicleFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _vehicleTypes.map((type) {
          final isSelected = type == _selectedVehicle;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: type,
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedVehicle = type);
                _fetchAndShuffleDrivers();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVehicleList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (drivers.isEmpty) {
      return const Center(
        child: Text(
          'لا يوجد سائقين متاحين حالياً',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Tajawal',
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: 80, // Add padding to account for bottom navigation bar
      ),
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        final driver = drivers[index];
        if (_selectedVehicle != 'الكل' && 
            driver['vehicleType'] != _selectedVehicle) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: kPrimaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: driver['profileImage'] != null
                    ? Image.memory(
                        base64Decode(driver['profileImage']),
                        fit: BoxFit.cover,
                        width: 60,
                        height: 60,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            size: 40,
                            color: kPrimaryColor,
                          );
                        },
                      )
                    : const Icon(
                        Icons.person,
                        size: 40,
                        color: kPrimaryColor,
                      ),
              ),
            ),
            title: Text(
              driver['name'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(Icons.star, color: kPrimaryColor, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${driver['rating'].toString()} (${driver['totalRatings'].toString()} تقييم)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: kSecondaryColor,
                      fontFamily: 'Tajawal',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: kPrimaryColor),
                  onPressed: () async{
                     final currentUserId = FirebaseAuth.instance.currentUser!.uid;
                    final driverId = driver['id'];
                    final driverName = driver['name'];

                    final chatId = await getOrCreateChatId(currentUserId, driverId);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          chatId: chatId,
                          otherUserId: driverId,
                          otherUserName: driverName,
                        ),
                      ),
                    );
                 
                  },
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: () async {
                    if (_currentLocationController.text.trim().isEmpty || 
                        _destinationController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('يرجى تحديد الموقع والوجهة'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    // Ensure riderId is not null
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                    if (currentUserId == null) {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('خطأ في تحديد المستخدم. يرجى تسجيل الخروج وإعادة الدخول.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      return; // Stop if user ID is null
                    }

                    // Ensure driver data is valid before proceeding
                    final driverId = driver['id'] as String?;
                    final driverName = driver['name'] as String?;

                    if (driverId == null || driverName == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('خطأ في بيانات السائق. يرجى المحاولة مع سائق آخر.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      return; // Stop if driver data is incomplete
                    }

                    try {
                      final ordersCollection = FirebaseFirestore.instance.collection('orders');

                      // Prepare coordinates for Firestore (only if input looks like coordinates)
                      String? startCoordsFirestore;
                      String? endCoordsFirestore;

                      final startParts = _currentLocationController.text.trim().split(',');
                      if (startParts.length == 2) {
                        try {
                          // Attempt to parse as double to confirm it's coordinates
                          double.parse(startParts[0].trim());
                          double.parse(startParts[1].trim());
                          startCoordsFirestore = _currentLocationController.text.trim();
                        } catch (e) {
                          // Not valid coordinates, leave as null
                           print('Failed to parse start coordinates from text: $e');
                        }
                      }

                      final endParts = _destinationController.text.trim().split(',');
                      if (endParts.length == 2) {
                         try {
                          // Attempt to parse as double to confirm it's coordinates
                          double.parse(endParts[0].trim());
                          double.parse(endParts[1].trim());
                           endCoordsFirestore = _destinationController.text.trim();
                        } catch (e) {
                          // Not valid coordinates, leave as null
                           print('Failed to parse end coordinates from text: $e');
                        }
                      }

                      final orderRef = await ordersCollection.add({
                        'riderId': currentUserId, // Use the checked user ID
                        'driverId': null, // Initial state is null, assigned when driver accepts
                        'currentLocation': _currentLocationController.text.trim(), // Store the address text
                        'destination': _destinationController.text.trim(), // Store the address text
                        'currentLocationCoordinates': startCoordsFirestore, // Store coordinates if available
                        'destinationCoordinates': endCoordsFirestore, // Store coordinates if available
                        'orderTime': FieldValue.serverTimestamp(),
                        'status': 'قيد الانتظار', // String
                        'paymentMethod': null, // Initial state is null, set later
                        'distance': _distanceInKm, // double
                        'totalPrice': 0.0, // Initial price, will be updated later
                      });

                      setState(() {
                        _isRequesting = true;
                      });

                      // Navigate to DriverProfileScreen, passing valid driver info and order ID
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DriverProfileScreen(
                            driverId: driverId, 
                            driverName: driverName, 
                            orderId: orderRef.id,
                            distance: _distanceInKm,  
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('حدث خطأ أثناء إرسال الطلب: ${e.toString()}'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } finally {
                      setState(() {
                        _isRequesting = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'طلب',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
 Future<String> getOrCreateChatId(String currentUserId, String otherUserId) async {
    // الطريقة الأولى: استخدام min و max بعد استيراد dart:math
    final chatId = '${min(currentUserId.hashCode, otherUserId.hashCode)}_${max(currentUserId.hashCode, otherUserId.hashCode)}';

    // الطريقة البديلة: ترتيب المعرفات أبجدياً
    // final participants = [currentUserId, otherUserId]..sort();
    // final chatId = '${participants[0]}_${participants[1]}';

    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .get();

    if (!chatDoc.exists) {
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participants': [currentUserId, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
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
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            
            if (index == 0) {
             final currentUser = FirebaseAuth.instance.currentUser;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SelectUserPage(currentUserId: currentUser!.uid),
                ),
              ).then((_) => setState(() => _selectedIndex = 0));
            } else if (index == 1) {
                           Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RiderOrderScreen(
                    driverId: widget.driverId ?? '',
                    riderId: widget.riderId,
                    isBankPayment: true,
                    distance: _distanceInKm,
                  ),
                ),
              ).then((_) => setState(() => _selectedIndex = 0));
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ).then((_) => setState(() => _selectedIndex = 0));
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
              icon: Icon(Icons.directions_car),
              label: 'الطلبات',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'حسابي',
            ),
          ],
        ),
      ),
    );
  }

  void _showMapSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'اختر الموقع',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              trailing: const Icon(Icons.location_on, color: kPrimaryColor),
              title: const Text(
                'موقع البداية',
                textAlign: TextAlign.right,
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              onTap: () {
                Navigator.pop(context);
                _selectLocation(true);
              },
            ),
            ListTile(
              trailing: const Icon(Icons.flag, color: kPrimaryColor),
              title: const Text(
                'موقع الوصول',
                textAlign: TextAlign.right,
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              onTap: () {
                Navigator.pop(context);
                _selectLocation(false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectLocation(bool isStartLocation) async {
    LatLng? startCoords;
    LatLng? endCoords;

    // Parse start coordinates if available
    if (_currentLocationController.text.isNotEmpty) {
      try {
        final parts = _currentLocationController.text.split(',');
        print('Start location parts: $parts'); // Debug print
        if (parts.length == 2) {
          startCoords = LatLng(
            double.parse(parts[0].trim()),
            double.parse(parts[1].trim()),
          );
          print('Parsed start coordinates: ${startCoords.latitude}, ${startCoords.longitude}'); // Debug print
        }
      } catch (e) {
        print('Error parsing start coordinates: $e');
      }
    }

    // Parse end coordinates if available
    if (_destinationController.text.isNotEmpty) {
      try {
        final parts = _destinationController.text.split(',');
        print('End location parts: $parts'); // Debug print
        if (parts.length == 2) {
          endCoords = LatLng(
            double.parse(parts[0].trim()),
            double.parse(parts[1].trim()),
          );
          print('Parsed end coordinates: ${endCoords.latitude}, ${endCoords.longitude}'); // Debug print
        }
      } catch (e) {
        print('Error parsing end coordinates: $e');
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapScreen(
          isSelectingStart: isStartLocation,
          startCoordinates: startCoords,
          endCoordinates: endCoords,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      print('Received result from map: $result'); // Debug print
      setState(() {
        if (isStartLocation) {
          _currentLocationController.text = result['location'];
          // Store start coordinates
          if (result['coordinates'] != null) {
            try {
              final parts = result['coordinates'].split(',');
              if (parts.length == 2) {
                _startCoordinates = LatLng(
                  double.parse(parts[0].trim()),
                  double.parse(parts[1].trim()),
                );
                 print('Stored start coordinates: ${_startCoordinates?.latitude}, ${_startCoordinates?.longitude}'); // Debug print
              }
            } catch (e) {
              print('Error parsing start coordinates from result: $e');
            }
          }
          print('Updated start location: ${_currentLocationController.text}'); // Debug print
        } else {
          _destinationController.text = result['location'];
          // Store end coordinates
           if (result['coordinates'] != null) {
            try {
              final parts = result['coordinates'].split(',');
              if (parts.length == 2) {
                _endCoordinates = LatLng(
                  double.parse(parts[0].trim()),
                  double.parse(parts[1].trim()),
                );
                 print('Stored end coordinates: ${_endCoordinates?.latitude}, ${_endCoordinates?.longitude}'); // Debug print
              }
            } catch (e) {
              print('Error parsing end coordinates from result: $e');
            }
          }
          print('Updated end location: ${_destinationController.text}'); // Debug print
        }

        // Calculate distance if both coordinates are set
        if (_startCoordinates != null && _endCoordinates != null) {
          try {
            _distanceInKm = _calculateDistance(
              _startCoordinates!,
              _endCoordinates!
            );

            print('المسافة بين موقع البداية وموقع الوصول: ${_distanceInKm.toStringAsFixed(2)} كم');
          } catch (e) {
            print('Error calculating distance: $e');
          }
        } else {
          print('One or both coordinates are not set for distance calculation'); // Debug print
        }
      });
    }
  }

  // Add method to calculate distance between two points
  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // in kilometers
    double dLat = _degreesToRadians(end.latitude - start.latitude);
    double dLng = _degreesToRadians(end.longitude - start.longitude);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(start.latitude)) * math.cos(_degreesToRadians(end.latitude)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  void _confirmRide() async {
    try {
      print('المسافة النهائية للرحلة: ${_distanceInKm.toStringAsFixed(2)} كم');
      
      // تحديث بيانات الطلب في Firestore
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'paymentMethod': _selectedPaymentMethod,  // تحديث طريقة الدفع
        'driverId': widget.driverId,             // تحديث معرف السائق
        'distance': _distanceInKm,               // تحديث المسافة
      });

      // التحقق من طريقة الدفع وتوجيه المستخدم
      if (_selectedPaymentMethod == 'bank') {
        // إذا كان الدفع بنكي، انتقل إلى صفحة التقييم مباشرة
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => PayScreen(
              riderId: widget.riderId,
              driverId: widget.driverId ?? '',
              isBankPayment: true,
              distance: _distanceInKm,
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
                  const SizedBox(height: 8),
                  Text(
                    'المسافة: ${_distanceInKm.toStringAsFixed(2)} كم',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
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
           
                         driverId: widget.driverId ?? '',
                          driverName: widget.driverName ?? '',
                          driverImage: userData?['profileImage'] ?? '',
                          distance: _distanceInKm,
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
      // إظهار رسالة خطأ في حالة فشل تحديث البيانات
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ أثناء تحديث البيانات. يرجى المحاولة مرة أخرى.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const ChoiceChip({
    Key? key,
    required this.label,
    required this.selected,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : _HomeScreenState.kPrimaryColor,
          fontFamily: 'Tajawal',
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: Colors.white,
      selectedColor: _HomeScreenState.kPrimaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? _HomeScreenState.kPrimaryColor 
              : _HomeScreenState.kPrimaryColor.withOpacity(0.3),
        ),
      ),
      showCheckmark: false,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}